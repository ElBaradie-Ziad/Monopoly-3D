#pragma once

#define ASIO_STANDALONE

#include <iostream>
#include <string>
#include "websocketpp/config/asio.hpp"
#include "websocketpp/server.hpp"
#include "json.hpp"
#include "ThreadSafeQueue.hpp"
#include "IObserver.hpp"
#include "SessionManager.hpp"
#include <vector>

using json = nlohmann::json;
using Server = websocketpp::server<websocketpp::config::asio_tls>;

class NetworkServer : public IObserver {
private:
    Server server;
    ThreadSafeQueue& queue;
    uint16_t port;
    SessionManager sessionManager;

    void configureOnClientConnected();
    void configureOnClientDisconnected();
    void configureOnMessage();
    void listen();

public:
    NetworkServer(ThreadSafeQueue& queue, uint16_t serverPort) 
        : queue(queue), port(serverPort) {}
    void run();
    void update(json data, std::vector<int> recipients) override;

    websocketpp::lib::shared_ptr<websocketpp::lib::asio::ssl::context> on_tls_init(websocketpp::connection_hdl hdl);
};
