-- ==============================================================================
-- Migration: Mehrstufige Langzeit-Erfolge & Daily Quests (STORY-003)
-- ==============================================================================

-- 1. Tabelle public.user_achievements erweitern & absichern
ALTER TABLE public.user_achievements 
ADD COLUMN IF NOT EXISTS claimed_tier INT DEFAULT 1;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'user_achievements' AND policyname = 'Users can update own achievements'
    ) THEN
        CREATE POLICY "Users can update own achievements" 
        ON public.user_achievements FOR UPDATE 
        USING (auth.uid() = user_id) 
        WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

-- Migration von Alt-Erfolgen auf die neuen Stufen (Option A):
-- veteran_5 -> match_veteran Tier 1
-- veteran_10 -> match_veteran Tier 2
-- win_streak_3 -> win_streak Tier 1
-- win_streak_5 -> win_streak Tier 2
-- level_3 -> level_master Tier 1
-- level_5 -> level_master Tier 1
-- collector_2 -> deck_curator Tier 1
-- pot_king -> pot_titan Tier 1
-- grandmaster -> ai_conqueror Tier 1

UPDATE public.user_achievements SET achievement_id = 'match_veteran', claimed_tier = 2 WHERE achievement_id = 'veteran_10';
UPDATE public.user_achievements SET achievement_id = 'match_veteran', claimed_tier = 1 WHERE achievement_id = 'veteran_5'
    AND NOT EXISTS (SELECT 1 FROM public.user_achievements ua2 WHERE ua2.user_id = user_achievements.user_id AND ua2.achievement_id = 'match_veteran');
DELETE FROM public.user_achievements WHERE achievement_id = 'veteran_5';

UPDATE public.user_achievements SET achievement_id = 'win_streak', claimed_tier = 2 WHERE achievement_id = 'win_streak_5';
UPDATE public.user_achievements SET achievement_id = 'win_streak', claimed_tier = 1 WHERE achievement_id = 'win_streak_3'
    AND NOT EXISTS (SELECT 1 FROM public.user_achievements ua2 WHERE ua2.user_id = user_achievements.user_id AND ua2.achievement_id = 'win_streak');
DELETE FROM public.user_achievements WHERE achievement_id = 'win_streak_3';

UPDATE public.user_achievements SET achievement_id = 'level_master', claimed_tier = 1 WHERE achievement_id IN ('level_3', 'level_5')
    AND id IN (
        SELECT DISTINCT ON (user_id) id FROM public.user_achievements WHERE achievement_id IN ('level_3', 'level_5') ORDER BY user_id, unlocked_at ASC
    );
DELETE FROM public.user_achievements WHERE achievement_id IN ('level_3', 'level_5');

UPDATE public.user_achievements SET achievement_id = 'deck_curator', claimed_tier = 1 WHERE achievement_id = 'collector_2';
UPDATE public.user_achievements SET achievement_id = 'pot_titan', claimed_tier = 1 WHERE achievement_id = 'pot_king';
UPDATE public.user_achievements SET achievement_id = 'ai_conqueror', claimed_tier = 1 WHERE achievement_id = 'grandmaster';

-- 2. Spalten in profiles für KI-Bezwinger und Daily-Quests-Streaks ergänzen
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS expert_bot_wins INT DEFAULT 0;

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS daily_streak INT DEFAULT 0;

ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS last_daily_bonus_date DATE;

-- Initialer Abgleich: Wer den Experten-Bot schon besiegt hatte, erhält expert_bot_wins = 1
UPDATE public.profiles
SET expert_bot_wins = 1
WHERE expert_bot_wins = 0 AND id IN (
    SELECT user_id FROM public.user_achievements WHERE achievement_id = 'ai_conqueror'
);

