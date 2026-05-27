#include "DatabaseManager.hpp"

#include <stdexcept>
#include <iostream>
#include <cstdlib>

// =========================================================
// Helpers
// =========================================================

static User buildUserFromRow(const pqxx::row& row) {
    User user;
    user.id = row["id"].as<int>();
    user.user_name = row["user_name"].as<std::string>();
    user.password_hash = row["password_hash"].as<std::string>();
    user.created_at = row["created_at"].as<std::string>();

    if (row["last_login"].is_null()) {
        user.last_login = std::nullopt;
    } else {
        user.last_login = row["last_login"].as<std::string>();
    }

    return user;
}

static Game buildGameFromRow(const pqxx::row& row) {
    Game game;
    game.id = row["id"].as<int>();
    game.creator_id = row["creator_id"].as<int>();
    game.code = row["code"].as<std::string>();
    game.status = fromString(row["status"].as<std::string>());
    game.created_at = row["created_at"].as<std::string>();

    if (row["ended_at"].is_null()) {
        game.ended_at = std::nullopt;
    } else {
        game.ended_at = row["ended_at"].as<std::string>();
    }

    return game;
}

// =========================================================
// Connexion
// =========================================================

pqxx::connection& DatabaseManager::getConnection() {
    const char* env_host = std::getenv("DB_HOST");
    std::string host = env_host ? env_host : "localhost";

    const char* env_port = std::getenv("DB_PORT");
    std::string port = env_port ? env_port : "5432";

    std::string conn_str = "dbname=monopoly3d user=monopoly password=monopoly_l3S6 host=" + host + " port=" + port;
    std::cout << "[DB] Connecting with: " << conn_str << std::endl;

    // Utiliser "new" pour éviter le crash double-free d'ASAN à la fermeture
    static pqxx::connection* conn = new pqxx::connection(conn_str);
    return *conn;
}

// =========================================================
// USER
// =========================================================

std::optional<User> DatabaseManager::findUserById(int id) {
    try {
        pqxx::read_transaction tx(getConnection());

        auto result = tx.exec_params(
            "SELECT id, user_name, password_hash, created_at, last_login "
            "FROM app_user WHERE id = $1",
            id
        );

        if (result.empty()) return std::nullopt;
        return buildUserFromRow(result[0]);

    } catch (const std::exception& e) {
        std::cerr << "[findUserById] " << e.what() << std::endl;
        return std::nullopt;
    }
}

std::optional<User> DatabaseManager::findUserByUsername(const std::string& username) {
    try {
        pqxx::read_transaction tx(getConnection());

        auto result = tx.exec_params(
            "SELECT id, user_name, password_hash, created_at, last_login "
            "FROM app_user WHERE user_name = $1",
            username
        );

        if (result.empty()) return std::nullopt;
        return buildUserFromRow(result[0]);

    } catch (const std::exception& e) {
        std::cerr << "[findUserByUsername] " << e.what() << std::endl;
        return std::nullopt;
    }
}

std::optional<User> DatabaseManager::login(const std::string& username,
                                           const std::string& passwordHash) {
    try {
        pqxx::read_transaction tx(getConnection());

        auto result = tx.exec_params(
            "SELECT id, user_name, password_hash, created_at, last_login "
            "FROM app_user WHERE user_name = $1 AND password_hash = $2",
            username, passwordHash
        );

        if (result.empty()) return std::nullopt;
        return buildUserFromRow(result[0]);

    } catch (const std::exception& e) {
        std::cerr << "[login] " << e.what() << std::endl;
        return std::nullopt;
    }
}

bool DatabaseManager::createUser(const std::string& username,
                                 const std::string& passwordHash) {
    try {
        pqxx::work tx(getConnection());

        auto result = tx.exec_params(
            "INSERT INTO app_user (user_name, password_hash) "
            "VALUES ($1, $2) "
            "ON CONFLICT (user_name) DO NOTHING "
            "RETURNING id",
            username, passwordHash
        );

        tx.commit();
        return !result.empty();

    } catch (const std::exception& e) {
        std::cerr << "[createUser] " << e.what() << std::endl;
        return false;
    }
}

int DatabaseManager::createUserAndReturnId(const std::string& username,
                                           const std::string& passwordHash) {
    try {
        pqxx::work tx(getConnection());

        auto result = tx.exec_params(
            "INSERT INTO app_user (user_name, password_hash) "
            "VALUES ($1, $2) "
            "ON CONFLICT (user_name) DO NOTHING "
            "RETURNING id",
            username, passwordHash
        );

        tx.commit();
        if (result.empty()) return -1;
        return result[0]["id"].as<int>();

    } catch (const std::exception& e) {
        std::cerr << "[createUserAndReturnId] " << e.what() << std::endl;
        return -1;
    }
}

bool DatabaseManager::updateLastLogin(int userId) {
    try {
        pqxx::work tx(getConnection());

        auto result = tx.exec_params(
            "UPDATE app_user SET last_login = NOW() WHERE id = $1",
            userId
        );

        tx.commit();
        return result.affected_rows() > 0;

    } catch (const std::exception& e) {
        std::cerr << "[updateLastLogin] " << e.what() << std::endl;
        return false;
    }
}

