-- Migration: 20260906160000_contract_facade_layer_v1.sql
-- STORY-010F: Einführung des Contract-Facade-Layers (Versionierte Views & RPCs)
-- Gemäß arc42 Kapitel 8.12 (Multi-Stage & Contract-Versioning)

-- ============================================================================
-- 1. STABILE FACADE-VIEWS (CONTRACT V1)
-- ============================================================================
-- Views mit 'security_invoker = true' wahren die RLS-Policies des aufrufenden Nutzers.
-- Explizite Spaltenauswahl garantiert, dass zukünftige Tabellenerweiterungen
-- (Expand-Pattern) den v1-Vertrag nicht verändern oder beschädigen.

-- 1.1 Player Profiles View
CREATE OR REPLACE VIEW public.v1_player_profiles WITH (security_invoker = true) AS
SELECT
    id,
    username,
    avatar_url,
    coins,
    xp,
    level,
    public.get_rank_tier_from_level(level) AS rank_tier,
    elo_rating,
    active_card_skin_id,
    active_card_back_id,
    expert_bot_wins,
    daily_streak,
    last_daily_bonus_date,
    created_at,
    updated_at
FROM public.profiles;

CREATE OR REPLACE VIEW public.v1_profiles WITH (security_invoker = true) AS
SELECT * FROM public.v1_player_profiles;

-- 1.2 Catalog Decks View
CREATE OR REPLACE VIEW public.v1_catalog_decks WITH (security_invoker = true) AS
SELECT
    id,
    slug,
    name,
    category,
    description,
    cover_image_url,
    price_coins,
    is_official,
    is_community,
    creator_id,
    review_status,
    attribute_definitions,
    created_at
FROM public.decks;

CREATE OR REPLACE VIEW public.v1_decks WITH (security_invoker = true) AS
SELECT * FROM public.v1_catalog_decks;

-- 1.3 Cards View
CREATE OR REPLACE VIEW public.v1_cards WITH (security_invoker = true) AS
SELECT
    id,
    deck_id,
    code,
    name,
    subtitle,
    image_url,
    fun_fact,
    image_credit,
    attributes,
    created_at
FROM public.cards;

CREATE OR REPLACE VIEW public.v1_deck_cards WITH (security_invoker = true) AS
SELECT * FROM public.v1_cards;

-- 1.4 User Inventory Decks View
CREATE OR REPLACE VIEW public.v1_user_inventory_decks WITH (security_invoker = true) AS
SELECT
    id,
    user_id,
    deck_id,
    unlocked_at
FROM public.user_inventory_decks;

-- 1.5 Matches View
CREATE OR REPLACE VIEW public.v1_matches WITH (security_invoker = true) AS
SELECT
    id,
    deck_id,
    host_id,
    guest_id,
    match_type,
    status,
    pot,
    game_state,
    turn_user_id,
    winner_user_id,
    room_code,
    created_at,
    updated_at
FROM public.matches;

-- 1.6 Match History View
CREATE OR REPLACE VIEW public.v1_match_history WITH (security_invoker = true) AS
SELECT
    id,
    user_id,
    deck_id,
    card_sequence,
    chosen_attributes,
    created_at
FROM public.match_history;

-- 1.7 User Achievements View
CREATE OR REPLACE VIEW public.v1_user_achievements WITH (security_invoker = true) AS
SELECT
    id,
    user_id,
    achievement_id,
    claimed_tier,
    unlocked_at
FROM public.user_achievements;

-- 1.8 User Cosmetics View
CREATE OR REPLACE VIEW public.v1_user_cosmetics WITH (security_invoker = true) AS
SELECT
    id,
    user_id,
    item_type,
    item_id,
    unlocked_at
FROM public.user_cosmetics;

-- 1.9 Deck Reviews View
CREATE OR REPLACE VIEW public.v1_deck_reviews WITH (security_invoker = true) AS
SELECT
    id,
    deck_id,
    user_id,
    rating,
    comment,
    created_at
FROM public.deck_reviews;

-- 1.10 Daily Quests View
CREATE OR REPLACE VIEW public.v1_daily_quests WITH (security_invoker = true) AS
SELECT
    id,
    user_id,
    quest_date,
    quest_key,
    category,
    title,
    description,
    current_val,
    target_val,
    reward_coins,
    is_claimed,
    created_at
FROM public.daily_quests;

-- 1.11 Friendships View
CREATE OR REPLACE VIEW public.v1_friendships WITH (security_invoker = true) AS
SELECT
    id,
    user_id,
    friend_id,
    status,
    created_at
FROM public.friendships;

-- 1.12 Purchase Receipts View
CREATE OR REPLACE VIEW public.v1_purchase_receipts WITH (security_invoker = true) AS
SELECT
    id,
    user_id,
    store,
    product_id,
    transaction_id,
    purchased_at
