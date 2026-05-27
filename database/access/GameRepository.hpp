#ifndef GAME_REPOSITORY_HPP
#define GAME_REPOSITORY_HPP

#include "Game.hpp"
#include <optional>
#include <vector>
#include <string>

/*
 * =========================================================
 * Classe : GameRepository
 * Description :
 *  Repository responsable des accès à la table game.
 *
 *  Cette classe contient uniquement les opérations liées
 *  à la persistance des parties en base de données.
 *
 *  Elle ne contient pas la logique métier
 *  (ex : vérifier si on peut lancer une partie, si elle
 *  a assez de joueurs, etc.).
 * =========================================================
 */
class GameRepository {
public:
    /*
     * =========================================================
     * Méthode : createGame
     * Description :
     *  Crée une nouvelle partie.
     *
     * Paramètres :
     *  - creatorId : id du user qui crée la partie
     *  - code      : code unique de la partie
     *  - status    : statut initial (par défaut "LOBBY")
     *
     * Retour :
     *  - id de la partie créée
     *  - -1 en cas d'erreur
     * =========================================================
     */
    static int createGame(int creatorId, const std::string& code,
                          const std::string& status = "LOBBY");

    /*
     * =========================================================
     * Méthode : findById
     * Description :
     *  Recherche une partie à partir de son id.
     *
     * Retour :
     *  - std::optional<Game> contenant la partie si trouvée
     *  - std::nullopt sinon
     * =========================================================
     */
    static std::optional<Game> findById(int gameId);

    /*
     * =========================================================
     * Méthode : findByCode
     * Description :
     *  Recherche une partie à partir de son code.
     *
     * Retour :
     *  - std::optional<Game> contenant la partie si trouvée
     *  - std::nullopt sinon
     * =========================================================
     */
    static std::optional<Game> findByCode(const std::string& code);

    /*
     * =========================================================
     * Méthode : findByStatus
     * Description :
     *  Récupère toutes les parties ayant un certain statut.
     *
     * Retour :
     *  - vecteur de parties
     * =========================================================
     */
    static std::vector<Game> findByStatus(const std::string& status);

    /*
     * =========================================================
     * Méthode : findByCreatorId
     * Description :
     *  Récupère toutes les parties créées par un utilisateur.
     *
     * Retour :
     *  - vecteur de parties
     * =========================================================
     */
    static std::vector<Game> findByCreatorId(int creatorId);

    /*
     * =========================================================
     * Méthode : updateStatus
     * Description :
     *  Met à jour le statut d'une partie.
     *
     * Retour :
     *  - true si mise à jour effectuée
     *  - false sinon
     * =========================================================
     */
    static bool updateStatus(int gameId, const std::string& newStatus);

    /*
     * =========================================================
     * Méthode : setEndedAtNow
     * Description :
     *  Met ended_at à NOW() pour la partie donnée.
     *
     * Retour :
     *  - true si mise à jour effectuée
     *  - false sinon
     * =========================================================
     */
    static bool setEndedAtNow(int gameId);

    /*
     * =========================================================
     * Méthode : exists
     * Description :
     *  Vérifie si une partie existe.
     *
     * Retour :
     *  - true si elle existe
     *  - false sinon
     * =========================================================
     */
    static bool exists(int gameId);

    /*
     * =========================================================
     * Méthode : isJoinable
     * Description :
     *  Vérifie si une partie est rejoignable.
     *
     * Ici, on considère qu'une partie est rejoignable
     * si son statut est "LOBBY".
     *
     * Retour :
     *  - true si rejoignable
     *  - false sinon
     * =========================================================
     */
    static bool isJoinable(int gameId);

    /*
     * =========================================================
     * Méthode : deleteGame
     * Description :
     *  Supprime une partie.
     *
     * Retour :
     *  - true si suppression effectuée
     *  - false sinon
     * =========================================================
     */
    static bool deleteGame(int gameId);
};

#endif
