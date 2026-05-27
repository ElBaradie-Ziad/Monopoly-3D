BEGIN;

-- =========================================================
-- RESET
-- =========================================================
DROP TABLE IF EXISTS user_stats CASCADE;
DROP TABLE IF EXISTS result CASCADE;
DROP TABLE IF EXISTS game CASCADE;
DROP TABLE IF EXISTS app_user CASCADE;

-- =========================================================
-- 1) TABLE APP_USER
-- =========================================================
CREATE TABLE app_user (
    id SERIAL PRIMARY KEY,
    user_name VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_login TIMESTAMP
);

-- =========================================================
-- 2) TABLE GAME
-- =========================================================
CREATE TABLE game (
    id SERIAL PRIMARY KEY,
    code VARCHAR(10) NOT NULL UNIQUE,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMP,
    creator_id INT NOT NULL,

    CONSTRAINT game_status_chk
        CHECK (status IN ('LOBBY', 'IN_GAME', 'FINISHED')),

    CONSTRAINT game_creator_fk
        FOREIGN KEY (creator_id)
        REFERENCES app_user(id)
        ON DELETE RESTRICT
);

-- =========================================================
-- 3) TABLE RESULT
-- =========================================================
CREATE TABLE result (
    id SERIAL PRIMARY KEY,
    game_id INT NOT NULL,
    user_id INT NOT NULL,
    rank INT NOT NULL,
    final_amount INT NOT NULL,
    result_status VARCHAR(10) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT res_game_fk
        FOREIGN KEY (game_id)
        REFERENCES game(id)
        ON DELETE CASCADE,

    CONSTRAINT res_user_fk
        FOREIGN KEY (user_id)
        REFERENCES app_user(id)
        ON DELETE CASCADE,

    CONSTRAINT res_result_status_chk
        CHECK (result_status IN ('WIN', 'LOSE', 'BANKRUPT')),

    CONSTRAINT res_rank_chk
        CHECK (rank >= 1),

    CONSTRAINT res_final_amount_chk
        CHECK (final_amount >= 0),

    CONSTRAINT uq_result_game_user
        UNIQUE (game_id, user_id)
);

-- =========================================================
-- 4) TABLE USER_STATS
-- =========================================================
CREATE TABLE user_stats (
    user_id INT PRIMARY KEY,
    games_played INT NOT NULL DEFAULT 0,
    games_won INT NOT NULL DEFAULT 0,
    level INT NOT NULL DEFAULT 1,
    last_game_at TIMESTAMP,

    CONSTRAINT us_user_fk
        FOREIGN KEY (user_id)
        REFERENCES app_user(id)
        ON DELETE CASCADE,

    CONSTRAINT us_games_played_chk
        CHECK (games_played >= 0),

    CONSTRAINT us_games_won_chk
        CHECK (games_won >= 0),

    CONSTRAINT us_level_chk
        CHECK (level >= 1),

    CONSTRAINT us_wins_le_games_chk
        CHECK (games_won <= games_played)
);

COMMIT;