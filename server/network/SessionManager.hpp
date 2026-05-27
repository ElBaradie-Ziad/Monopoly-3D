#pragma once

#define ASIO_STANDALONE

#include "websocketpp/config/asio.hpp"
#include "websocketpp/server.hpp"
#include "Session.hpp"
#include "json.hpp"

using json = nlohmann::json;
using ConnectionHandle = websocketpp::connection_hdl;

class SessionManager {
private:
    std::map<int, Session> sessions;
    int nextSession = 1;

    std::map<ConnectionHandle, int, std::owner_less<ConnectionHandle>> handleToIDMap;

public:
    SessionManager() = default;
    ~SessionManager() = default;

    // Add a new client connexion, generate an ID, and returns the ID
    int addNewSession(ConnectionHandle hdl);

    // Remove a session
    void removeSessionByHandle(ConnectionHandle hdl);

    // Return a session
    Session* getSession(int clientID);
};
