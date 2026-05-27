#include <UnitTest++/UnitTest++.h>
#include <TestReporterStdout.h>
#include <thread>
#include <chrono>
#include <unistd.h>

#include "DatabaseManager.hpp"
#include "ThreadSafeQueue.hpp"
#include "NetworkServer.hpp"
#include "LogicDispatcher.hpp"

extern "C" const char* __lsan_default_options() {
    return "detect_leaks=0";
}

// Custom reporter to stop on FIRST failure
class FailFastReporter : public UnitTest::TestReporterStdout {
public:
    virtual void ReportFailure(UnitTest::TestDetails const& details, char const* failure) override {
        printf("%s:%d: error: Failure in %s: %s\n", details.filename, details.lineNumber, details.testName, failure);
        printf("\n[FAIL-FAST] Arret immediat des tests.\n\n");
        std::_Exit(1);
    }
};

int main() {
    // 1. Database Check
    try {
        pqxx::connection& conn = DatabaseManager::getConnection();
        if(!conn.is_open()) {
            std::cerr << "Database not open\n";
            std::abort();
        }
    } catch (const std::exception& e) {
        std::cerr << "\n[ERREUR CRITIQUE] Impossible de joindre PostgreSQL:\n" << e.what() << "\n=> ALLUMEZ VOTRE BASE DE DONNÉES <= \n\n";
        std::abort();
    } catch (...) { 
        std::cerr << "Unknown exception connecting to DB\n";
        std::abort(); 
    }

    // 2. Start server components in threads
    ThreadSafeQueue* messageQueue = new ThreadSafeQueue();
    NetworkServer* networkServer = new NetworkServer(*messageQueue, 10000);
    std::vector<IObserver*> obs = {networkServer};
    LogicDispatcher* logicDispatcher = new LogicDispatcher(*messageQueue, obs);

    std::thread networkThread([networkServer]() { networkServer->run(); });
    std::thread logicThread([logicDispatcher]() { logicDispatcher->run(); });

    std::this_thread::sleep_for(std::chrono::milliseconds(500)); // wait for start

    FailFastReporter reporter;
    UnitTest::TestRunner runner(reporter);
    int res = 0;
    
    printf("\n>>> Execution de MonopolyServerTests <<<\n");
    res = runner.RunTestsIf(UnitTest::Test::GetTestList(), "MonopolyServerTests", UnitTest::True(), 0);
    if (res > 0) {
        printf("\n[FAIL] MonopolyServerTests a echoue avec %d erreurs. Arret.\n", res);
        std::_Exit(res);
    }

    printf("\n>>> Execution de ThreadedLobbySuite <<<\n");
    res = runner.RunTestsIf(UnitTest::Test::GetTestList(), "ThreadedLobbySuite", UnitTest::True(), 0);
    if (res > 0) {
        printf("\n[FAIL] ThreadedLobbySuite a echoue avec %d erreurs. Arret.\n", res);
        std::_Exit(res);
    }

    printf("\n>>> Execution de ThreadedGameSuite <<<\n");
    res = runner.RunTestsIf(UnitTest::Test::GetTestList(), "ThreadedGameSuite", UnitTest::True(), 0);
    if (res > 0) {
        printf("\n[FAIL] ThreadedGameSuite a echoue avec %d erreurs. Arret.\n", res);
        std::_Exit(res);
    }
    
    // We don't join threads so process can exit cleanly
    networkThread.detach();
    logicThread.detach();

    std::_Exit(res);
}
