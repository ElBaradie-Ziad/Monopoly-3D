#pragma once

#include "IController.hpp"
#include "IMatchState.hpp"
#include "Match.hpp"
#include "Message.hpp"
#include "IObserver.hpp"

using commandFunc = void(*)(Match*, const Message&, std::vector<IObserver*>);

class GameController : public IController {
private:
    std::vector<commandFunc> handlers;
    

public:
    GameController(std::vector<IObserver*> obs); 

    void handler(const Message& msg) override;
};
