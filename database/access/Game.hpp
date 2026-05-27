#ifndef GAME_HPP
#define GAME_HPP

#include <string>
#include <optional>
#include <stdexcept>

/*
 * =========================================================
 * Enum : GameStatus
 * =========================================================
 */
enum class GameStatus {
    IN_LOBBY,
    IN_GAME,
    FINISHED
};

/*
 * =========================================================
 * Conversion enum → string
 * =========================================================
 */
inline std::string toString(GameStatus status) {
    switch (status) {
        case GameStatus::IN_LOBBY: return "IN_LOBBY";
        case GameStatus::IN_GAME: return "IN_GAME";
        case GameStatus::FINISHED: return "FINISHED";
    }
    return "IN_LOBBY"; // fallback
}

/*
 * =========================================================
 * Conversion string → enum
 * =========================================================
 */
inline GameStatus fromString(const std::string& status) {
    if (status == "IN_LOBBY") return GameStatus::IN_LOBBY;
    if (status == "IN_GAME") return GameStatus::IN_GAME;
    if (status == "FINISHED") return GameStatus::FINISHED;
    throw std::runtime_error("Invalid game status");
}

/*
 * =========================================================
 * Struct : Game
 * =========================================================
 */
struct Game {
    int id;
    int creator_id;
    std::string code;
    GameStatus status; 
    std::string created_at;
    std::optional<std::string> ended_at;
};

#endif
