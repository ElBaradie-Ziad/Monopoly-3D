#pragma once

#include "IMatchState.hpp"

class StateFinished : public IMatchState {
private:
    Codes::ErrorCode errorForGameCommand(int id);
public:
    returnExecute canExecute(const Match& match, const Message& msg);
};
