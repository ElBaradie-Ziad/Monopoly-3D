BEGIN;

-- =========================================================
-- INDEXES SUR GAME
-- =========================================================

-- recherche rapide des parties par statut
CREATE INDEX IF NOT EXISTS idx_game_status
    ON game(status);

-- recherche des parties créées par un utilisateur
CREATE INDEX IF NOT EXISTS idx_game_creator_id
    ON game(creator_id);

-- =========================================================
-- INDEXES SUR RESULT
-- =========================================================

-- recherche rapide des résultats d'une partie
CREATE INDEX IF NOT EXISTS idx_result_game_id
    ON result(game_id);

-- recherche rapide des résultats d'un joueur
CREATE INDEX IF NOT EXISTS idx_result_user_id
    ON result(user_id);

-- =========================================================
-- INDEXES SUR USER_STATS
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_user_stats_level
    ON user_stats(level);

COMMIT;