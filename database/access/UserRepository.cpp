/*
 * =========================================================
 * File: user_repository.cpp
 * Description:
 *  Implémentation du repository utilisateur.
 *
 *  Ce fichier contient les requêtes SQL permettant
 *  d'interagir avec la table app_user.
 * =========================================================
 */

#include "UserRepository.hpp"
#include "Database.hpp"

#include <pqxx/pqxx>
#include <iostream>

/*
 * =========================================================
 * Méthode : findById
 * Description :
 *  Recherche un utilisateur à partir de son ID.
 * =========================================================
 */
std::optional<User> UserRepository::findById(int id) {
    try {
        pqxx::work tx(Database::getConnection());

        pqxx::result result = tx.exec_params(
            "SELECT id, user_name, password_hash, created_at, last_login "
            "FROM app_user WHERE id = $1",
            id
        );

        if (result.empty()) {
            return std::nullopt;
        }

        User user;
        user.id = result[0]["id"].as<int>();
        user.user_name = result[0]["user_name"].as<std::string>();
        user.password_hash = result[0]["password_hash"].as<std::string>();
        user.created_at = result[0]["created_at"].c_str();

        if (result[0]["last_login"].is_null()) {
            user.last_login = std::nullopt;
        } else {
            user.last_login = result[0]["last_login"].c_str();
        }

        return user;

    } catch (const std::exception& e) {
        std::cerr << "[UserRepository::findById] Erreur: "
                  << e.what() << std::endl;
        return std::nullopt;
    }
}

/*
 * =========================================================
 * Méthode : login
 * Description :
 *  Vérifie si un utilisateur existe avec ce pseudo
 *  et ce mot de passe hashé.
 *
 *  Retourne l'utilisateur si les identifiants sont corrects,
 *  sinon retourne std::nullopt.
 * =========================================================
 */
std::optional<User> UserRepository::login(const std::string& username,
                                          const std::string& passwordHash) {
    try {
        pqxx::work tx(Database::getConnection());

        pqxx::result result = tx.exec_params(
            "SELECT id, user_name, password_hash, created_at, last_login "
            "FROM app_user "
            "WHERE user_name = $1 AND password_hash = $2",
            username, passwordHash
        );

        if (result.empty()) {
            return std::nullopt;
        }

        User user;
        user.id = result[0]["id"].as<int>();
        user.user_name = result[0]["user_name"].as<std::string>();
        user.password_hash = result[0]["password_hash"].as<std::string>();
        user.created_at = result[0]["created_at"].c_str();

        if (result[0]["last_login"].is_null()) {
            user.last_login = std::nullopt;
        } else {
            user.last_login = result[0]["last_login"].c_str();
        }

        return user;

    } catch (const std::exception& e) {
        std::cerr << "[UserRepository::login] Erreur: "
                  << e.what() << std::endl;
        return std::nullopt;
    }
}


/*
 * =========================================================
 * Méthode : findByUsername
 * Description :
 *  Recherche un utilisateur à partir de son pseudo.
 * =========================================================
 */
std::optional<User> UserRepository::findByUsername(const std::string& username) {
    try {
        pqxx::work tx(Database::getConnection());

        pqxx::result result = tx.exec_params(
            "SELECT id, user_name, password_hash, created_at, last_login "
            "FROM app_user WHERE user_name = $1",
            username
        );

        if (result.empty()) {
            return std::nullopt;
        }

        User user;
        user.id = result[0]["id"].as<int>();
        user.user_name = result[0]["user_name"].as<std::string>();
        user.password_hash = result[0]["password_hash"].as<std::string>();
        user.created_at = result[0]["created_at"].c_str();

        if (result[0]["last_login"].is_null()) {
            user.last_login = std::nullopt;
        } else {
            user.last_login = result[0]["last_login"].c_str();
        }

        return user;

    } catch (const std::exception& e) {
        std::cerr << "[UserRepository::findByUsername] Erreur: "
                  << e.what() << std::endl;
        return std::nullopt;
    }
}

/*
 * =========================================================
 * Méthode : createUser
 * Description :
 *  Insère un nouvel utilisateur dans la base.
 * =========================================================
 */
bool UserRepository::createUser(const std::string& username,
                                const std::string& passwordHash) {
    try {
        pqxx::work tx(Database::getConnection());

        pqxx::result result = tx.exec_params(
            "INSERT INTO app_user (user_name, password_hash) "
            "VALUES ($1, $2) "
            "ON CONFLICT (user_name) DO NOTHING "
            "RETURNING id",
            username, passwordHash
        );

        tx.commit();

        return !result.empty();

    } catch (const std::exception& e) {
        std::cerr << "[UserRepository::createUser] Erreur: "
                  << e.what() << std::endl;
        return false;
    }
}

/*
 * =========================================================
 * Méthode : createUserAndReturnId
 * Description :
 *  Crée un utilisateur et retourne son ID généré.
 * =========================================================
 */
int UserRepository::createUserAndReturnId(const std::string& username,
                                          const std::string& passwordHash) {
    try {
        pqxx::work tx(Database::getConnection());

        pqxx::result result = tx.exec_params(
            "INSERT INTO app_user (user_name, password_hash) "
            "VALUES ($1, $2) "
            "ON CONFLICT (user_name) DO NOTHING "
            "RETURNING id",
            username, passwordHash
        );

        tx.commit();

        if (result.empty()) {
            return -1; // pseudo déjà pris
        }

        return result[0]["id"].as<int>();

    } catch (const std::exception& e) {
        std::cerr << "[UserRepository::createUserAndReturnId] Erreur: "
                  << e.what() << std::endl;
        return -1;
    }
}

/*
 * =========================================================
 * Méthode : updateLastLogin
 * Description :
 *  Met à jour le champ last_login avec la date actuelle.
 * =========================================================
 */
bool UserRepository::updateLastLogin(int userId) {
    try {
        pqxx::work tx(Database::getConnection());

        pqxx::result result = tx.exec_params(
            "UPDATE app_user "
            "SET last_login = NOW() "
            "WHERE id = $1",
            userId
        );

        tx.commit();

        return result.affected_rows() > 0;

    } catch (const std::exception& e) {
        std::cerr << "[UserRepository::updateLastLogin] Erreur: "
                  << e.what() << std::endl;
        return false;
    }
}
