#include "MessageParser.hpp"
#include <iostream>

Message MessageParser::parse(const std::string& message) {
    try {
        // 1. Parse the raw string into a temporary JSON object
        json j = json::parse(message);

        // 2. Return the Message object
        return Message(
            j.at("mainID").get<Codes::MainID>(),
            j.at("subID").get<int>(),
            j.at("clientID").get<int>(),
            j.at("data")
        );

    } catch (nlohmann::json::parse_error& e) {
        std::cerr << "[MessageParser] JSON invalide : " << e.what() << "\n";
        throw; // on relance pour que le serveur puisse gérer
    }
}
