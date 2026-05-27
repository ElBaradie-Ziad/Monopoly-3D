#pragma once

#include "Message.hpp"

class MessageValidator {
public:
    // Valide la structure générale du message
    // Retourne true si valide, false sinon
    static bool validate(const Message& msg);

private:
    // Vérifie les champs spécifiques selon mainID et subID
    static bool validateAuth(const Message& msg);    // mainID = 1
    static bool validateLobby(const Message& msg);   // mainID = 2
    static bool validateGame(const Message& msg);    // mainID = 3
};
