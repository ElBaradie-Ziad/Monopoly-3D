#pragma once

#include "Match.hpp"
#include "Message.hpp"
#include "IObserver.hpp"
#include "ICommand.hpp"

#ifdef TEST_MODE
#include <map>
#include <utility>
#include <mutex>
#endif

namespace Monopoly::Game {
    class CmdRollDice : public ICommand {
    public:
        void execute(Match* match, const Message& msg, std::vector<IObserver*> obs);
        static void run(Match* match, const Message& msg, std::vector<IObserver*> obs);

#ifdef TEST_MODE
        static void setForcedDice(int clientID, int d1, int d2) {
            std::lock_guard<std::mutex> lock(diceMtx);
            forcedDiceMap[clientID] = {d1, d2};
        }
        static void clearForcedDice(int clientID) {
            std::lock_guard<std::mutex> lock(diceMtx);
            forcedDiceMap.erase(clientID);
        }
        static void clearAllForcedDice() {
            std::lock_guard<std::mutex> lock(diceMtx);
            forcedDiceMap.clear();
        }
    private:
        static std::map<int, std::pair<int,int>> forcedDiceMap;
        static std::mutex diceMtx;
#endif

    private:
        static void applyCardEffect(Match* match, int clientID, int cardID);
        static GameState::TurnPhase applyConsequences(Match* match, int clientID, int d1, int d2, int* outCardID);
    };
}
