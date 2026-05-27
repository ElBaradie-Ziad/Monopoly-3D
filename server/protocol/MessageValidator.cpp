#include "MessageValidator.hpp"
#include <iostream>

bool MessageValidator::validate(const Message& msg) {
    // mainID must be between 1 and 3
    if (msg.mainID < 1 || msg.mainID > 3) {
        std::cerr << "[MessageValidator] Invalid mainID: " << msg.mainID << "\n";
        return false;
    }

    // Specific verification based on mainID
    if (msg.mainID == 1) return validateAuth(msg);
    if (msg.mainID == 2) return validateLobby(msg);
    if (msg.mainID == 3) return validateGame(msg);

    return true;
}

bool MessageValidator::validateAuth(const Message& msg) {
    if (msg.subID == 1 || msg.subID == 3) {
        // LOGIN and REGISTER require a username and a password
        if (!msg.data.contains("username") || !msg.data.contains("password")) {
            std::cerr << "[MessageValidator] LOGIN/REGISTER: Missing username or password\n";
            return false;
        }
    }
    // LOGOUT (subID=2) has no mandatory fields in its data payload
    return true;
}

bool MessageValidator::validateLobby(const Message& msg) {
    return true;
}

bool MessageValidator::validateGame(const Message& msg) {
    return true;
}
