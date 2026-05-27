#include "LobbyPlayer1Test.hpp"
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

static bool p1Poll(int maxTries, int msPerTry, std::function<bool()> condition) {
    for (int i = 0; i < maxTries; i++) {
        Player1Context::c->poll();
        std::this_thread::sleep_for(std::chrono::milliseconds(msPerTry));
        if (condition()) return true;
    }
    return false;
}

void runPlayer1LobbySequence(std::atomic<int>& sharedMatchID, MatchManager* mm) {
    if (Player1Context::id == -1 || !Player1Context::c) {
        printf("[P1] ERREUR: non connecté.\n");
        return;
    }
    printf("\n[P1] === DEBUT SÉQUENCE LOBBY (clientID=%d) ===\n", Player1Context::id);

    // ─── ÉTAPE 1 : Créer le lobby ──────────────────────────────────────────
    json createLobby = {
        {"mainID", 2}, {"subID", 1},
        {"clientID", Player1Context::id},
        {"data", {
            {"username", "player_test_1"},
            {"mapID", 1},
            {"numberTurn", 50},
            {"moneyStart", 1500}
        }}
    };
    Player1Context::c->send(Player1Context::h, createLobby.dump(), websocketpp::frame::opcode::text);

    int mID = -1;
    p1Poll(20, 50, [&]() {
        if (Player1Context::lastResponse.contains("data") &&
            Player1Context::lastResponse["data"].contains("matchID")) {
            mID = Player1Context::lastResponse["data"]["matchID"];
            sharedMatchID.store(mID);
            return true;
        }
        return false;
    });

    printf("[P1] Étape 1 – Lobby créé, MatchID=%d\n", mID);

    // >>> Vérification serveur après CREATE LOBBY
    {
        Match* match = mm->getMatchByMatchID(mID);
        CHECK(match != nullptr);
        if (match) {
            printf("  [P1 LOBBY] ID lobby=%d | Joueurs: %zu\n", 
                   mID, match->getPlayers().size());
            CHECK(match->hasPlayer(Player1Context::id));
            const Player& p1 = match->getPlayer(Player1Context::id);
            CHECK_EQUAL(1500, p1.getMoney());
            CHECK(!p1.checkIsReady());
            printf("  [SERVEUR] Match id=%d | joueurs=%zu | isWaiting=%d | P1 argent=%d | P1 prêt=%d\n",
                mID, match->getPlayers().size(), (int)match->isWaiting(),
                p1.getMoney(), (int)p1.checkIsReady());
        }
    }

    // ─── ÉTAPE 2 : Attendre que P2 rejoigne ───────────────────────────────
    p1Poll(60, 50, [&]() {
        json event = Player1Context::findEvent(Codes::EventType::LOBBY_PLAYER_JOINED);
        return !event.empty() && event["data"]["payload"]["clientID"].get<int>() != Player1Context::id;
    });
    printf("[P1] Étape 2 – Joueur 2 a rejoint\n");

    // >>> Vérification serveur : 2 joueurs, aucun prêt
    {
        Match* match = mm->getMatchByMatchID(mID);
        if (match) {
            printf("  [SERVEUR] Nombre de joueurs dans le match: %zu\n", match->getPlayers().size());
            for (const Player& p : match->getPlayers()) {
                printf("  [SERVEUR] Joueur clientID=%d | nom=%s | argent=%d | prêt=%d\n",
                    p.getId(), p.playerName.c_str(), p.getMoney(), (int)p.checkIsReady());
                CHECK_EQUAL(1500, p.getMoney());
                CHECK(!p.checkIsReady());
            }
        }
    }

    // ─── ÉTAPE 3 : P1 se marque prêt ──────────────────────────────────────
    json p1Ready = {
        {"mainID", 2}, {"subID", 4},
        {"clientID", Player1Context::id},
        {"data", { {"matchID", mID} }}
    };
    Player1Context::c->send(Player1Context::h, p1Ready.dump(), websocketpp::frame::opcode::text);

    // Attendre l'événement ET_READY (mainID 4, subID 2) pour P1
    bool eventReadyP1 = p1Poll(40, 50, [&]() {
        json event = Player1Context::findEvent(Codes::EventType::ET_READY);
        return !event.empty() && event["data"]["payload"]["clientID"].get<int>() == Player1Context::id;
    });
    printf("[P1] Étape 3 – Événement ET_READY reçu pour P1 (ok=%d)\n", (int)eventReadyP1);

    // >>> Vérification serveur : P1 (optionnel - pas encore marqué ready selon protocole)
    {
        Match* match = mm->getMatchByMatchID(mID);
        if (match && match->isWaiting()) {
            printf("  [SERVEUR] P1 (clientID=%d) a envoyé Ready\n", Player1Context::id);
        }
    }

    // ─── ÉTAPE 4 : Attendre l'événement ET_READY pour P2 ──────────────────
    p1Poll(60, 50, [&]() {
        json event = Player1Context::findEvent(Codes::EventType::ET_READY);
        if (event.empty()) return false;
        return event["data"]["payload"]["clientID"].get<int>() == Player2Context::id;
    });
    printf("[P1] Étape 4 – Événement ET_READY reçu pour P2\n");

    // >>> Vérification serveur : P2 (optionnel)
    {
        Match* match = mm->getMatchByMatchID(mID);
        if (match && match->isWaiting()) {
            printf("  [SERVEUR] P2 (clientID=%d) a envoyé Ready\n", Player2Context::id);
        }
    }

    // ─── ÉTAPE 5 : Lancer la partie ───────────────────────────────────────
    json startMsg = {
        {"mainID", 2}, {"subID", 5},
        {"clientID", Player1Context::id},
        {"data", { {"matchID", mID} }}
    };
    Player1Context::c->send(Player1Context::h, startMsg.dump(), websocketpp::frame::opcode::text);
    p1Poll(30, 50, [&]() {
        json event = Player1Context::findEvent(Codes::EventType::TURN_CHANGED);
        return !event.empty();
    });

    // >>> Vérification serveur après START
    {
        Match* match = mm->getMatchByMatchID(mID);
        if (match) {
            printf("  [P1 LOBBY] Match isPlaying=%d\n", (int)match->isPlaying());
            CHECK(match->getCurrentPlayerID() != -1);
            // Après nextTurn(), les joueurs ne sont plus marqués "prêt" (reset normal)
            printf("  [SERVEUR] isPlaying=%d | currentPlayerID=%d | phase=%d\n",
                (int)match->isPlaying(), match->getCurrentPlayerID(), (int)match->getTurnPhase());
        }
    }

    printf("[P1] === FIN SÉQUENCE LOBBY ===\n");
}
