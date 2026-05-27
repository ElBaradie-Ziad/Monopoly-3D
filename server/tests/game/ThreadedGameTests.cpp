#include <UnitTest++/UnitTest++.h>
#include "GamePlayer1Test.hpp"
#include "GamePlayer2Test.hpp"
#include "Player1Context.hpp"
#include "Player2Context.hpp"
#include "MatchManager.hpp"
#include "Match.hpp"
#include "GameState.hpp"
#include "Player.hpp"
#include "CmdRollDice.hpp"
#include "StatePlaying.hpp"
#include "Code.hpp"
#include <thread>
#include <chrono>
#include <atomic>

// ─────────────────────────────────────────────────────────────────────────────
// SUITE GameTests
// Exige que ThreadedLobbySuite ait réussi AVANT (le match est déjà créé 
// et la partie est en cours).
//
// Organisation :
//   - Les deux joueurs jouent dans des threads séparés
//   - Chaque joueur attend son tour via polling MatchManager
//   - Les dés sont truqués via CmdRollDice::setForcedDice avant chaque envoi
//   - Les vérifications serveur se font directement sur Match/GameState/Player
//
// Tests couverts :
//   1. Lancer normal (non-double) + position correcte
//   2. Achat de propriété + argent déduit + propriétaire assigné
//   3. Lancer double → relance autorisée
//   4. 3 doubles consécutifs → prison
//   5. En prison non-double → reste en prison
//   6. En prison double → sort de prison + déplacement
//   7. Passage par case Départ → +200€
//   8. Atterrir sur "Aller en prison" (case 30) → prison
//   9. Payer 50€ pour sortir de prison
//  10. Loyer rue (propriété de l'autre joueur)
//  11. Loyer avec achat Gare (1 station = 25€, 2 = 50€, 3 = 100€)
//  12. Achat Compagnie Électricité (Utility)
//  13. END_TURN + READY_NEXT_TURN → changement de tour
//  14. Achat de maison (avec monopole couleur)
// ─────────────────────────────────────────────────────────────────────────────

SUITE(ThreadedGameSuite) {

    TEST(Test_Complete_Game_Simulation) {
        printf("\n\n════════════════════════════════════════════════════════════\n");
        printf("     DÉBUT DU TEST DE SIMULATION DE PARTIE\n");
        printf("════════════════════════════════════════════════════════════\n\n");

        MatchManager* mm = MatchManager::getInstance();

        // Le matchID doit exister (créé par les tests lobby précédents)
        // On le récupère du MatchManager directement
        Match* match = mm->getMatchByClientID(Player1Context::id);
        CHECK(match != nullptr);
        if (!match) {
            printf("[GAME] ERREUR FATALE: Aucun match trouvé pour P1!\n");
            return;
        }

        CHECK(match->isPlaying());

        // Vérifier que le state du match est bien StatePlaying
        bool isStatePlaying = (dynamic_cast<StatePlaying*>(&match->getState()) != nullptr);
        CHECK(isStatePlaying);
        printf("[GAME] Match state = %s\n", isStatePlaying ? "StatePlaying ✓" : "ERREUR: pas StatePlaying ✗");
        int mID = -1;
        // Trouver le matchID
        // On utilise le fait que P1 est déjà dans un match
        // On doit trouver le matchID — parcourir n'est pas simple
        // On regarde le sharedMatchID via une variable qui est encore accessible
        // Alternate: créer un atomic partagé. Plus simple: stocker dans les contextes.
        // En fait, le match est unique pour ce test, donc matchID=1 normalement.
        // Mais pour être robuste, on va le déduire.
        
        // Petit hack : on regarde quel matchID a un match jouant
        for (int id = 1; id <= 10; id++) {
            Match* m = mm->getMatchByMatchID(id);
            if (m && m->isPlaying() && m->hasPlayer(Player1Context::id)) {
                mID = id;
                break;
            }
        }
        CHECK(mID != -1);

        std::atomic<int> sharedMatchID(mID);

        printf("[GAME] Match trouvé: id=%d | isPlaying=%d | currentPlayer=%d\n",
            mID, (int)match->isPlaying(), match->getCurrentPlayerID());
        printf("[GAME] P1 id=%d | P2 id=%d\n", Player1Context::id, Player2Context::id);

        // Lancer les deux threads joueurs
        std::thread t1(runPlayer1GameSequence, std::ref(sharedMatchID), mm);
        std::thread t2(runPlayer2GameSequence, std::ref(sharedMatchID), mm);

        t1.join();
        t2.join();

        // ─── Vérifications finales ───────────────────────────────────────
        printf("\n--- VÉRIFICATION FINALE GAME ---\n");

        match = mm->getMatchByMatchID(mID);
        CHECK(match != nullptr);
        if (match) {
            CHECK(match->isPlaying());
            printf("  [FINAL] isPlaying=%d | currentPlayerID=%d\n",
                (int)match->isPlaying(), match->getCurrentPlayerID());

            // Compter les propriétés de chaque joueur
            int p1Props = 0, p2Props = 0;
            for (int i = 0; i < 40; i++) {
                try {
                    int owner = match->getPropertyOwner(i);
                    if (owner == Player1Context::id) p1Props++;
                    if (owner == Player2Context::id) p2Props++;
                } catch (...) {}
            }
            printf("  [FINAL] P1 possède %d propriétés | P2 possède %d propriétés\n",
                p1Props, p2Props);
            printf("  [FINAL] P1 argent=%d | P2 argent=%d\n",
                match->getPlayerMoney(Player1Context::id),
                match->getPlayerMoney(Player2Context::id));
            printf("  [FINAL] P1 position=%d | P2 position=%d\n",
                match->getPlayerPosition(Player1Context::id),
                match->getPlayerPosition(Player2Context::id));
        }

        printf("\n════════════════════════════════════════════════════════════\n");
        printf("     FIN DU TEST DE SIMULATION DE PARTIE\n");
        printf("════════════════════════════════════════════════════════════\n");
    }
}
