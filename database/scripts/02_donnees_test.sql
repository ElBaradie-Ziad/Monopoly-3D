BEGIN;

-- =========================================================
-- USERS
-- =========================================================
INSERT INTO app_user (user_name, password_hash) VALUES
('alice', 'hash_alice'),
('bob', 'hash_bob'),
('charlie', 'hash_charlie'),
('diana', 'hash_diana'),
('eric', 'hash_eric')
ON CONFLICT (user_name) DO NOTHING;

-- =========================================================
-- GAMES
-- =========================================================
INSERT INTO game (code, status, creator_id, ended_at)
VALUES
(
    'GAME001',
    'FINISHED',
    (SELECT id FROM app_user WHERE user_name = 'alice'),
    NOW()
),
(
    'GAME002',
    'IN_GAME',
    (SELECT id FROM app_user WHERE user_name = 'bob'),
    NULL
)
ON CONFLICT (code) DO NOTHING;

-- =========================================================
-- RESULTS (uniquement pour GAME001 car terminée)
-- =========================================================
INSERT INTO result (game_id, user_id, rank, final_amount, result_status)
VALUES
(
    (SELECT id FROM game WHERE code = 'GAME001'),
    (SELECT id FROM app_user WHERE user_name = 'alice'),
    1,
    1500,
    'WIN'
),
(
    (SELECT id FROM game WHERE code = 'GAME001'),
    (SELECT id FROM app_user WHERE user_name = 'bob'),
    2,
    1100,
    'LOSE'
),
(
    (SELECT id FROM game WHERE code = 'GAME001'),
    (SELECT id FROM app_user WHERE user_name = 'charlie'),
    3,
    700,
    'LOSE'
),
(
    (SELECT id FROM game WHERE code = 'GAME001'),
    (SELECT id FROM app_user WHERE user_name = 'diana'),
    4,
    0,
    'BANKRUPT'
)
ON CONFLICT (game_id, user_id) DO NOTHING;

-- =========================================================
-- USER_STATS
-- =========================================================
INSERT INTO user_stats (user_id, games_played, games_won, level, last_game_at)
VALUES
(
    (SELECT id FROM app_user WHERE user_name = 'alice'),
    1,
    1,
    2,
    NOW()
),
(
    (SELECT id FROM app_user WHERE user_name = 'bob'),
    1,
    0,
    1,
    NOW()
),
(
    (SELECT id FROM app_user WHERE user_name = 'charlie'),
    1,
    0,
    1,
    NOW()
),
(
    (SELECT id FROM app_user WHERE user_name = 'diana'),
    1,
    0,
    1,
    NOW()
),
(
    (SELECT id FROM app_user WHERE user_name = 'eric'),
    0,
    0,
    1,
    NULL
)
ON CONFLICT (user_id) DO NOTHING;

COMMIT;