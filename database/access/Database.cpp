#include "Database.hpp"
#include <stdexcept>
#include <cstdlib> // Nécessaire pour std::getenv
#include <string>

pqxx::connection& Database::getConnection() {
    // Si la variable DB_HOST existe on l'utilise, sinon on utilise "localhost"
    const char* env_host = std::getenv("DB_HOST");
    std::string host = env_host ? env_host : "localhost";

    std::string conn_str = 
        "dbname=monopoly3d "
        "user=monopoly "
        "password=monopoly_l3S6 "
        "host=" + host + " "
        "port=5432";

    static pqxx::connection conn(conn_str);

    if (!conn.is_open()) {
        throw std::runtime_error("Impossible d'ouvrir la connexion PostgreSQL sur " + host);
    }

    return conn;
}
