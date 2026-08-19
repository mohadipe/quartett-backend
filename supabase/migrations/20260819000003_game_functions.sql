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