// =========================================================
// GAME
// =========================================================

int DatabaseManager::createGame(int creatorId, const std::string& code,
                                GameStatus status) {
    try {
        pqxx::work tx(getConnection());

        auto result = tx.exec_params(
            "INSERT INTO game (creator_id, code, status) "
            "VALUES ($1, $2, $3) RETURNING id",
            creatorId, code, toString(status)
        );

        tx.commit();
        if (result.empty()) return -1;
        return result[0]["id"].as<int>();

    } catch (const std::exception& e) {
        std::cerr << "[createGame] " << e.what() << std::endl;
        return -1;
    }
}

std::optional<Game> DatabaseManager::findGameById(int gameId) {
    try {
        pqxx::read_transaction tx(getConnection());

        auto result = tx.exec_params(
            "SELECT id, creator_id, code, status, created_at, ended_at "
            "FROM game WHERE id = $1",
            gameId
        );

        if (result.empty()) return std::nullopt;
        return buildGameFromRow(result[0]);

    } catch (const std::exception& e) {
        std::cerr << "[findGameById] " << e.what() << std::endl;
        return std::nullopt;
    }
}

std::optional<Game> DatabaseManager::findGameByCode(const std::string& code) {
    try {
        pqxx::read_transaction tx(getConnection());

        auto result = tx.exec_params(
            "SELECT id, creator_id, code, status, created_at, ended_at "
            "FROM game WHERE code = $1",
            code
        );

        if (result.empty()) return std::nullopt;
        return buildGameFromRow(result[0]);

    } catch (const std::exception& e) {
        std::cerr << "[findGameByCode] " << e.what() << std::endl;
        return std::nullopt;
    }
}

std::vector<Game> DatabaseManager::findGamesByStatus(GameStatus status) {
    std::vector<Game> games;

    try {
        pqxx::read_transaction tx(getConnection());

        auto result = tx.exec_params(
            "SELECT id, creator_id, code, status, created_at, ended_at "
            "FROM game WHERE status = $1 ORDER BY created_at DESC",
            toString(status)
        );

        for (const auto& row : result) {
            games.push_back(buildGameFromRow(row));
        }

    } catch (const std::exception& e) {
        std::cerr << "[findGamesByStatus] " << e.what() << std::endl;
    }

    return games;
}

std::vector<Game> DatabaseManager::findGamesByCreatorId(int creatorId) {
    std::vector<Game> games;

    try {
        pqxx::read_transaction tx(getConnection());

        auto result = tx.exec_params(
            "SELECT id, creator_id, code, status, created_at, ended_at "
            "FROM game WHERE creator_id = $1 ORDER BY created_at DESC",
            creatorId
        );

        for (const auto& row : result) {
            games.push_back(buildGameFromRow(row));
        }

    } catch (const std::exception& e) {
        std::cerr << "[findGamesByCreatorId] " << e.what() << std::endl;
    }

    return games;
}

bool DatabaseManager::updateGameStatus(int gameId, GameStatus newStatus) {
    try {
        pqxx::work tx(getConnection());

        auto result = tx.exec_params(
            "UPDATE game SET status = $1 WHERE id = $2",
            toString(newStatus), gameId
        );

        tx.commit();
        return result.affected_rows() > 0;

    } catch (const std::exception& e) {
        std::cerr << "[updateGameStatus] " << e.what() << std::endl;
        return false;
    }
}

bool DatabaseManager::setGameEndedAtNow(int gameId) {
    try {
        pqxx::work tx(getConnection());

        auto result = tx.exec_params(
            "UPDATE game SET ended_at = NOW() WHERE id = $1",
            gameId
        );

        tx.commit();
        return result.affected_rows() > 0;

    } catch (const std::exception& e) {
        std::cerr << "[setGameEndedAtNow] " << e.what() << std::endl;
        return false;
    }
}

bool DatabaseManager::gameExists(int gameId) {
    try {
        pqxx::read_transaction tx(getConnection());

        auto result = tx.exec_params(
            "SELECT 1 FROM game WHERE id = $1",
            gameId
        );

        return !result.empty();

    } catch (const std::exception& e) {
        std::cerr << "[gameExists] " << e.what() << std::endl;
        return false;
    }
}

bool DatabaseManager::isGameJoinable(int gameId) {
    try {
        pqxx::read_transaction tx(getConnection());

        auto result = tx.exec_params(
            "SELECT 1 FROM game WHERE id = $1 AND status = 'LOBBY'",
            gameId
        );

        return !result.empty();

    } catch (const std::exception& e) {
        std::cerr << "[isGameJoinable] " << e.what() << std::endl;
        return false;
    }
}

bool DatabaseManager::deleteGame(int gameId) {
    try {
        pqxx::work tx(getConnection());

        auto result = tx.exec_params(
            "DELETE FROM game WHERE id = $1",
            gameId
        );

        tx.commit();
        return result.affected_rows() > 0;

    } catch (const std::exception& e) {
        std::cerr << "[deleteGame] " << e.what() << std::endl;
        return false;
    }
}
