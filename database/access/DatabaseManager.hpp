#pragma once

#include <pqxx/pqxx>
#include <optional>
#include <vector>
#include <string>

#include "User.hpp"
#include "Game.hpp"

/*
 * =========================================================
 * Classe : DatabaseManager
 * Description :
 *  Centralise :
 *   - la connexion PostgreSQL
 *   - les opérations liées aux utilisateurs
 *   - les opérations liées aux parties
 *
 *  NOTE :
 *   Cette classe agit comme un repository global.
 * =========================================================
 */
class DatabaseManager {
public:
    // =========================
    // Connexion
    // =========================
    static pqxx::connection& getConnection();

    // =========================
    // User
    // =========================

    // Recherche par ID
    static std::optional<User> findUserById(int id);

    // Recherche par username
    static std::optional<User> findUserByUsername(const std::string& username);

    // Login (version simplifiée avec hash)
    static std::optional<User> login(const std::string& username,
                                     const std::string& passwordHash);

    // Création utilisateur
    static bool createUser(const std::string& username,
                           const std::string& passwordHash);

    // Création + retour ID
    static int createUserAndReturnId(const std::string& username,
                                     const std::string& passwordHash);

    // Mise à jour last_login
    static bool updateLastLogin(int userId);

    // =========================
    // Game
    // =========================

    // Création d'une partie
    static int createGame(int creatorId, const std::string& code,
                          GameStatus status = GameStatus::IN_LOBBY);

    // Recherche
    static std::optional<Game> findGameById(int gameId);
    static std::optional<Game> findGameByCode(const std::string& code);

    // Listes
    static std::vector<Game> findGamesByStatus(GameStatus status);
    static std::vector<Game> findGamesByCreatorId(int creatorId);

    // Update
    static bool updateGameStatus(int gameId, GameStatus newStatus);
    static bool setGameEndedAtNow(int gameId);

    // Vérifications
    static bool gameExists(int gameId);
    static bool isGameJoinable(int gameId);

    // Suppression
    static bool deleteGame(int gameId);

private:
    DatabaseManager() = default;
};
