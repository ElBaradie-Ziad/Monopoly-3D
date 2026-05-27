#pragma once
#define ASIO_STANDALONE
#include "websocketpp/config/asio.hpp"
#include "websocketpp/client.hpp"
#include "json.hpp"
#include <vector>
#include <string>
#include <memory>

using json = nlohmann::json;
typedef websocketpp::client<websocketpp::config::asio_tls> ws_client;

struct Player2Context {
    inline static std::unique_ptr<ws_client> c = nullptr;
    inline static websocketpp::connection_hdl h;
    inline static int id = -1;
    inline static std::vector<json> messages;
    inline static json lastResponse;
    inline static std::string username = "player_test_2";
    inline static std::string password = "password123";

    static json findEvent(int eventType) {
        for (auto it = messages.rbegin(); it != messages.rend(); ++it) {
            if ((*it).contains("mainID") && (*it)["mainID"].get<int>() == 4 &&
                (*it)["data"].contains("eventType") &&
                (*it)["data"]["eventType"].get<int>() == eventType)
                return *it;
        }
        return json();
    }
};
