#include <fstream>
#include <stdexcept>
#include "json.hpp"
#include "ServerConfig.hpp"

using json = nlohmann::json;

ServerConfig ServerConfig::loadFromFile(const std::string& path) {
    std::ifstream file(path);

    if (!file.is_open()) {
        throw std::runtime_error("Pas capable d'ouvrir:  " + path);
    }

    json j;
    file >> j;

    ServerConfig config;

    config.port = j.at("port").get<uint16_t>();

    config.maxClients = j.value("maxClients", 100);
    config.timeoutSeconds = j.value("timeoutSeconds", 30);
    config.debug = j.value("debug", true);

    return config;
}