FROM public.purchase_receipts;


-- ============================================================================
-- 2. VERSIONIERTE RPC-FUNKTIONEN (CONTRACT V1)
-- ============================================================================

-- 2.1 Match Reward Claim (v1)
CREATE OR REPLACE FUNCTION public.claim_match_reward_v1(
    p_match_id UUID,
    p_xp_gain INT,
    p_coins_gain INT
)
RETURNS JSONB AS $$
BEGIN
    RETURN public.rpc_claim_match_reward(p_match_id, p_xp_gain, p_coins_gain);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Aliase für flexible Client-Aufrufe
CREATE OR REPLACE FUNCTION public.claim_reward_v1(
    p_match_id UUID,
    p_xp_gain INT,
    p_coins_gain INT
)
RETURNS JSONB AS $$
BEGIN
    RETURN public.claim_match_reward_v1(p_match_id, p_xp_gain, p_coins_gain);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.rpc_claim_match_reward_v1(
    p_match_id UUID,
    p_xp_gain INT,
    p_coins_gain INT
)
RETURNS JSONB AS $$
BEGIN
    RETURN public.claim_match_reward_v1(p_match_id, p_xp_gain, p_coins_gain);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 2.2 Cosmetic Purchase (v1)
CREATE OR REPLACE FUNCTION public.purchase_cosmetic_v1(
    p_item_type TEXT,
    p_item_id TEXT,
    p_price INT
)
RETURNS JSONB AS $$
BEGIN
    RETURN public.rpc_purchase_cosmetic(p_item_type, p_item_id, p_price);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.rpc_purchase_cosmetic_v1(
    p_item_type TEXT,
    p_item_id TEXT,
    p_price INT
)
RETURNS JSONB AS $$
BEGIN
    RETURN public.purchase_cosmetic_v1(p_item_type, p_item_id, p_price);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 2.3 Guest Data Merge (v1)
CREATE OR REPLACE FUNCTION public.merge_guest_data_v1(
    p_guest_id UUID
)
RETURNS JSONB AS $$
BEGIN
    RETURN public.rpc_merge_guest_data(p_guest_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.rpc_merge_guest_data_v1(
    p_guest_id UUID
)
RETURNS JSONB AS $$
BEGIN
    RETURN public.merge_guest_data_v1(p_guest_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 2.4 Daily Quests (v1)
CREATE OR REPLACE FUNCTION public.get_or_create_daily_quests_v1(
    p_date DATE DEFAULT CURRENT_DATE
)
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
BEGIN
    RETURN QUERY SELECT * FROM public.rpc_get_or_create_daily_quests(p_date);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.rpc_get_or_create_daily_quests_v1(
    p_date DATE DEFAULT CURRENT_DATE
)
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
BEGIN
    RETURN QUERY SELECT * FROM public.get_or_create_daily_quests_v1(p_date);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.claim_daily_quest_v1(
    p_quest_id UUID
)
RETURNS JSONB AS $$
BEGIN
    RETURN public.rpc_claim_daily_quest(p_quest_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.rpc_claim_daily_quest_v1(
    p_quest_id UUID
)
RETURNS JSONB AS $$
BEGIN
    RETURN public.claim_daily_quest_v1(p_quest_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.claim_daily_bonus_v1(
    p_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB AS $$
BEGIN
    RETURN public.rpc_claim_daily_bonus(p_date);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.rpc_claim_daily_bonus_v1(
    p_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSONB AS $$
BEGIN
    RETURN public.claim_daily_bonus_v1(p_date);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 2.5 Lobby Join RPC (v1)
CREATE OR REPLACE FUNCTION public.join_lobby_v1(
    p_room_code TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_match public.matches%ROWTYPE;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    SELECT * INTO v_match
    FROM public.matches
    WHERE room_code = UPPER(p_room_code)
      AND status = 'waiting'
    LIMIT 1
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Lobby mit Code % nicht gefunden oder bereits voll.', p_room_code;
    END IF;

    IF v_match.host_id = v_user_id THEN
        RAISE EXCEPTION 'Host kann nicht als Gast beitreten.';
    END IF;

    UPDATE public.matches
    SET guest_id = v_user_id,
        status = 'active',
        updated_at = NOW()
    WHERE id = v_match.id;

    RETURN jsonb_build_object(
        'success', true,
        'match_id', v_match.id,
        'room_code', v_match.room_code,
        'deck_id', v_match.deck_id,
        'host_id', v_match.host_id,
        'guest_id', v_user_id,
        'status', 'active'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.rpc_join_lobby_v1(
    p_room_code TEXT
)
RETURNS JSONB AS $$
BEGIN
    RETURN public.join_lobby_v1(p_room_code);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================================
-- 3. RECHTE & POSTGREST SCHEMA-CACHE
-- ============================================================================
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

NOTIFY pgrst, 'reload schema';
