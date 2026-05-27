#pragma once

#include "Message.hpp"

class MessageParser {
public:
    static Message parse(const std::string& message);
};
