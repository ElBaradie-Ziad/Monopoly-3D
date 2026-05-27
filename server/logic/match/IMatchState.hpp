#pragma once
#include "Code.hpp"
#include <optional>
#include "Message.hpp"


class Match;
struct returnExecute {
        bool ok;
        Codes::ErrorCode error;

        static returnExecute success() {
            return {true, Codes::ErrorCode::NO_ERROR};
        }

        static returnExecute failure(Codes::ErrorCode error) {
            return {false, error};
        }
    };

class IMatchState {
private:

public:
    virtual returnExecute canExecute(const Match& match, const Message& msg) = 0;
    virtual ~IMatchState() = default;
};
