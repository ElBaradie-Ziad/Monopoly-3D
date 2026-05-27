#include "ConnexionPlayer1Test.hpp"
#include "Player1Context.hpp"
#include "Code.hpp"
#include <iostream>
#include <thread>
#include <chrono>

static void setupConn1() {
    Player1Context::c = std::make_unique<ws_client>();
    auto& ctx = Player1Context::c;
    ctx->init_asio();
    ctx->clear_access_channels(websocketpp::log::alevel::all);

    ctx->set_tls_init_handler([](websocketpp::connection_hdl) {
        auto tls_ctx = std::make_shared<websocketpp::lib::asio::ssl::context>(websocketpp::lib::asio::ssl::context::tlsv12);
        tls_ctx->set_verify_mode(websocketpp::lib::asio::ssl::verify_none);
        return tls_ctx;
    });

    ctx->set_message_handler([](websocketpp::connection_hdl, ws_client::message_ptr msg) {
        try {
            json data = json::parse(msg->get_payload());
            Player1Context::messages.push_back(data);

            if (data.contains("mainID") && data["mainID"] == 0 &&
                data.contains("data") && data["data"].contains("clientID")) {
                Player1Context::id = data["data"]["clientID"].get<int>();
            }

            if (!data.contains("mainID") || data["mainID"].get<int>() != 4) {
                Player1Context::lastResponse = data;
            }
        } catch(...) {}
    });

    websocketpp::lib::error_code ec;
    auto con = ctx->get_connection("wss://localhost:10000", ec);
    ctx->connect(con);
    Player1Context::h = con->get_handle();
}

void runPlayer1ConnexionSequence() {
    setupConn1();

    // 1. Connection (Wait for ID)
    for(int i=0; i<20 && Player1Context::id == -1; i++) {
        Player1Context::c->poll(); std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    
    if (Player1Context::id == -1) {
        printf("[P1 CONNEXION] ERREUR: Impossible de se connecter au serveur.\n");
        return;
    }
    printf("[P1 CONNEXION] Connexion établie. ClientID: %d\n", Player1Context::id);

    // 2. Register
    json reg = {
        {"mainID", 1}, {"subID", 3}, {"clientID", Player1Context::id},
        {"data", { {"username", "player_test_1"}, {"password", "password123"} }}
    };
    Player1Context::c->send(Player1Context::h, reg.dump(), websocketpp::frame::opcode::text);
    
    for(int i=0; i<15; i++) {
        Player1Context::c->poll(); std::this_thread::sleep_for(std::chrono::milliseconds(50));
        if (Player1Context::lastResponse.contains("mainID") && Player1Context::lastResponse["mainID"] == 1) break;
    }
    printf("[P1 CONNEXION] Requête Register traitée.\n");

    // 3. Login
    json login = {
        {"mainID", 1}, {"subID", 1}, {"clientID", Player1Context::id},
        {"data", { {"username", "player_test_1"}, {"password", "password123"} }}
    };
    Player1Context::c->send(Player1Context::h, login.dump(), websocketpp::frame::opcode::text);
    
    for(int i=0; i<15; i++) {
        Player1Context::c->poll(); std::this_thread::sleep_for(std::chrono::milliseconds(50));
        if (Player1Context::lastResponse.contains("mainID") && Player1Context::lastResponse["mainID"] == 1) break;
    }
    printf("[P1 CONNEXION] Requête Login traitée.\n");
}