-- 3. Tabelle public.daily_quests erstellen
CREATE TABLE IF NOT EXISTS public.daily_quests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    quest_date DATE NOT NULL DEFAULT CURRENT_DATE,
    quest_key TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('easy', 'tactics', 'hard')),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    current_val INT NOT NULL DEFAULT 0,
    target_val INT NOT NULL,
    reward_coins INT NOT NULL,
    is_claimed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, quest_date, quest_key)
);

-- RLS aktivieren & absichern
ALTER TABLE public.daily_quests ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'daily_quests' AND policyname = 'Users see own daily quests') THEN
        CREATE POLICY "Users see own daily quests" ON public.daily_quests FOR SELECT USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'daily_quests' AND policyname = 'Users can insert own daily quests') THEN
        CREATE POLICY "Users can insert own daily quests" ON public.daily_quests FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'daily_quests' AND policyname = 'Users can update own daily quests') THEN
        CREATE POLICY "Users can update own daily quests" ON public.daily_quests FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

-- 4. RPC Funktion: rpc_get_or_create_daily_quests
CREATE OR REPLACE FUNCTION public.rpc_get_or_create_daily_quests(p_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    quest_date DATE,
    quest_key TEXT,
    category TEXT,
    title TEXT,
    description TEXT,
    current_val INT,
    target_val INT,
    reward_coins INT,
    is_claimed BOOLEAN
) AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_existing_count INT;
    v_date DATE := COALESCE(p_date, CURRENT_DATE);
    v_seed_int INT;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    SELECT count(*) INTO v_existing_count
    FROM public.daily_quests dq
    WHERE dq.user_id = v_user_id AND dq.quest_date = v_date;

    IF v_existing_count = 0 THEN
        -- Deterministische Auswahl anhand von User-ID und Tagesdatum
        v_seed_int := ('x' || substr(md5(v_user_id::text || v_date::text), 1, 8))::bit(32)::int;

        -- 1. Easy Quest (30 Coins)
        IF (abs(v_seed_int) % 2) = 0 THEN
            INSERT INTO public.daily_quests (user_id, quest_date, quest_key, category, title, description, current_val, target_val, reward_coins)
            VALUES (v_user_id, v_date, 'play_matches_2', 'easy', 'Warm-up', 'Spiele 2 Matches.', 0, 2, 30);
        ELSE
            INSERT INTO public.daily_quests (user_id, quest_date, quest_key, category, title, description, current_val, target_val, reward_coins)
            VALUES (v_user_id, v_date, 'win_match_1', 'easy', 'Tagessieg', 'Gewinne 1 Match.', 0, 1, 30);
        END IF;

        -- 2. Tactics Quest (50 Coins)
        IF (abs(v_seed_int / 2) % 2) = 0 THEN
            INSERT INTO public.daily_quests (user_id, quest_date, quest_key, category, title, description, current_val, target_val, reward_coins)
            VALUES (v_user_id, v_date, 'win_speed_tricks_3', 'tactics', 'Geschwindigkeitsrausch', 'Gewinne 3 Stiche mit Höchstgeschwindigkeit.', 0, 3, 50);
        ELSE
            INSERT INTO public.daily_quests (user_id, quest_date, quest_key, category, title, description, current_val, target_val, reward_coins)
            VALUES (v_user_id, v_date, 'win_pot_trick', 'tactics', 'Pott-Räuber', 'Gewinne einen Pott mit mindestens 4 Karten.', 0, 1, 50);
        END IF;

        -- 3. Hard Quest (75 Coins)
        IF (abs(v_seed_int / 4) % 2) = 0 THEN
            INSERT INTO public.daily_quests (user_id, quest_date, quest_key, category, title, description, current_val, target_val, reward_coins)
            VALUES (v_user_id, v_date, 'win_expert_bot', 'hard', 'Meister-Duell', 'Besiege den Experten-Bot oder gewinne ein Multiplayer-Spiel.', 0, 1, 75);
        ELSE
            INSERT INTO public.daily_quests (user_id, quest_date, quest_key, category, title, description, current_val, target_val, reward_coins)
            VALUES (v_user_id, v_date, 'win_streak_2', 'hard', 'Doppelschlag', 'Erziele eine 2er Siegesserie.', 0, 2, 75);
        END IF;
    END IF;

    RETURN QUERY
    SELECT dq.id, dq.user_id, dq.quest_date, dq.quest_key, dq.category, dq.title, dq.description, dq.current_val, dq.target_val, dq.reward_coins, dq.is_claimed
    FROM public.daily_quests dq
    WHERE dq.user_id = v_user_id AND dq.quest_date = v_date
    ORDER BY 
        CASE dq.category 
            WHEN 'easy' THEN 1 
            WHEN 'tactics' THEN 2 
            WHEN 'hard' THEN 3 
            ELSE 4 
        END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. RPC Funktion: rpc_claim_daily_quest
