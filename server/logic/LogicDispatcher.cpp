#include "LogicDispatcher.hpp"
#include "MessageValidator.hpp"
#include "MessageBuilder.hpp"
#include "Code.hpp"

LogicDispatcher::LogicDispatcher
    (ThreadSafeQueue& queue, std::vector<IObserver*> obs)
    : queue(queue), obs(obs),
    game(obs), lobby(obs), auth(obs) {}

void LogicDispatcher::run() {
    while (true) {
        Message msg = queue.pop();

        if (!MessageValidator::validate(msg)) {
            json response = MessageBuilder::buildError(msg.mainID, msg.subID, Codes::ErrorCode::BAD_JSON);
            std::vector<int> recipients = { msg.clientID };

            for (IObserver* o : obs) {
                o->update(response, recipients);
            }
        } else
            dispatch(msg);
    }
}

void LogicDispatcher::dispatch(Message msg) {
    json data;
    json response;
    std::vector<int> recipients;

    switch (msg.mainID) {
    case Codes::MainID::AUTHENTIFICATION:
        auth.handler(msg);
        break;

    case Codes::MainID::LOBBY:
        lobby.handler(msg);
        break;

    case Codes::MainID::GAME:
        game.handler(msg);
        break;

    default:
        json response = MessageBuilder::buildError(msg.mainID, msg.subID, Codes::ErrorCode::BAD_JSON);
        std::vector<int> recipients = { msg.clientID };

        for (IObserver* o : obs) {
            o->update(response, recipients);
        }
    }
}
