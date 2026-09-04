-- ==============================================================================
-- Migration: Progressive Level-Kurve & Rang-Tiers (STORY-002)
-- 
-- Spezifikation (Option A + Option 1):
-- - Bronze (Lvl 1-5, à 300 XP):      0 - 1.500 XP
-- - Silber (Lvl 6-15, à 500 XP):     1.500 - 6.500 XP
-- - Gold (Lvl 16-30, à 800 XP):      6.500 - 18.500 XP
-- - Platin (Lvl 31-50, à 1.200 XP):  18.500 - 42.500 XP
-- - Diamant (Lvl 51-100, à 2.000 XP): 42.500 - 142.500 XP
-- - Tier-Aufstiegsbonus: +100 Coins beim Erreichen eines neuen Rang-Tiers
-- ==============================================================================

-- 1. Mathematische Hilfsfunktion: Level aus XP berechnen
CREATE OR REPLACE FUNCTION public.get_level_from_xp(p_xp INT)
RETURNS INT AS $$
BEGIN
    IF p_xp IS NULL OR p_xp < 0 THEN
        RETURN 1;
    ELSIF p_xp < 1500 THEN
        RETURN 1 + (p_xp / 300);
    ELSIF p_xp < 6500 THEN
        RETURN 6 + ((p_xp - 1500) / 500);
    ELSIF p_xp < 18500 THEN
        RETURN 16 + ((p_xp - 6500) / 800);
    ELSIF p_xp < 42500 THEN
        RETURN 31 + ((p_xp - 18500) / 1200);
    ELSIF p_xp < 142500 THEN
        RETURN 51 + ((p_xp - 42500) / 2000);
    ELSE
        RETURN 100;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 2. Hilfsfunktion: Rang-Tier aus Level bestimmen
CREATE OR REPLACE FUNCTION public.get_rank_tier_from_level(p_level INT)
RETURNS TEXT AS $$
BEGIN
    IF p_level IS NULL OR p_level < 6 THEN
        RETURN 'bronze';
    ELSIF p_level < 16 THEN
        RETURN 'silber';
    ELSIF p_level < 31 THEN
        RETURN 'gold';
    ELSIF p_level < 51 THEN
        RETURN 'platin';
    ELSE
        RETURN 'diamant';
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 3. Überarbeitete Belohnungs-RPC Funktion mit Stufen-Level & Tier-Aufstiegsbonus (+100 Coins)
CREATE OR REPLACE FUNCTION public.rpc_claim_match_reward(
    p_match_id UUID,
    p_xp_gain INT,
    p_coins_gain INT
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_old_xp INT;
    v_old_coins INT;
    v_old_level INT;
    v_new_xp INT;
    v_new_coins INT;
    v_new_level INT;
    v_old_tier TEXT;
    v_new_tier TEXT;
    v_tier_bonus_coins INT := 0;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    SELECT xp, coins, level INTO v_old_xp, v_old_coins, v_old_level
    FROM public.profiles
    WHERE id = v_user_id;

    IF v_old_xp IS NULL THEN
        RAISE EXCEPTION 'Profil nicht gefunden';
    END IF;

    v_new_xp := v_old_xp + p_xp_gain;
    v_new_level := public.get_level_from_xp(v_new_xp);

    v_old_tier := public.get_rank_tier_from_level(v_old_level);
    v_new_tier := public.get_rank_tier_from_level(v_new_level);

    -- Option 1: Tier-Aufstiegsbonus (+100 Coins) nur bei Tier-Wechsel (z. B. Bronze -> Silber)
    IF v_new_tier <> v_old_tier AND v_new_level > v_old_level THEN
        v_tier_bonus_coins := 100;
    END IF;

    v_new_coins := v_old_coins + p_coins_gain + v_tier_bonus_coins;

    UPDATE public.profiles
    SET 
        xp = v_new_xp,
        coins = v_new_coins,
        level = v_new_level,
        updated_at = now()
    WHERE id = v_user_id;

    RETURN jsonb_build_object(
        'success', true,
        'xp', v_new_xp,
        'coins', v_new_coins,
        'level', v_new_level,
        'tier', v_new_tier,
        'tier_promoted', (v_tier_bonus_coins > 0),
        'tier_bonus_coins', v_tier_bonus_coins
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Gast-Merge Funktion auf neue Stufen-Funktion umstellen
CREATE OR REPLACE FUNCTION public.rpc_merge_guest_data(p_guest_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_new_user_id UUID := auth.uid();
    v_guest_coins INT;
    v_guest_xp INT;
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
    SELECT coins, xp INTO v_guest_coins, v_guest_xp
    FROM public.profiles
    WHERE id = p_guest_id;

    IF v_guest_coins IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Gast-Profil nicht gefunden');
    END IF;

    -- 2. Münzen und XP übertragen mit neuer Stufenberechnung
    UPDATE public.profiles
    SET
        coins = coins + GREATEST(0, v_guest_coins - 100),
        xp = xp + v_guest_xp,
        level = public.get_level_from_xp(xp + v_guest_xp),
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

    -- 4. Achievements auf neuen User übertragen
    INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at)
    SELECT v_new_user_id, achievement_id, unlocked_at
    FROM public.user_achievements
    WHERE user_id = p_guest_id
    ON CONFLICT (user_id, achievement_id) DO NOTHING;

    -- 5. Inventar/Decks auf neuen User übertragen
    INSERT INTO public.user_inventory_decks (user_id, deck_id, unlocked_at)
    SELECT v_new_user_id, deck_id, unlocked_at
    FROM public.user_inventory_decks
    WHERE user_id = p_guest_id
    ON CONFLICT (user_id, deck_id) DO NOTHING;

    -- 6. Gast-Profil in public.profiles löschen
    DELETE FROM public.profiles WHERE id = p_guest_id;

    RETURN jsonb_build_object(
        'success', true,
        'coins', v_new_coins,
        'xp', v_new_xp,
        'level', v_new_level
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Szenario 3: Rückwärtskompatibilität - Bestehende Spielerprofile fair nach neuer Formel anpassen
UPDATE public.profiles
SET level = public.get_level_from_xp(xp);
