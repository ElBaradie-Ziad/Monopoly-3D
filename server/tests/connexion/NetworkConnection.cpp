#include <UnitTest++/UnitTest++.h>
#include "ConnexionPlayer1Test.hpp"
#include "ConnexionPlayer2Test.hpp"
#include <thread>
#include <chrono>

SUITE(MonopolyServerTests) {

    // ==========================================
    // NOUVEAU SYSTÈME DE TESTS THREADÉS ET ISOLÉS
    // ==========================================
    TEST(Test_00_Threaded_Connexion) {
        printf("\n--- DÉBUT DU TEST CONNEXION THREADÉ ---\n");

        // Lancement des deux clients de manière 100% isolée via threads
        std::thread t1(runPlayer1ConnexionSequence);
        std::thread t2(runPlayer2ConnexionSequence);

        t1.join();
        t2.join();

        printf("--- FIN DU TEST CONNEXION THREADÉ ---\n");
    }
}