#pragma once

#include "IObserver.hpp"
#include "Message.hpp"
#include "json.hpp"
#include <vector>

using json = nlohmann::json;

class IController {
protected:
    std::vector<IObserver*> obs;

public:
    IController(std::vector<IObserver*> obs) : obs(obs) {}
    virtual ~IController() = default;
    
    virtual void handler(const Message& msg) = 0;
};
