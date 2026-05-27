#include "AuthController.hpp"
#include "DatabaseManager.hpp"
#include "MessageBuilder.hpp"
#include "Code.hpp"

AuthController::AuthController(std::vector<IObserver*> obs) : IController(obs) {}

void AuthController::handler(const Message& msg) {
    switch (msg.subID) {
    case Codes::SubID::Auth::LOGIN:
        this->login(msg);
        break;

    case Codes::SubID::Auth::LOGOUT:
        break;

    case Codes::SubID::Auth::REGISTER:
        this->registerUser(msg);
        break;

    default:
        break;
    }
}

void AuthController::login(const Message& msg) {
    std::vector<int> recipients = { msg.clientID };
    
    std::hash<std::string> h;
    std::optional<User> loggedInUser = DatabaseManager::login(msg.data["username"], std::to_string(h(msg.data["password"])));

    if (loggedInUser.has_value()) {
        json response = MessageBuilder::buildResponse(msg.mainID, msg.subID, {});
        for (IObserver* o : obs) {
            o->update(response, recipients);
        }

    } else {
        json response = MessageBuilder::buildError(msg.mainID, msg.subID, Codes::ErrorCode::AUTH_INVALID);
        for (IObserver* o : obs) {
            o->update(response, recipients);
        }
    }
}

void AuthController::registerUser(const Message& msg) {
    std::vector<int> recipients = { msg.clientID };

    std::hash<std::string> h;
    bool success = DatabaseManager::createUser(msg.data["username"], std::to_string(h(msg.data["password"])));

    if (success) {
        json response = MessageBuilder::buildResponse(msg.mainID, msg.subID, {});
        for (IObserver* o : obs) {
            o->update(response, recipients);
        }
        
    } else {
        json response = MessageBuilder::buildError(msg.mainID, msg.subID, Codes::ErrorCode::USERNAME_TAKEN);
        for (IObserver* o : obs) {
            o->update(response, recipients);
        }
    }
}
