#pragma once

#include "ThreadSafeQueue.hpp"
#include "IObserver.hpp"
#include "GameController.hpp"
#include "LobbyController.hpp"
#include "AuthController.hpp"
#include "Message.hpp"
#include <vector>

class LogicDispatcher {
private:
    ThreadSafeQueue& queue;
    std::vector<IObserver*> obs;

    GameController game;
    LobbyController lobby;
    AuthController auth;
    
    void dispatch(Message msg);

public:
    LogicDispatcher(ThreadSafeQueue& queue, std::vector<IObserver*> obs);
    ~LogicDispatcher() = default;

    void run ();
};
