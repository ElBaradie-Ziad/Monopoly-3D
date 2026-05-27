#include "MessageBuilder.hpp"

json MessageBuilder::buildResponse(Codes::MainID mainID, int subID, const json& data) {
    json safeData = (data.is_null() || data.empty()) ? json::object() : data;

    return {
        {"mainID", mainID},
        {"subID",  subID},
        {"erreur", false},
        {"data",   safeData}
    };
}

json MessageBuilder::buildServerPush(int eventType, const json& payload) {
    json safePayload = (payload.is_null() || payload.empty()) ? json::object() : payload;

    return {
        {"mainID", Codes::MainID::SERVER_PUSH},
        {"subID",  Codes::SubID::Server_Push::EVENT_TYPE},
        {"erreur", false},
        {"data",   {
            {"eventType", eventType},
            {"payload", safePayload}
        }}
    };
}

json MessageBuilder::buildError(Codes::MainID mainID, int subID,
                    Codes::ErrorCode errorCode) {
    return {
        {"mainID", mainID},
        {"subID",  subID},
        {"erreur", true},
        {"data", {
            {"codeErreur",    errorCode},
            {"messageErreur", Codes::ErrorMessage[errorCode]}
        }}
    };
}
