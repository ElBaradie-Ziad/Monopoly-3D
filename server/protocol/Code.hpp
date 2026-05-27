#pragma once

namespace Codes {

    // PlayerClass
    enum PlayerClass {
        STANDARD = 0,
        THIEF = 1,
        LUCKY = 2,
        GREEDY = 3
    };

    // MainID
    enum MainID {
        NONE = 0,
        AUTHENTIFICATION = 1,
        LOBBY = 2,
        GAME = 3,
        SERVER_PUSH = 4
    };

    // SubID
    namespace SubID {
        // Authentification
        namespace Auth {
            enum {
                NONE = 0,
                LOGIN = 1,
                LOGOUT = 2,
                REGISTER = 3
            };
        }
        
        // Lobby
        namespace Lobby {
            enum {
                NONE = 0,
                CREATE_LOBBY = 1,
                LEAVE_LOBBY = 2,
                JOIN_LOBBY = 3,
                READY = 4,
                START_GAME = 5
            };
        }

        // Game
        namespace Game {
            enum {
                NONE = 0,
                DICE_ROLLED = 1,
                GOT_OUT_OF_JAIL = 2,
                USE_CARD = 3,
                PROPERTY_BOUGHT = 4,
                HOUSE_BUILT = 5,
                END_TURN = 6,
                READY_NEXT_TURN = 7
            };
        }

        // Server Push
        namespace Server_Push {
            enum {
                NONE = 0,
                SNAPSHOT = 1,
                EVENT_TYPE = 2
            };
        }
    }

    // EventType
    namespace EventType {
        enum {
            NONE = 0,
            LOBBY_PLAYER_JOINED = 1,
            LOBBY_PLAYER_LEFT = 2,
            GAME_STARTED = 3,
            TURN_CHANGED = 4,
            DICE_ROLLED = 5,
            PROPERTY_BOUGHT = 6,
            HOUSE_BUILT = 7,
            GOT_OUT_OF_JAIL = 8,
            USE_CARD = 9,
            END_TURN = 10,
            GAME_ENDED = 11,
            ET_READY = 12
        };
    }

    // Error Code
    enum ErrorCode {
        UNKNOWN_ERROR = 0,
        BAD_JSON = 1,
        LOBBY_NOT_FOUND = 2,
        LOBBY_NOT_CREATE = 3,
        IMPOSSIBLE_TO_JOIN = 4,
        IMPOSSIBLE_TO_LEAVE = 5,
        IMPOSSIBLE_TO_BE_READY = 6,
        IMPOSSIBLE_TO_LAUNCH = 7,
        CANNOT_BUY_HOUSE = 8,
        CANNOT_BUY_PROPERTY = 9,
        CANNOT_END_TURN = 10,
        CANNOT_GET_OUT_JAIL = 11,
        CANNOT_READY_NEXT_TURN = 12,
        CANNOT_ROLL_DICE = 13,
        CANNOT_USE_CARD = 14,
        USERNAME_TAKEN = 15,
        AUTH_INVALID = 16,
        NO_ERROR = 17
    };
    // Error Message Array
    static constexpr const char* ErrorMessage[] = {
        "An unknown error occurred.",
        "The sent JSON format is invalid or corrupted.",
        "Lobby not found.",
        "Failed to create the lobby.",
        "Unable to join the lobby.",
        "Unable to leave the lobby.",
        "Failed to update ready status.",
        "Unable to launch the game.",
        "Unable to buy a house.",
        "Unable to buy the property.",
        "Unable to end the turn.",
        "Unable to get out of jail.",
        "Unable to mark as ready for the next turn.",
        "Unable to roll the dice.",
        "Unable to use the card.",
        "The username is already taken.",
        "Invalid authentication credentials."
    };
}
