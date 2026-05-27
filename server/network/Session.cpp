#include "Session.hpp"

Session::Session(ConnectionHandle hdl) : hdl(hdl) {}

void Session::send(Server& server, json data) {
    // Convert the JSON object into a string
    std::string payload = data.dump();

    // error code
    websocketpp::lib::error_code ec;

    // send the message
    server.send(hdl, payload, websocketpp::frame::opcode::text, ec);

    if (ec) {
        std::cout << "send a échoué" << ec.message() << '\n';
    }
}
