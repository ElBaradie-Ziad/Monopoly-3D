#include "StateFinished.hpp"
#include "Match.hpp"
#include "Message.hpp"

Codes::ErrorCode StateFinished::errorForGameCommand(int subID) {
    switch (subID) {
        case Codes::SubID::Game::DICE_ROLLED:
            return Codes::ErrorCode::CANNOT_ROLL_DICE;
        case Codes::SubID::Game::GOT_OUT_OF_JAIL:
            return Codes::ErrorCode::CANNOT_GET_OUT_JAIL;
        case Codes::SubID::Game::USE_CARD:
            return Codes::ErrorCode::CANNOT_USE_CARD;
        case Codes::SubID::Game::PROPERTY_BOUGHT:
            return Codes::ErrorCode::CANNOT_BUY_PROPERTY;
        case Codes::SubID::Game::HOUSE_BUILT:
            return Codes::ErrorCode::CANNOT_BUY_HOUSE;
        case Codes::SubID::Game::END_TURN:
            return Codes::ErrorCode::CANNOT_END_TURN;
        case Codes::SubID::Game::READY_NEXT_TURN:
            return Codes::ErrorCode::CANNOT_READY_NEXT_TURN;
        default:
            return Codes::ErrorCode::UNKNOWN_ERROR;
    }
}

returnExecute StateFinished::canExecute(const Match& match, const Message& msg) {
    if (msg.mainID != Codes::MainID::GAME) {
        return returnExecute::failure(Codes::ErrorCode::UNKNOWN_ERROR);
    }

    return returnExecute::failure(errorForGameCommand(msg.subID));
}