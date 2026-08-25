-- Migration 03: Secure Backend Functions (RPC)

-- 1. Automatisches Profil beim ersten Login (Gast oder OAuth)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, username, coins, xp, level)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', 'Spieler_' || SUBSTRING(NEW.id::TEXT, 1, 6)),
        100, -- 100 Start-Münzen geschenkt!
        0,
        1
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. Sichere Belohnungs-Vergabe nach Match-Abschluss
CREATE OR REPLACE FUNCTION public.rpc_claim_match_reward(
    p_match_id UUID,
    p_xp_gain INT,
    p_coins_gain INT
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_new_xp INT;
    v_new_coins INT;
    v_new_level INT;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    UPDATE public.profiles
    SET 
        xp = xp + p_xp_gain,
        coins = coins + p_coins_gain,
        level = 1 + FLOOR((xp + p_xp_gain) / 500),
        updated_at = now()
    WHERE id = v_user_id
    RETURNING xp, coins, level INTO v_new_xp, v_new_coins, v_new_level;

    RETURN jsonb_build_object(
        'success', true,
        'xp', v_new_xp,
        'coins', v_new_coins,
        'level', v_new_level
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Gast-Account Daten-Merge nach OAuth-Registrierung
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
        -- Kein Gast-Profil gefunden, breche ab
        RETURN jsonb_build_object('success', false, 'message', 'Gast-Profil nicht gefunden');
    END IF;

    -- 2. Münzen und XP übertragen
    -- Startmünzen (100) vom Gast abziehen, falls er sie noch hat, sonst nur die Netto-Münzen übertragen
    UPDATE public.profiles
    SET
        coins = coins + GREATEST(0, v_guest_coins - 100),
        xp = xp + v_guest_xp,
        level = 1 + FLOOR((xp + v_guest_xp) / 500),
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
