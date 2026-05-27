#include <iostream>
#include <thread>
#include <exception>

#include "DatabaseManager.hpp"
#include "ThreadSafeQueue.hpp"
#include "NetworkServer.hpp"
#include "LogicDispatcher.hpp"

#define PORT 10000

int main() {
    // 1. Database Connection Check
    try {
        pqxx::connection& conn = DatabaseManager::getConnection();
        if (conn.is_open()) {
            std::cout << "[DB] Successfully connected to database: " << conn.dbname() << std::endl;
        }
    } catch (const std::exception& e) {
        std::cerr << "[DB] Critical error: " << e.what() << std::endl;
        return 1;
    }

    // 2. Create the shared thread-safe queue
    ThreadSafeQueue messageQueue;

    // 3. Create the Network Server
    NetworkServer networkServer(messageQueue, PORT);

    // 4. Create the Logic Dispatcher
    std::vector<IObserver*> obs = {&networkServer};
    LogicDispatcher logicDispatcher(messageQueue, obs);

    // 5. Launch the Threads
    std::cout << "[SYSTEM] Launching asynchronous processes..." << std::endl;

    // Thread 1: Network server listening for WebSocket connections
    std::thread networkThread([&networkServer]() {
        networkServer.run();
    });

    // Thread 2: Logic dispatcher processing messages from the queue
    std::thread logicThread([&logicDispatcher]() {
        logicDispatcher.run();
    });

    // 6. Wait for threads to finish 
    networkThread.join();
    logicThread.join();

    return 0;
}
