#pragma once

#include <string>

struct ServerConfig {
    //default au cas ou le fichier plante 
    int port = 10000;
    int maxClients = 100;
    int timeoutSeconds = 30;
    bool debug = false;

    static ServerConfig loadFromFile(const std::string& path);
};