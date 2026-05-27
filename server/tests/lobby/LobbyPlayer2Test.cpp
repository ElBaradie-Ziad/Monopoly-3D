#include "LobbyPlayer2Test.hpp"
#include "Player1Context.hpp"
#include "Player2Context.hpp"
#include "Match.hpp"
#include "GameState.hpp"
#include "Player.hpp"
#include "Code.hpp"
#include <UnitTest++/UnitTest++.h>
#include <iostream>
#include <thread>
#include <chrono>
#include <functional>

static bool p2Poll(int maxTries, int msPerTry, std::function<bool()> condition) {
    for (int i = 0; i < maxTries; i++) {
        Player2Context::c->poll();
        std::this_thread::sleep_for(std::chrono::milliseconds(msPerTry));
        if (condition()) return true;
    }
    return false;
}

void runPlayer2LobbySequence(std::atomic<int>& sharedMatchID, MatchManager* mm) {
    if (Player2Context::id == -1 || !Player2Context::c) {
        printf("[P2] ERREUR: non connecté.\n");
        return;
    }
    printf("\n[P2] === DEBUT SÉQUENCE LOBBY (clientID=%d) ===\n", Player2Context::id);

    // ─── ÉTAPE 1 : Attendre que P1 crée le lobby ──────────────────────────
    int mID = -1;
    p2Poll(60, 50, [&]() {
        mID = sharedMatchID.load();
        return mID != -1;
    });

    if (mID == -1) {
        printf("[P2] ERREUR: MatchID non reçu à temps.\n");
        return;
    }
    printf("[P2] Étape 1 – MatchID reçu: %d\n", mID);

    // >>> Vérification serveur : le match existe avec 1 joueur
    {
        Match* match = mm->getMatchByMatchID(mID);
        CHECK(match != nullptr);
        if (match) {
            printf("  [P2 LOBBY] Match trouvé: id=%d | Joueurs: %zu\n",
                mID, match->getPlayers().size());
            CHECK(match->isWaiting());
        }
    }

    // ─── ÉTAPE 2 : Rejoindre le lobby ─────────────────────────────────────
    json joinLobby = {
        {"mainID", 2}, {"subID", 3},
        {"clientID", Player2Context::id},
        {"data", {
            {"matchID", mID},
            {"username", "player_test_2"}
        }}
    };
    Player2Context::c->send(Player2Context::h, joinLobby.dump(), websocketpp::frame::opcode::text);

    // Attendre l'ACK JOIN (subID=3, erreur=false)
    p2Poll(20, 50, [&]() {
        return Player2Context::lastResponse.contains("subID") &&
               Player2Context::lastResponse["subID"].get<int>() == 3 &&
               Player2Context::lastResponse.contains("erreur") &&
               !Player2Context::lastResponse["erreur"].get<bool>();
    });
    printf("[P2] Étape 2 – A rejoint le Lobby %d\n", mID);

    // >>> Vérification serveur : 2 joueurs dans le match
    {
        Match* match = mm->getMatchByMatchID(mID);
        if (match) {
            CHECK_EQUAL(2, match->getPlayers().size());
            CHECK(match->hasPlayer(Player2Context::id));
            const Player& p2 = match->getPlayer(Player2Context::id);
            CHECK_EQUAL(1500, p2.getMoney());
            CHECK(!p2.checkIsReady());
            printf("  [SERVEUR] Joueurs dans match=%zu | P2 argent=%d | P2 prêt=%d\n",
                match->getPlayers().size(), p2.getMoney(), (int)p2.checkIsReady());
        }
    }

    // ─── ÉTAPE 3 : Attendre le server push ET_READY de P1 ─────────────────
    p2Poll(60, 50, [&]() {
        json event = Player2Context::findEvent(Codes::EventType::ET_READY);
        return !event.empty() && event["data"]["payload"]["clientID"].get<int>() != Player2Context::id;
    });
    printf("[P2] Étape 3 – Joueur 1 est prêt\n");

    // >>> Vérification serveur : P1 est bien prêt
    // Seulement si la partie n'a pas déjà démarré (nextTurn réinitialise les flags)
    {
        Match* match = mm->getMatchByMatchID(mID);
        if (match && match->isWaiting()) {
            printf("  [SERVEUR] P1 (clientID=%d) a envoyé Ready\n", Player1Context::id);
        }
    }

    // ─── ÉTAPE 4 : P2 se marque prêt ──────────────────────────────────────
    json p2Ready = {
        {"mainID", 2}, {"subID", 4},
        {"clientID", Player2Context::id},
        {"data", { {"matchID", mID} }}
    };
    Player2Context::c->send(Player2Context::h, p2Ready.dump(), websocketpp::frame::opcode::text);

    // Attendre l'événement ET_READY pour P2
    bool eventReadyP2 = p2Poll(30, 50, [&]() {
        json event = Player2Context::findEvent(Codes::EventType::ET_READY);
        return !event.empty() && event["data"]["payload"]["clientID"].get<int>() == Player2Context::id;
    });
    printf("[P2] Étape 4 – Événement ET_READY reçu pour P2 (ok=%d)\n", (int)eventReadyP2);

    // >>> Vérification serveur : P2 (optionnel)
    {
        Match* match = mm->getMatchByMatchID(mID);
        if (match && match->isWaiting()) {
            printf("  [SERVEUR] P2 (clientID=%d) a envoyé Ready\n", Player2Context::id);
        }
    }

    // ─── ÉTAPE 5 : P2 envoie aussi Start ──────────────────────────────────
    json startMsg = {
        {"mainID", 2}, {"subID", 5},
        {"clientID", Player2Context::id},
        {"data", { {"matchID", mID} }}
    };
    Player2Context::c->send(Player2Context::h, startMsg.dump(), websocketpp::frame::opcode::text);
    p2Poll(30, 50, [&]() {
        json event = Player2Context::findEvent(Codes::EventType::TURN_CHANGED);
        return !event.empty();
    });

    // >>> Vérification serveur finale : partie en cours
    {
        Match* match = mm->getMatchByMatchID(mID);
        if (match) {
            printf("  [P2 LOBBY] Match isPlaying=%d\n", (int)match->isPlaying());
            CHECK(match->isPlaying());
            CHECK(match->getCurrentPlayerID() != -1);
            printf("  [SERVEUR] isPlaying=%d | currentPlayerID=%d\n",
                (int)match->isPlaying(), match->getCurrentPlayerID());
        }
    }

    printf("[P2] === FIN SÉQUENCE LOBBY ===\n");
}
