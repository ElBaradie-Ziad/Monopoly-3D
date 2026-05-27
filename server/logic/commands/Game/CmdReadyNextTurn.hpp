#pragma once

#include "Match.hpp"
#include "Message.hpp"
#include "IObserver.hpp"
#include "ICommand.hpp"

namespace Monopoly::Game {
    class CmdReadyNextTurn : public ICommand {
    public:
        void execute(Match* match, const Message& msg, std::vector<IObserver*> obs);
        
        static void run(Match* match, const Message& msg, std::vector<IObserver*> obs);
    };
}
