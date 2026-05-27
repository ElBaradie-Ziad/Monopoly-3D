/*
 * =========================================================
 * File: user_repository.hpp
 * Description:
 *  Repository chargé de l'accès aux données des utilisateurs.
 *
 *  Cette classe sert d'intermédiaire entre le serveur et la
 *  table app_user de la base PostgreSQL.
 *
 *  Fonctions principales :
 *   - rechercher un utilisateur par id
 *   - rechercher un utilisateur par pseudo
 *   - créer un utilisateur
 *   - mettre à jour la dernière connexion
 * =========================================================
 */

#pragma once

#include <optional>
#include <string>
#include "User.hpp"


/*
 * =========================================================
 * Classe : UserRepository
 * Description :
 *  Fournit des méthodes statiques pour interagir avec
 *  la table app_user dans PostgreSQL.
 * =========================================================
 */
class UserRepository {
public:

    /*
     * Recherche un utilisateur par son identifiant.
     */
    static std::optional<User> findById(int id);

    /*
     * Vérifie les identifiants de connexion d'un utilisateur.
     * Retourne l'utilisateur si le pseudo et le mot de passe
     * hashé correspondent, sinon retourne std::nullopt.
     */
    static std::optional<User> login(const std::string& username,
                                     const std::string& passwordHash);

    /*
     * Recherche un utilisateur par son pseudo.
     */
    static std::optional<User> findByUsername(const std::string& username);

    /*
     * Crée un nouvel utilisateur dans la base.
     */
    static bool createUser(const std::string& username,
                           const std::string& passwordHash);

    /*
     * Crée un utilisateur et retourne son ID généré.
     */
    static int createUserAndReturnId(const std::string& username,
                                     const std::string& passwordHash);

    /*
     * Met à jour la date de dernière connexion.
     */
    static bool updateLastLogin(int userId);
};