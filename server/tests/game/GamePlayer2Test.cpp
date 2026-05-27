#include "GamePlayer2Test.hpp"
#include "Player2Context.hpp"
#include "Player1Context.hpp"
#include "Match.hpp"
#include "GameState.hpp"
#include "Code.hpp"
#include "CmdRollDice.hpp"
#include "MessageBuilder.hpp"
#include <UnitTest++/UnitTest++.h>
#include <thread>
#include <chrono>
#include <atomic>
#include <functional>

static void p2Poll(int count, int ms, std::function<bool()> condition) {
    for (int i = 0; i < count; i++) {
        Player2Context::c->poll();
        if (condition()) return;
        std::this_thread::sleep_for(std::chrono::milliseconds(ms));
    }
}

static void p2RollDice() {
    json msg = {
        {"mainID", 3}, {"subID", 1},
        {"clientID", Player2Context::id},
        {"data", json::object()}
    };
    Player2Context::c->send(Player2Context::h, msg.dump(), websocketpp::frame::opcode::text);
    p2Poll(15, 50, [&]() {
        return Player2Context::lastResponse.contains("subID") && 
               Player2Context::lastResponse["subID"].get<int>() == 1;
    });
}

static void p2BuyProperty(int propertyID) {
    json msg = {
        {"mainID", 3}, {"subID", 4},
        {"clientID", Player2Context::id},
        {"data", {{"propertyID", propertyID}}}
    };
    Player2Context::c->send(Player2Context::h, msg.dump(), websocketpp::frame::opcode::text);
    p2Poll(15, 50, [&]() {
        return Player2Context::lastResponse.contains("subID") && 
               Player2Context::lastResponse["subID"].get<int>() == 4;
    });
}

static void p2EndTurn() {
    json msg = {
        {"mainID", 3}, {"subID", 6},
        {"clientID", Player2Context::id},
        {"data", json::object()}
    };
    Player2Context::c->send(Player2Context::h, msg.dump(), websocketpp::frame::opcode::text);
    p2Poll(15, 50, [&]() {
        return Player2Context::lastResponse.contains("subID") && 
               Player2Context::lastResponse["subID"].get<int>() == 6;
    });
}

static void p2ReadyNextTurn() {
    json msg = {
        {"mainID", 3}, {"subID", 7},
        {"clientID", Player2Context::id},
        {"data", json::object()}
    };
    Player2Context::c->send(Player2Context::h, msg.dump(), websocketpp::frame::opcode::text);
    p2Poll(15, 50, [&]() {
        return Player2Context::lastResponse.contains("subID") && 
               Player2Context::lastResponse["subID"].get<int>() == 7;
    });
}

static void p2WaitForMyTurn(MatchManager* mm, int mID) {
    bool sentReady = false;
    size_t startIdx = Player2Context::messages.size();
    printf("  [P2 WAIT] Attente de mon tour (ID=%d)...\n", Player2Context::id);
    
    p2Poll(300, 50, [&]() {
        Match* m = mm->getMatchByMatchID(mID);
        if (!m) return false;

        // Chercher TURN_CHANGED uniquement parmi les NOUVEAUX messages
        json turnEvent;
        auto& msgs = Player2Context::messages;
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
            if (currentID == Player2Context::id) {
                if (m->getCurrentPlayerID() == Player2Context::id &&
                    (m->getTurnPhase() == GameState::TurnPhase::BEFORE_ROLL ||
                     m->getTurnPhase() == GameState::TurnPhase::JAIL_CHOICE)) {
                    return true;
                }
            }
        }

        if (!sentReady &&
            m->getCurrentPlayerID() != Player2Context::id &&
            m->getTurnPhase() == GameState::TurnPhase::WAITING_NEXT_TURN_READY) {
            printf("  [P2 AUTO] Envoi READY_NEXT_TURN (phase detected)\n");
            json msg = {
                {"mainID", 3}, {"subID", 7},
                {"clientID", Player2Context::id},
                {"data", json::object()}
            };
            Player2Context::c->send(Player2Context::h, msg.dump(), websocketpp::frame::opcode::text);
            sentReady = true;
        }

        if (sentReady && m->getTurnPhase() != GameState::TurnPhase::WAITING_NEXT_TURN_READY) {
            sentReady = false;
        }

        return false;
    });

    printf("  [P2 WAIT] Mon tour (ID=%d) commence !\n", Player2Context::id);
    std::this_thread::sleep_for(std::chrono::milliseconds(200));
}

