#pragma once

#include "Match.hpp"
#include "Message.hpp"
#include "IObserver.hpp"
#include "ICommand.hpp"

namespace Monopoly::Lobby {
    class CmdStartGame : public ICommand {
    public:
        void execute(Match* match, const Message& msg, std::vector<IObserver*> obs);
        
        static void run(Match* match, const Message& msg, std::vector<IObserver*> obs);
    };
}
