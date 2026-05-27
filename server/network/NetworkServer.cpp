#include "NetworkServer.hpp"

#include "MessageBuilder.hpp"
#include "MessageParser.hpp"
#include "Message.hpp"
#include <iostream>
#include <websocketpp/common/asio_ssl.hpp>

using ssl_context = websocketpp::lib::asio::ssl::context;
using ssl_context_ptr = websocketpp::lib::shared_ptr<ssl_context>;
using connection_hdl = websocketpp::connection_hdl;

ssl_context_ptr NetworkServer::on_tls_init(connection_hdl hdl) {
    auto ctx = websocketpp::lib::make_shared<ssl_context>(ssl_context::tlsv12);

    try {
        ctx->set_options(
            ssl_context::default_workarounds |
            ssl_context::no_sslv2 |
            ssl_context::no_sslv3 |
            ssl_context::single_dh_use
        );

        // Fallback for tests running from build/
        try {
            ctx->use_certificate_chain_file("server.crt");
            ctx->use_private_key_file("server.key", ssl_context::pem);
        } catch (...) {
            ctx->use_certificate_chain_file("../server.crt");
            ctx->use_private_key_file("../server.key", ssl_context::pem);
        }
    } catch (std::exception& e) {
        std::cerr << "Erreur critique TLS Init : " << e.what() << "\n(Avez-vous bien les fichiers server.crt et server.key ?)\n";
    }

    return ctx;
}

// HANDLERS WEBSOCKET
void NetworkServer::configureOnClientConnected() {
    server.set_open_handler([this](websocketpp::connection_hdl handler) {
        std::cout << "Client connecté (Sécurisé)\n";

        // Create a new Session
        int clientID = sessionManager.addNewSession(handler);

        // Json data
        json data = MessageBuilder::buildResponse(Codes::MainID::NONE, 0, {{"clientID", clientID}});

        // Send the ID to Client
        Session* clientSession = sessionManager.getSession(clientID);
        if (clientSession)
            clientSession->send(server, data);
    });
}

void NetworkServer::configureOnClientDisconnected() {
    server.set_close_handler([this](websocketpp::connection_hdl handler) {
        std::cout << "Client deconnecté\n";

        // Delete the session
        sessionManager.removeSessionByHandle(handler);
    });
}

void NetworkServer::configureOnMessage() {
    server.set_message_handler([this](websocketpp::connection_hdl hdl, Server::message_ptr msg) {

        try {
            // rawdata
            std::string rawdata = msg->get_payload();

            // Conversion into the class Message
            Message m = MessageParser::parse(rawdata);

            // Push the message in the queue
            queue.push(m);
        } catch (const std::exception& e ) {
            std::cerr << "Message rejeté: " << e.what() << "\n";
        }
        
    });
}

void NetworkServer::update(const json data, std::vector<int> recipients) {
    for (int clientID : recipients) {
        Session* session = sessionManager.getSession(clientID);

        if (!session) {
            std::cerr << "Session pas trouvé pour: " << clientID << "\n";
            continue;
        }

        try {
            session->send(server, data);
        } catch (const std::exception& e) {
            std::cerr << "Erreur d'envoi au client " << clientID
                      << " : " << e.what() << "\n";
        }
    }

}

void NetworkServer::listen() {
    server.set_reuse_addr(true);
    try {
        server.listen(port);
    } catch (const std::exception& e) {
        std::cerr << "\n[ERREUR RESEAU] Impossible d'ecouter sur le port " << port 
                  << " : " << e.what() << "\n=> Si vous testez, ARRETEZ LE SERVEUR DOCKER 'docker compose stop server' <=\n\n";
        throw; // We still throw to let the thread cleanly abort rather than zombieing
    }
}

void NetworkServer::run() {
    server.clear_access_channels(websocketpp::log::alevel::all);
    server.init_asio();

    server.set_tls_init_handler([this](websocketpp::connection_hdl hdl) {
        return this->on_tls_init(hdl);
    });

    configureOnClientConnected();
    configureOnClientDisconnected();   
    configureOnMessage(); 

    listen();    
    
    server.start_accept();
    std::cout << "Serveur WSS en écoute sur le port : " << port << " (TLS Activé)\n";

    server.run();
}
