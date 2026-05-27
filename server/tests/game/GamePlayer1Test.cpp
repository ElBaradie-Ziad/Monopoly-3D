#include "GamePlayer1Test.hpp"
#include "Player1Context.hpp"
#include "Player2Context.hpp"
#include "Match.hpp"
#include "GameState.hpp"
#include "Player.hpp"
#include "Code.hpp"
#include "CmdRollDice.hpp"
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

static void p1RollDice() {
    json msg = {
        {"mainID", 3}, {"subID", 1},
        {"clientID", Player1Context::id},
        {"data", json::object()}
    };
    Player1Context::c->send(Player1Context::h, msg.dump(), websocketpp::frame::opcode::text);
    p1Poll(20, 50, [&]() {
        return Player1Context::lastResponse.contains("subID") &&
               Player1Context::lastResponse["subID"].get<int>() == 1;
    });
}

static void p1BuyProperty(int propertyID) {
    json msg = {
        {"mainID", 3}, {"subID", 4},
        {"clientID", Player1Context::id},
        {"data", {{"propertyID", propertyID}}}
    };
    Player1Context::c->send(Player1Context::h, msg.dump(), websocketpp::frame::opcode::text);
    p1Poll(15, 50, [&]() {
        return Player1Context::lastResponse.contains("subID") &&
               Player1Context::lastResponse["subID"].get<int>() == 4;
    });
}

static void p1EndTurn() {
    json msg = {
        {"mainID", 3}, {"subID", 6},
        {"clientID", Player1Context::id},
        {"data", json::object()}
    };
    Player1Context::c->send(Player1Context::h, msg.dump(), websocketpp::frame::opcode::text);
    p1Poll(15, 50, [&]() {
        return Player1Context::lastResponse.contains("subID") &&
               Player1Context::lastResponse["subID"].get<int>() == 6;
    });
}

static void p1ReadyNextTurn() {
    json msg = {
        {"mainID", 3}, {"subID", 7},
        {"clientID", Player1Context::id},
        {"data", json::object()}
    };
    Player1Context::c->send(Player1Context::h, msg.dump(), websocketpp::frame::opcode::text);
    p1Poll(20, 50, [&]() {
        return Player1Context::lastResponse.contains("subID") &&
               Player1Context::lastResponse["subID"].get<int>() == 7;
    });
}

static void p1PayJail() {
    json msg = {
        {"mainID", 3}, {"subID", 2},
        {"clientID", Player1Context::id},
        {"data", {{"method", "pay"}}}
    };
    Player1Context::c->send(Player1Context::h, msg.dump(), websocketpp::frame::opcode::text);
    p1Poll(15, 50, [&]() {
        return Player1Context::lastResponse.contains("subID") &&
               Player1Context::lastResponse["subID"].get<int>() == 2;
    });
}

static void p1WaitTurnChanged() {
    p1Poll(100, 50, [&]() {
        json event = Player1Context::findEvent(Codes::EventType::TURN_CHANGED);
        return !event.empty();
    });
}

static void p1WaitForMyTurn(MatchManager* mm, int mID) {
    bool sentReady = false;
    size_t startIdx = Player1Context::messages.size();
    printf("  [P1 WAIT] Attente de mon tour (ID=%d)...\n", Player1Context::id);
    
    p1Poll(300, 50, [&]() {
        Match* m = mm->getMatchByMatchID(mID);
        if (!m) return false;

        json turnEvent;
        auto& msgs = Player1Context::messages;
        for (size_t i = startIdx; i < msgs.size(); i++) {
            if (msgs[i].contains("mainID") && msgs[i]["mainID"].get<int>() == 4 &&
                msgs[i]["data"].contains("eventType") &&
                msgs[i]["data"]["eventType"].get<int>() == Codes::EventType::TURN_CHANGED) {
                turnEvent = msgs[i];
                break;
            }
        }

        if (!turnEvent.empty() && turnEvent.contains("data") && turnEvent["data"].contains("currentClientID") && !turnEvent["data"]["currentClientID"].is_null()) {
            int currentID = turnEvent["data"]["currentClientID"].get<int>();
            if (currentID == Player1Context::id) {
                if (m->getCurrentPlayerID() == Player1Context::id &&
                    (m->getTurnPhase() == GameState::TurnPhase::BEFORE_ROLL ||
                     m->getTurnPhase() == GameState::TurnPhase::JAIL_CHOICE)) {
                    return true;
                }
            }
        }

        if (!sentReady &&
            m->getCurrentPlayerID() != Player1Context::id &&
            m->getTurnPhase() == GameState::TurnPhase::WAITING_NEXT_TURN_READY) {
            printf("  [P1 AUTO] Envoi READY_NEXT_TURN (phase detected)\n");
            json msg = {
                {"mainID", 3}, {"subID", 7},
                {"clientID", Player1Context::id},
                {"data", json::object()}
            };
            Player1Context::c->send(Player1Context::h, msg.dump(), websocketpp::frame::opcode::text);
            sentReady = true;
        }

        if (sentReady && m->getTurnPhase() != GameState::TurnPhase::WAITING_NEXT_TURN_READY) {
            sentReady = false;
        }

        return false;
    });

    printf("  [P1 WAIT] Mon tour (ID=%d) commence !\n", Player1Context::id);
    std::this_thread::sleep_for(std::chrono::milliseconds(200));
}

