/*
 * =========================================================
 * File: db_connection.hpp
 * Description:
 *  Gestion de la connexion PostgreSQL.
 *  Cette classe fournit une connexion unique réutilisée
 *  par tous les repositories.
 * =========================================================
 */

#pragma once

#include <pqxx/pqxx>

class Database {
public:
    static pqxx::connection& getConnection();
};