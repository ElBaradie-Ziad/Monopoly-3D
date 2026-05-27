#pragma once

#include "Message.hpp"
#include <vector>
#include <iostream>

class Match;
class IObserver;

class ICommand {
public:
    virtual void execute(Match* match, const Message& msg, std::vector<IObserver*> server) = 0;
    virtual ~ICommand() = default;
};