void runPlayer1GameSequence(std::atomic<int>& sharedMatchID, MatchManager* mm) {
    int mID = sharedMatchID.load();
    if (mID == -1) { printf("[P1 GAME] Pas de matchID!\n"); return; }
    Match* match = mm->getMatchByMatchID(mID);
    if (!match) { printf("[P1 GAME] Match introuvable!\n"); return; }

    printf("\n[P1 GAME] === DEBUT SÉQUENCE GAME (clientID=%d) ===\n", Player1Context::id);
    Player1Context::lastResponse = json::object();

    p1WaitTurnChanged();

    // TOUR 1
    if (match->getCurrentPlayerID() == Player1Context::id) {
        printf("[P1 GAME] Tour 1 - Mon tour\n");
        Monopoly::Game::CmdRollDice::setForcedDice(Player1Context::id, 1, 2); 
        p1RollDice();
        p1BuyProperty(3);
        p1EndTurn();
        p1ReadyNextTurn();
    }

    // TOUR 2
    p1WaitForMyTurn(mm, mID);

    // TOUR 3
    {
        printf("[P1 GAME] Tour 3 - 3 doubles consécutifs\n");
        CHECK_EQUAL(Player1Context::id, match->getCurrentPlayerID());
        Monopoly::Game::CmdRollDice::setForcedDice(Player1Context::id, 1, 1);
        p1RollDice();
        p1BuyProperty(5);
        Monopoly::Game::CmdRollDice::setForcedDice(Player1Context::id, 3, 3);
        p1RollDice();
        p1BuyProperty(11);
        Monopoly::Game::CmdRollDice::setForcedDice(Player1Context::id, 4, 4);
        p1RollDice();
        p1ReadyNextTurn();
    }

    // TOUR 4
    p1WaitForMyTurn(mm, mID);

    // TOUR 5
    {
        printf("[P1 GAME] Tour 5 - En prison, lancer non-double\n");
        CHECK_EQUAL(Player1Context::id, match->getCurrentPlayerID());
        Monopoly::Game::CmdRollDice::setForcedDice(Player1Context::id, 1, 2);
        p1RollDice();
        p1ReadyNextTurn();
    }

    // TOUR 6
    p1WaitForMyTurn(mm, mID);

    // TOUR 7
    {
        printf("[P1 GAME] Tour 7 - En prison, lancer double → sort\n");
        CHECK_EQUAL(Player1Context::id, match->getCurrentPlayerID());
        Monopoly::Game::CmdRollDice::setForcedDice(Player1Context::id, 3, 3);
        p1RollDice();
        p1BuyProperty(16);
        if (match->getTurnPhase() == GameState::TurnPhase::BEFORE_ROLL) {
            Monopoly::Game::CmdRollDice::setForcedDice(Player1Context::id, 2, 1);
            p1RollDice();
            if (match->getTurnPhase() == GameState::TurnPhase::PROPERTY_CHOICE) {
                p1BuyProperty(match->getPlayerPosition(Player1Context::id));
            }
        }
        p1EndTurn();
        p1ReadyNextTurn();
    }

    // TOUR 8
    p1WaitForMyTurn(mm, mID);

    // TOUR 9
    {
        printf("[P1 GAME] Tour 9 - Test de loyer rue\n");
        CHECK_EQUAL(Player1Context::id, match->getCurrentPlayerID());
        int p1Pos = match->getPlayerPosition(Player1Context::id);
        int target = 6; 
        int needed = (target - p1Pos + 40) % 40;
        if (needed >= 2 && needed <= 12) {
            Monopoly::Game::CmdRollDice::setForcedDice(Player1Context::id, needed/2, needed - needed/2);
            p1RollDice();
        } else {
            Monopoly::Game::CmdRollDice::setForcedDice(Player1Context::id, 1, 2);
            p1RollDice();
        }
        p1EndTurn();
        p1ReadyNextTurn();
    }

    // TOUR 10
    p1WaitForMyTurn(mm, mID);

    // TOUR 11
    {
        printf("[P1 GAME] Tour 11 - Aller en prison (case 30)\n");
        CHECK_EQUAL(Player1Context::id, match->getCurrentPlayerID());
        int p1Pos = match->getPlayerPosition(Player1Context::id);
        int needed = (30 - p1Pos + 40) % 40;
        if (needed >= 2 && needed <= 12) {
            Monopoly::Game::CmdRollDice::setForcedDice(Player1Context::id, needed/2, needed - needed/2);
            p1RollDice();
            p1ReadyNextTurn();
        } else {
            Monopoly::Game::CmdRollDice::setForcedDice(Player1Context::id, 1, 2);
            p1RollDice();
            p1EndTurn();
            p1ReadyNextTurn();
        }
    }

    // TOUR 12
    p1WaitForMyTurn(mm, mID);

    // TOUR 13
    {
        printf("[P1 GAME] Tour 13 - Sortir de prison en payant 50€\n");
        CHECK_EQUAL(Player1Context::id, match->getCurrentPlayerID());
        if (match->isPlayerInJail(Player1Context::id)) {
            p1PayJail();
            Monopoly::Game::CmdRollDice::setForcedDice(Player1Context::id, 1, 2);
            p1RollDice();
        }
        p1EndTurn();
        p1ReadyNextTurn();
    }

    // TOUR 14
    p1WaitForMyTurn(mm, mID);

    // TOUR 15
    {
        printf("[P1 GAME] Tour 15 - Test de loyer gare (3 gares = 100€)\n");
        CHECK_EQUAL(Player1Context::id, match->getCurrentPlayerID());
        int p1Pos = match->getPlayerPosition(Player1Context::id);
        int target = 15;
        int needed = (target - p1Pos + 40) % 40;
        Monopoly::Game::CmdRollDice::setForcedDice(Player1Context::id, needed/2, needed - needed/2);
        p1RollDice();
        p1EndTurn();
        p1ReadyNextTurn();
    }

    printf("[P1 GAME] === FIN SÉQUENCE GAME ===\n");
}