void runPlayer2GameSequence(std::atomic<int>& sharedMatchID, MatchManager* mm) {
    int mID = sharedMatchID.load();
    if (mID == -1) { printf("[P2 GAME] Pas de matchID!\n"); return; }
    Match* match = mm->getMatchByMatchID(mID);
    if (!match) { printf("[P2 GAME] Match introuvable!\n"); return; }

    printf("\n[P2 GAME] === DEBUT SÉQUENCE GAME (clientID=%d) ===\n", Player2Context::id);
    Player2Context::lastResponse = json::object();

    // Attendre TURN_CHANGED du lobby start (déjà dans le buffer ou arrive bientôt)
    p2Poll(100, 50, [&]() {
        json event = Player2Context::findEvent(Codes::EventType::TURN_CHANGED);
        return !event.empty();
    });

    p2WaitForMyTurn(mm, mID);

    // TOUR 2
    {
        printf("[P2 GAME] Tour 2 - Mon tour\n");
        CHECK_EQUAL(Player2Context::id, match->getCurrentPlayerID());
        Monopoly::Game::CmdRollDice::setForcedDice(Player2Context::id, 1, 5);
        p2RollDice();
        p2BuyProperty(6);
        p2EndTurn();
        p2ReadyNextTurn();
    }

    p2WaitForMyTurn(mm, mID);

    // TOUR 4
    {
        printf("[P2 GAME] Tour 4 - Achat + test passage Départ\n");
        CHECK_EQUAL(Player2Context::id, match->getCurrentPlayerID());
        Monopoly::Game::CmdRollDice::setForcedDice(Player2Context::id, 2, 1);
        p2RollDice();
        p2BuyProperty(9);
        p2EndTurn();
        p2ReadyNextTurn();
    }

    p2WaitForMyTurn(mm, mID);

    // TOUR 6
    {
        printf("[P2 GAME] Tour 6 - Achat compagnie électricité\n");
        CHECK_EQUAL(Player2Context::id, match->getCurrentPlayerID());
        Monopoly::Game::CmdRollDice::setForcedDice(Player2Context::id, 2, 1);
        p2RollDice();
        p2BuyProperty(12);
        p2EndTurn();
        p2ReadyNextTurn();
    }

    p2WaitForMyTurn(mm, mID);

    // TOUR 8
    {
        printf("[P2 GAME] Tour 8 - Achat Gare de Lyon\n");
        CHECK_EQUAL(Player2Context::id, match->getCurrentPlayerID());
        Monopoly::Game::CmdRollDice::setForcedDice(Player2Context::id, 2, 1);
        p2RollDice();
        p2BuyProperty(15);
        p2EndTurn();
        p2ReadyNextTurn();
    }

    p2WaitForMyTurn(mm, mID);

    // TOUR 10
    {
        printf("[P2 GAME] Tour 10 - Achat 2ème gare (Gare du Nord)\n");
        CHECK_EQUAL(Player2Context::id, match->getCurrentPlayerID());
        Monopoly::Game::CmdRollDice::setForcedDice(Player2Context::id, 5, 5); 
        p2RollDice();
        p2BuyProperty(25);
        Monopoly::Game::CmdRollDice::setForcedDice(Player2Context::id, 5, 4);
        p2RollDice();
        if (match->getTurnPhase() == GameState::TurnPhase::PROPERTY_CHOICE) {
            p2BuyProperty(match->getPlayerPosition(Player2Context::id));
        }
        p2EndTurn();
        p2ReadyNextTurn();
    }

    p2WaitForMyTurn(mm, mID);

    // TOUR 12
    {
        printf("[P2 GAME] Tour 12 - Achat 3ème gare (St-Lazare)\n");
        CHECK_EQUAL(Player2Context::id, match->getCurrentPlayerID());
        int pos = match->getPlayerPosition(Player2Context::id);
        int needed = (35 - pos + 40) % 40;
        Monopoly::Game::CmdRollDice::setForcedDice(Player2Context::id, needed/2, needed - needed/2);
        p2RollDice();
        p2BuyProperty(35);
        p2EndTurn();
        p2ReadyNextTurn();
    }

    p2WaitForMyTurn(mm, mID);

    // TOUR 14
    {
        printf("[P2 GAME] Tour 14 - Passage par case Départ\n");
        CHECK_EQUAL(Player2Context::id, match->getCurrentPlayerID());
        Monopoly::Game::CmdRollDice::setForcedDice(Player2Context::id, 3, 2);
        p2RollDice();
        p2EndTurn();
        p2ReadyNextTurn();
    }

    p2WaitForMyTurn(mm, mID);

    printf("[P2 GAME] Fin de simulation !\n");
}
