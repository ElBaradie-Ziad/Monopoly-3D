#pragma once

#include "IController.hpp"
#include "Message.hpp"
#include "IObserver.hpp"

class AuthController : public IController {
private:
    void login(const Message& msg);
    void registerUser(const Message& msg);

public:
    AuthController(std::vector<IObserver*>);

    void handler(const Message& msg) override;
};