CREATE OR REPLACE FUNCTION public.rpc_claim_daily_quest(p_quest_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_reward INT;
    v_current INT;
    v_target INT;
    v_claimed BOOLEAN;
    v_new_coins INT;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    SELECT reward_coins, current_val, target_val, is_claimed
    INTO v_reward, v_current, v_target, v_claimed
    FROM public.daily_quests
    WHERE id = p_quest_id AND user_id = v_user_id;

    IF v_reward IS NULL THEN
        RAISE EXCEPTION 'Tagesmission nicht gefunden';
    END IF;

    IF v_claimed THEN
        RAISE EXCEPTION 'Mission wurde bereits eingelöst';
    END IF;

    IF v_current < v_target THEN
        RAISE EXCEPTION 'Missionsziel noch nicht erreicht (% / %)', v_current, v_target;
    END IF;

    UPDATE public.daily_quests
    SET is_claimed = true
    WHERE id = p_quest_id;

    UPDATE public.profiles
    SET coins = coins + v_reward,
        updated_at = now()
    WHERE id = v_user_id
    RETURNING coins INTO v_new_coins;

    RETURN jsonb_build_object(
        'success', true,
        'coins', v_new_coins,
        'reward', v_reward
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. RPC Funktion: rpc_claim_daily_bonus (+100 Coins & Streak +1)
CREATE OR REPLACE FUNCTION public.rpc_claim_daily_bonus(p_date DATE DEFAULT CURRENT_DATE)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_date DATE := COALESCE(p_date, CURRENT_DATE);
    v_unclaimed_count INT;
    v_total_quests INT;
    v_last_bonus_date DATE;
    v_current_streak INT;
    v_new_streak INT;
    v_new_coins INT;
    v_bonus_coins INT := 100;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    SELECT last_daily_bonus_date, daily_streak INTO v_last_bonus_date, v_current_streak
    FROM public.profiles
    WHERE id = v_user_id;

    IF v_last_bonus_date = v_date THEN
        RAISE EXCEPTION 'Tages-Bonus wurde heute bereits abgeholt';
    END IF;

    SELECT count(*), count(*) FILTER (WHERE is_claimed = false)
    INTO v_total_quests, v_unclaimed_count
    FROM public.daily_quests
    WHERE user_id = v_user_id AND quest_date = v_date;

    IF v_total_quests < 3 OR v_unclaimed_count > 0 THEN
        RAISE EXCEPTION 'Es müssen alle 3 Tagesmissionen abgeschlossen und abgeholt sein';
    END IF;

    IF v_last_bonus_date = (v_date - INTERVAL '1 day')::date THEN
        v_new_streak := COALESCE(v_current_streak, 0) + 1;
    ELSE
        v_new_streak := 1;
    END IF;

    UPDATE public.profiles
    SET 
        coins = coins + v_bonus_coins,
        daily_streak = v_new_streak,
        last_daily_bonus_date = v_date,
        updated_at = now()
    WHERE id = v_user_id
    RETURNING coins INTO v_new_coins;

    RETURN jsonb_build_object(
        'success', true,
        'coins', v_new_coins,
        'bonus_coins', v_bonus_coins,
        'daily_streak', v_new_streak
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Gast-Merge Funktion aktualisieren (Daily Quests & Streaks übertragen)
CREATE OR REPLACE FUNCTION public.rpc_merge_guest_data(p_guest_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_new_user_id UUID := auth.uid();
    v_guest_coins INT;
    v_guest_xp INT;
    v_guest_expert_wins INT;
    v_guest_streak INT;
    v_guest_bonus_date DATE;
    v_new_coins INT;
    v_new_xp INT;
    v_new_level INT;
BEGIN
    IF v_new_user_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    IF v_new_user_id = p_guest_id THEN
        RETURN jsonb_build_object('success', true, 'message', 'IDs sind identisch, kein Merge nötig');
    END IF;

    -- 1. Gast-Profil Daten holen
    SELECT coins, xp, COALESCE(expert_bot_wins, 0), COALESCE(daily_streak, 0), last_daily_bonus_date
    INTO v_guest_coins, v_guest_xp, v_guest_expert_wins, v_guest_streak, v_guest_bonus_date
    FROM public.profiles
    WHERE id = p_guest_id;

    IF v_guest_coins IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Gast-Profil nicht gefunden');
    END IF;

    -- 2. Münzen, XP, Streaks übertragen
    UPDATE public.profiles
    SET
        coins = coins + GREATEST(0, v_guest_coins - 100),
        xp = xp + v_guest_xp,
        level = public.get_level_from_xp(xp + v_guest_xp),
        expert_bot_wins = expert_bot_wins + v_guest_expert_wins,
        daily_streak = GREATEST(daily_streak, v_guest_streak),
        last_daily_bonus_date = COALESCE(last_daily_bonus_date, v_guest_bonus_date),
        updated_at = now()
    WHERE id = v_new_user_id
    RETURNING coins, xp, level INTO v_new_coins, v_new_xp, v_new_level;

    -- 3. Matches auf neuen User umschreiben
    UPDATE public.matches
    SET host_id = v_new_user_id
    WHERE host_id = p_guest_id;

    UPDATE public.matches
    SET guest_id = v_new_user_id
    WHERE guest_id = p_guest_id;

    UPDATE public.matches
    SET winner_user_id = v_new_user_id
    WHERE winner_user_id = p_guest_id;

    -- 4. Achievements auf neuen User übertragen (höchste Stufe behalten)
    INSERT INTO public.user_achievements (user_id, achievement_id, claimed_tier, unlocked_at)
    SELECT v_new_user_id, achievement_id, claimed_tier, unlocked_at
    FROM public.user_achievements
    WHERE user_id = p_guest_id
    ON CONFLICT (user_id, achievement_id) DO UPDATE
    SET claimed_tier = GREATEST(public.user_achievements.claimed_tier, EXCLUDED.claimed_tier);

    -- 5. Daily Quests übertragen
    INSERT INTO public.daily_quests (user_id, quest_date, quest_key, category, title, description, current_val, target_val, reward_coins, is_claimed, created_at)
    SELECT v_new_user_id, quest_date, quest_key, category, title, description, current_val, target_val, reward_coins, is_claimed, created_at
    FROM public.daily_quests
    WHERE user_id = p_guest_id
    ON CONFLICT (user_id, quest_date, quest_key) DO NOTHING;

    -- 6. Inventar/Decks auf neuen User übertragen
    INSERT INTO public.user_inventory_decks (user_id, deck_id, unlocked_at)
    SELECT v_new_user_id, deck_id, unlocked_at
    FROM public.user_inventory_decks
    WHERE user_id = p_guest_id
    ON CONFLICT (user_id, deck_id) DO NOTHING;

    -- 7. Gast-Profil in public.profiles löschen
    DELETE FROM public.profiles WHERE id = p_guest_id;

    RETURN jsonb_build_object(
        'success', true,
        'coins', v_new_coins,
        'xp', v_new_xp,
        'level', v_new_level
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
