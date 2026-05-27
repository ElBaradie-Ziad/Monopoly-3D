#pragma once

#include "json.hpp"
#include "Code.hpp"

using json = nlohmann::json;

class MessageBuilder {
public:
    // Construit une réponse directe à un client
    static json buildResponse(Codes::MainID mainID, int subID, const json& data);

    // Construit une réponse Serrver Push
    static json buildServerPush(int eventType, const json& payload);

    // Construit une réponse d'erreur standard
    static json buildError(Codes::MainID mainID, int subID,
                    Codes::ErrorCode errorCode);
};
