#pragma once

#define ASIO_STANDALONE

#include "websocketpp/config/asio.hpp"
#include "websocketpp/server.hpp"
#include "json.hpp"

using Server = websocketpp::server<websocketpp::config::asio_tls>;
using json = nlohmann::json;
using ConnectionHandle = websocketpp::connection_hdl;

class Session {
private:
    ConnectionHandle hdl;

public:
    Session(ConnectionHandle hdl);
    ~Session() = default;

    void send(Server& server, json data);
};
