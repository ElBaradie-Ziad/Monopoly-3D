#include <UnitTest++/UnitTest++.h>
#include "LobbyPlayer1Test.hpp"
#include "LobbyPlayer2Test.hpp"
#include "MatchManager.hpp"
#include "Match.hpp"
#include "Player.hpp"
#include <thread>
#include <chrono>
#include <atomic>

SUITE(ThreadedLobbySuite) {

    TEST(Test_Threaded_Lobby_Creation_And_Start) {
        printf("\n--- DÉBUT DU TEST LOBBY THREADÉ ---\n");

        std::atomic<int> sharedMatchID(-1);

        // On passe le MatchManager en paramètre pour que chaque joueur
        // puisse inspecter les classes Match / GameState / Player directement.
        MatchManager* mm = MatchManager::getInstance();

        std::thread t1(runPlayer1LobbySequence, std::ref(sharedMatchID), mm);
        std::thread t2(runPlayer2LobbySequence, std::ref(sharedMatchID), mm);

        t1.join();
        t2.join();

        // ─── Vérification finale dans l'orchestrateur ──────────────────────
        printf("\n--- VÉRIFICATION FINALE (orchestrateur) ---\n");
        int finalMatchID = sharedMatchID.load();
        CHECK(finalMatchID != -1);

        if (finalMatchID != -1) {
            Match* match = mm->getMatchByMatchID(finalMatchID);
            CHECK(match != nullptr);

            if (match) {
                CHECK_EQUAL(2, (int)match->getAllClientID().size());
                CHECK(match->isPlaying());
                printf("  [FINAL] matchID=%d | joueurs=%zu | isPlaying=%d | currentPlayerID=%d\n",
                    finalMatchID,
                    match->getAllClientID().size(),
                    (int)match->isPlaying(),
                    match->getCurrentPlayerID());
            }
        }

        printf("--- FIN DU TEST LOBBY ---\n");
    }
}
