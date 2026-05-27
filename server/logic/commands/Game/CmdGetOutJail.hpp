#pragma once

#include "Match.hpp"
#include "Message.hpp"
#include "IObserver.hpp"
#include "ICommand.hpp"

namespace Monopoly::Game {
    class CmdGetOutJail : public ICommand {
    public:
        void execute(Match* match, const Message& msg, std::vector<IObserver*> obs);
        
        static void run(Match* match, const Message& msg, std::vector<IObserver*> obs);
    };
}
