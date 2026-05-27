/*
 * =========================================================
 * File: game_repository.cpp
 * Description:
 *  Implémentation du repository de la table game.
 * =========================================================
 */

#include "GameRepository.hpp"
#include "Database.hpp"

#include <pqxx/pqxx>
#include <iostream>

/*
 * =========================================================
 * Fonction utilitaire locale
 * Description :
 *  Construit un objet Game à partir d'une ligne SQL.
 * =========================================================
 */
static Game buildGameFromRow(const pqxx::row& row) {
    Game game;
    game.id = row["id"].as<int>();
    game.creator_id = row["creator_id"].as<int>();
    game.code = row["code"].as<std::string>();
    game.status = fromString(row["status"].as<std::string>());
    game.created_at = row["created_at"].c_str();

    if (row["ended_at"].is_null()) {
        game.ended_at = std::nullopt;
    } else {
        game.ended_at = std::string(row["ended_at"].c_str());
    }

    return game;
}

/*
 * =========================================================
 * Méthode : createGame
 * =========================================================
 */
int GameRepository::createGame(int creatorId, const std::string& code,
                          const std::string& status) {
    try {
        pqxx::work tx(Database::getConnection());

        pqxx::result result = tx.exec_params(
            "INSERT INTO game (creator_id, code, status) "
            "VALUES ($1, $2, $3) "
            "RETURNING id",
            creatorId, code, status
        );

        tx.commit();

        if (!result.empty()) {
            return result[0]["id"].as<int>();
        }

        return -1;
    } catch (const std::exception& e) {
        std::cerr << "[GameRepository::createGame] Erreur: "
                  << e.what() << std::endl;
        return -1;
    }
}

/*
 * =========================================================
 * Méthode : findById
 * =========================================================
 */
std::optional<Game> GameRepository::findById(int gameId) {
    try {
        pqxx::work tx(Database::getConnection());

        pqxx::result result = tx.exec_params(
            "SELECT id, creator_id, code, status, created_at, ended_at "
            "FROM game "
            "WHERE id = $1",
            gameId
        );

        if (result.empty()) {
            return std::nullopt;
        }

        return buildGameFromRow(result[0]);
    } catch (const std::exception& e) {
        std::cerr << "[GameRepository::findById] Erreur: "
                  << e.what() << std::endl;
        return std::nullopt;
    }
}

/*
 * =========================================================
 * Méthode : findByCode
 * =========================================================
 */
std::optional<Game> GameRepository::findByCode(const std::string& code) {
    try {
        pqxx::work tx(Database::getConnection());

        pqxx::result result = tx.exec_params(
            "SELECT id, creator_id, code, status, created_at, ended_at "
            "FROM game "
            "WHERE code = $1",
            code
        );

        if (result.empty()) {
            return std::nullopt;
        }

        return buildGameFromRow(result[0]);
    } catch (const std::exception& e) {
        std::cerr << "[GameRepository::findByCode] Erreur: "
                  << e.what() << std::endl;
        return std::nullopt;
    }
}

/*
 * =========================================================
 * Méthode : findByStatus
 * =========================================================
 */
std::vector<Game> GameRepository::findByStatus(const std::string& status) {
    std::vector<Game> games;

    try {
        pqxx::work tx(Database::getConnection());

        pqxx::result result = tx.exec_params(
            "SELECT id, creator_id, code, status, created_at, ended_at "
            "FROM game "
            "WHERE status = $1 "
            "ORDER BY created_at DESC",
            status
        );

        for (const auto& row : result) {
            games.push_back(buildGameFromRow(row));
        }
    } catch (const std::exception& e) {
        std::cerr << "[GameRepository::findByStatus] Erreur: "
                  << e.what() << std::endl;
    }

    return games;
}

/*
 * =========================================================
 * Méthode : findByCreatorId
 * =========================================================
 */
std::vector<Game> GameRepository::findByCreatorId(int creatorId) {
    std::vector<Game> games;

    try {
        pqxx::work tx(Database::getConnection());

        pqxx::result result = tx.exec_params(
            "SELECT id, creator_id, code, status, created_at, ended_at "
            "FROM game "
            "WHERE creator_id = $1 "
            "ORDER BY created_at DESC",
            creatorId
        );

        for (const auto& row : result) {
            games.push_back(buildGameFromRow(row));
        }
    } catch (const std::exception& e) {
        std::cerr << "[GameRepository::findByCreatorId] Erreur: "
                  << e.what() << std::endl;
    }

    return games;
}

/*
 * =========================================================
 * Méthode : updateStatus
 * =========================================================
 */
bool GameRepository::updateStatus(int gameId, const std::string& newStatus) {
    try {
        pqxx::work tx(Database::getConnection());

        pqxx::result result = tx.exec_params(
            "UPDATE game SET status = $1 WHERE id = $2",
            newStatus, gameId
        );

        tx.commit();

        return result.affected_rows() > 0;
    } catch (const std::exception& e) {
        std::cerr << "[GameRepository::updateStatus] Erreur: "
                  << e.what() << std::endl;
        return false;
    }
}

/*
 * =========================================================
 * Méthode : setEndedAtNow
 * =========================================================
 */
bool GameRepository::setEndedAtNow(int gameId) {
    try {
        pqxx::work tx(Database::getConnection());

        pqxx::result result = tx.exec_params(
            "UPDATE game "
            "SET ended_at = NOW() "
            "WHERE id = $1",
            gameId
        );

        tx.commit();

        return result.affected_rows() > 0;
    } catch (const std::exception& e) {
        std::cerr << "[GameRepository::setEndedAtNow] Erreur: "
                  << e.what() << std::endl;
        return false;
    }
}

/*
 * =========================================================
 * Méthode : exists
 * =========================================================
 */
bool GameRepository::exists(int gameId) {
    try {
        pqxx::work tx(Database::getConnection());

        pqxx::result result = tx.exec_params(
            "SELECT 1 FROM game WHERE id = $1",
            gameId
        );

        return !result.empty();
    } catch (const std::exception& e) {
        std::cerr << "[GameRepository::exists] Erreur: "
                  << e.what() << std::endl;
        return false;
    }
}

/*
 * =========================================================
 * Méthode : isJoinable
 * =========================================================
 */
bool GameRepository::isJoinable(int gameId) {
    try {
        pqxx::work tx(Database::getConnection());

        pqxx::result result = tx.exec_params(
            "SELECT 1 FROM game WHERE id = $1 AND status = 'LOBBY'",
            gameId
        );

        return !result.empty();
    } catch (const std::exception& e) {
        std::cerr << "[GameRepository::isJoinable] Erreur: "
                  << e.what() << std::endl;
        return false;
    }
}

/*
 * =========================================================
 * Méthode : deleteGame
 * =========================================================
 */
bool GameRepository::deleteGame(int gameId) {
    try {
        pqxx::work tx(Database::getConnection());

        pqxx::result result = tx.exec_params(
            "DELETE FROM game WHERE id = $1",
            gameId
        );

        tx.commit();

        return result.affected_rows() > 0;
    } catch (const std::exception& e) {
        std::cerr << "[GameRepository::deleteGame] Erreur: "
                  << e.what() << std::endl;
        return false;
    }
}