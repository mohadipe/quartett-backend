-- ============================================================================
-- Contract v1 Regression Testsuite (pgTAP)
-- File: supabase/tests/contracts/test_contract_v1.sql
-- Gemäß arc42 Kapitel 8.12 und Issue #17
--
-- Ziel: Garantiert, dass alte App-Versionen (F1) durch spätere Backend-Änderungen
--       niemals inkompatibel werden. Prüft alle Views, exakten Spaltenlisten,
--       Datentypen, RPC-Signaturen und das Expand-Pattern.
-- ============================================================================

BEGIN;

SELECT plan(120);

-- ============================================================================
-- 1. EXISTENZ ALLER V1-FACADE-VIEWS PRÜFEN (15 Views)
-- ============================================================================
SELECT has_view('public', 'v1_player_profiles', 'Facade View v1_player_profiles muss existieren');
SELECT has_view('public', 'v1_profiles', 'Alias View v1_profiles muss existieren');
SELECT has_view('public', 'v1_catalog_decks', 'Facade View v1_catalog_decks muss existieren');
SELECT has_view('public', 'v1_decks', 'Alias View v1_decks muss existieren');
SELECT has_view('public', 'v1_cards', 'Facade View v1_cards muss existieren');
SELECT has_view('public', 'v1_deck_cards', 'Alias View v1_deck_cards muss existieren');
SELECT has_view('public', 'v1_user_inventory_decks', 'Facade View v1_user_inventory_decks muss existieren');
SELECT has_view('public', 'v1_matches', 'Facade View v1_matches muss existieren');
SELECT has_view('public', 'v1_match_history', 'Facade View v1_match_history muss existieren');
SELECT has_view('public', 'v1_user_achievements', 'Facade View v1_user_achievements muss existieren');
SELECT has_view('public', 'v1_user_cosmetics', 'Facade View v1_user_cosmetics muss existieren');
SELECT has_view('public', 'v1_deck_reviews', 'Facade View v1_deck_reviews muss existieren');
SELECT has_view('public', 'v1_daily_quests', 'Facade View v1_daily_quests muss existieren');
SELECT has_view('public', 'v1_friendships', 'Facade View v1_friendships muss existieren');
SELECT has_view('public', 'v1_purchase_receipts', 'Facade View v1_purchase_receipts muss existieren');

-- ============================================================================
-- 2. EXAKTE SPALTENPROJEKTION ALLER V1-VIEWS (15 Tests)
-- Verhindert unbemerktes Entfernen oder Hinzufügen von Feldern (Contract Leakage)
-- ============================================================================
SELECT columns_are('public', 'v1_player_profiles', ARRAY[
    'id', 'username', 'avatar_url', 'coins', 'xp', 'level',
    'rank_tier', 'elo_rating', 'active_card_skin_id', 'active_card_back_id',
    'expert_bot_wins', 'daily_streak', 'last_daily_bonus_date',
    'created_at', 'updated_at'
], 'v1_player_profiles besitzt exakt die v1-Vertragsspalten');

SELECT columns_are('public', 'v1_profiles', ARRAY[
    'id', 'username', 'avatar_url', 'coins', 'xp', 'level',
    'rank_tier', 'elo_rating', 'active_card_skin_id', 'active_card_back_id',
    'expert_bot_wins', 'daily_streak', 'last_daily_bonus_date',
    'created_at', 'updated_at'
], 'v1_profiles besitzt exakt die v1-Vertragsspalten');

SELECT columns_are('public', 'v1_catalog_decks', ARRAY[
    'id', 'slug', 'name', 'category', 'description', 'cover_image_url',
    'price_coins', 'is_official', 'is_community', 'creator_id',
    'review_status', 'attribute_definitions', 'created_at', 'language'
], 'v1_catalog_decks besitzt exakt die v1-Vertragsspalten');

SELECT columns_are('public', 'v1_decks', ARRAY[
    'id', 'slug', 'name', 'category', 'description', 'cover_image_url',
    'price_coins', 'is_official', 'is_community', 'creator_id',
    'review_status', 'attribute_definitions', 'created_at', 'language'
], 'v1_decks besitzt exakt die v1-Vertragsspalten');

SELECT columns_are('public', 'v1_cards', ARRAY[
    'id', 'deck_id', 'code', 'name', 'subtitle', 'image_url',
    'fun_fact', 'image_credit', 'attributes', 'created_at'
], 'v1_cards besitzt exakt die v1-Vertragsspalten');

SELECT columns_are('public', 'v1_deck_cards', ARRAY[
    'id', 'deck_id', 'code', 'name', 'subtitle', 'image_url',
    'fun_fact', 'image_credit', 'attributes', 'created_at'
], 'v1_deck_cards besitzt exakt die v1-Vertragsspalten');

SELECT columns_are('public', 'v1_user_inventory_decks', ARRAY[
    'id', 'user_id', 'deck_id', 'unlocked_at'
], 'v1_user_inventory_decks besitzt exakt die v1-Vertragsspalten');

SELECT columns_are('public', 'v1_matches', ARRAY[
    'id', 'deck_id', 'host_id', 'guest_id', 'match_type', 'status',
    'pot', 'game_state', 'turn_user_id', 'winner_user_id', 'room_code',
    'created_at', 'updated_at'
], 'v1_matches besitzt exakt die v1-Vertragsspalten');

SELECT columns_are('public', 'v1_match_history', ARRAY[
    'id', 'user_id', 'deck_id', 'card_sequence', 'chosen_attributes', 'created_at'
], 'v1_match_history besitzt exakt die v1-Vertragsspalten');

SELECT columns_are('public', 'v1_user_achievements', ARRAY[
    'id', 'user_id', 'achievement_id', 'claimed_tier', 'unlocked_at'
], 'v1_user_achievements besitzt exakt die v1-Vertragsspalten');

SELECT columns_are('public', 'v1_user_cosmetics', ARRAY[
    'id', 'user_id', 'item_type', 'item_id', 'unlocked_at'
], 'v1_user_cosmetics besitzt exakt die v1-Vertragsspalten');

SELECT columns_are('public', 'v1_deck_reviews', ARRAY[
    'id', 'deck_id', 'user_id', 'rating', 'comment', 'created_at'
], 'v1_deck_reviews besitzt exakt die v1-Vertragsspalten');

SELECT columns_are('public', 'v1_daily_quests', ARRAY[
    'id', 'user_id', 'quest_date', 'quest_key', 'category', 'title',
    'description', 'current_val', 'target_val', 'reward_coins', 'is_claimed', 'created_at'
], 'v1_daily_quests besitzt exakt die v1-Vertragsspalten');

SELECT columns_are('public', 'v1_friendships', ARRAY[
    'id', 'user_id', 'friend_id', 'status', 'created_at'
], 'v1_friendships besitzt exakt die v1-Vertragsspalten');

SELECT columns_are('public', 'v1_purchase_receipts', ARRAY[
    'id', 'user_id', 'store', 'product_id', 'transaction_id', 'purchased_at'
], 'v1_purchase_receipts besitzt exakt die v1-Vertragsspalten');

-- ============================================================================
-- 3. DATENTYP-VALIDIERUNG (AKZEPTANZKRITERIUM: INKOMPATIBLE TYPIERUNG) (49 Tests)
-- Stellt sicher, dass kein Typ inkompatibel verändert wird
-- ============================================================================
-- 3.1 v1_player_profiles Datentypen (15 Tests)
SELECT col_type_is('public', 'v1_player_profiles', 'id', 'uuid', 'v1_player_profiles.id Typ ist uuid');
SELECT col_type_is('public', 'v1_player_profiles', 'username', 'text', 'v1_player_profiles.username Typ ist text');
SELECT col_type_is('public', 'v1_player_profiles', 'avatar_url', 'text', 'v1_player_profiles.avatar_url Typ ist text');
SELECT col_type_is('public', 'v1_player_profiles', 'coins', 'integer', 'v1_player_profiles.coins Typ ist integer');
SELECT col_type_is('public', 'v1_player_profiles', 'xp', 'integer', 'v1_player_profiles.xp Typ ist integer');
SELECT col_type_is('public', 'v1_player_profiles', 'level', 'integer', 'v1_player_profiles.level Typ ist integer');
SELECT col_type_is('public', 'v1_player_profiles', 'rank_tier', 'text', 'v1_player_profiles.rank_tier Typ ist text');
SELECT col_type_is('public', 'v1_player_profiles', 'elo_rating', 'integer', 'v1_player_profiles.elo_rating Typ ist integer');
SELECT col_type_is('public', 'v1_player_profiles', 'active_card_skin_id', 'text', 'v1_player_profiles.active_card_skin_id Typ ist text');
SELECT col_type_is('public', 'v1_player_profiles', 'active_card_back_id', 'text', 'v1_player_profiles.active_card_back_id Typ ist text');
SELECT col_type_is('public', 'v1_player_profiles', 'expert_bot_wins', 'integer', 'v1_player_profiles.expert_bot_wins Typ ist integer');
SELECT col_type_is('public', 'v1_player_profiles', 'daily_streak', 'integer', 'v1_player_profiles.daily_streak Typ ist integer');
SELECT col_type_is('public', 'v1_player_profiles', 'last_daily_bonus_date', 'date', 'v1_player_profiles.last_daily_bonus_date Typ ist date');
SELECT col_type_is('public', 'v1_player_profiles', 'created_at', 'timestamp with time zone', 'v1_player_profiles.created_at Typ ist timestamptz');
SELECT col_type_is('public', 'v1_player_profiles', 'updated_at', 'timestamp with time zone', 'v1_player_profiles.updated_at Typ ist timestamptz');

-- 3.2 v1_catalog_decks Datentypen (6 Tests)
SELECT col_type_is('public', 'v1_catalog_decks', 'id', 'uuid', 'v1_catalog_decks.id Typ ist uuid');
SELECT col_type_is('public', 'v1_catalog_decks', 'slug', 'text', 'v1_catalog_decks.slug Typ ist text');
SELECT col_type_is('public', 'v1_catalog_decks', 'name', 'text', 'v1_catalog_decks.name Typ ist text');
SELECT col_type_is('public', 'v1_catalog_decks', 'price_coins', 'integer', 'v1_catalog_decks.price_coins Typ ist integer');
SELECT col_type_is('public', 'v1_catalog_decks', 'is_official', 'boolean', 'v1_catalog_decks.is_official Typ ist boolean');
SELECT col_type_is('public', 'v1_catalog_decks', 'attribute_definitions', 'jsonb', 'v1_catalog_decks.attribute_definitions Typ ist jsonb');

-- 3.3 v1_cards Datentypen (4 Tests)
SELECT col_type_is('public', 'v1_cards', 'id', 'uuid', 'v1_cards.id Typ ist uuid');
SELECT col_type_is('public', 'v1_cards', 'deck_id', 'uuid', 'v1_cards.deck_id Typ ist uuid');
SELECT col_type_is('public', 'v1_cards', 'code', 'text', 'v1_cards.code Typ ist text');
SELECT col_type_is('public', 'v1_cards', 'attributes', 'jsonb', 'v1_cards.attributes Typ ist jsonb');

-- 3.4 v1_user_inventory_decks Datentypen (3 Tests)
SELECT col_type_is('public', 'v1_user_inventory_decks', 'id', 'uuid', 'v1_user_inventory_decks.id Typ ist uuid');
SELECT col_type_is('public', 'v1_user_inventory_decks', 'user_id', 'uuid', 'v1_user_inventory_decks.user_id Typ ist uuid');
SELECT col_type_is('public', 'v1_user_inventory_decks', 'deck_id', 'uuid', 'v1_user_inventory_decks.deck_id Typ ist uuid');

-- 3.5 v1_matches Datentypen (4 Tests)
SELECT col_type_is('public', 'v1_matches', 'id', 'uuid', 'v1_matches.id Typ ist uuid');
SELECT col_type_is('public', 'v1_matches', 'status', 'text', 'v1_matches.status Typ ist text');
SELECT col_type_is('public', 'v1_matches', 'pot', 'jsonb', 'v1_matches.pot Typ ist jsonb');
SELECT col_type_is('public', 'v1_matches', 'game_state', 'jsonb', 'v1_matches.game_state Typ ist jsonb');

-- 3.6 v1_match_history Datentypen (3 Tests)
SELECT col_type_is('public', 'v1_match_history', 'id', 'uuid', 'v1_match_history.id Typ ist uuid');
SELECT col_type_is('public', 'v1_match_history', 'user_id', 'uuid', 'v1_match_history.user_id Typ ist uuid');
SELECT col_type_is('public', 'v1_match_history', 'card_sequence', 'jsonb', 'v1_match_history.card_sequence Typ ist jsonb');

-- 3.7 v1_user_achievements Datentypen (3 Tests)
SELECT col_type_is('public', 'v1_user_achievements', 'id', 'uuid', 'v1_user_achievements.id Typ ist uuid');
SELECT col_type_is('public', 'v1_user_achievements', 'achievement_id', 'text', 'v1_user_achievements.achievement_id Typ ist text');
SELECT col_type_is('public', 'v1_user_achievements', 'claimed_tier', 'integer', 'v1_user_achievements.claimed_tier Typ ist integer');

-- 3.8 v1_user_cosmetics Datentypen (3 Tests)
SELECT col_type_is('public', 'v1_user_cosmetics', 'id', 'uuid', 'v1_user_cosmetics.id Typ ist uuid');
SELECT col_type_is('public', 'v1_user_cosmetics', 'item_type', 'text', 'v1_user_cosmetics.item_type Typ ist text');
SELECT col_type_is('public', 'v1_user_cosmetics', 'item_id', 'text', 'v1_user_cosmetics.item_id Typ ist text');

-- 3.9 v1_deck_reviews Datentypen (2 Tests)
SELECT col_type_is('public', 'v1_deck_reviews', 'id', 'uuid', 'v1_deck_reviews.id Typ ist uuid');
SELECT col_type_is('public', 'v1_deck_reviews', 'rating', 'integer', 'v1_deck_reviews.rating Typ ist integer');

-- 3.10 v1_daily_quests Datentypen (4 Tests)
SELECT col_type_is('public', 'v1_daily_quests', 'id', 'uuid', 'v1_daily_quests.id Typ ist uuid');
SELECT col_type_is('public', 'v1_daily_quests', 'quest_date', 'date', 'v1_daily_quests.quest_date Typ ist date');
SELECT col_type_is('public', 'v1_daily_quests', 'reward_coins', 'integer', 'v1_daily_quests.reward_coins Typ ist integer');
SELECT col_type_is('public', 'v1_daily_quests', 'is_claimed', 'boolean', 'v1_daily_quests.is_claimed Typ ist boolean');

-- 3.11 v1_friendships Datentypen (2 Tests)
SELECT col_type_is('public', 'v1_friendships', 'id', 'uuid', 'v1_friendships.id Typ ist uuid');
SELECT col_type_is('public', 'v1_friendships', 'status', 'text', 'v1_friendships.status Typ ist text');

-- ============================================================================
-- 4. RPC-FUNKTIONEN SIGNATUREN & RÜCKGABETYPEN (30 Tests)
-- ============================================================================
-- claim_match_reward_v1
SELECT has_function('public', 'claim_match_reward_v1', ARRAY['uuid', 'integer', 'integer'], 'RPC claim_match_reward_v1 existiert');
SELECT function_returns('public', 'claim_match_reward_v1', ARRAY['uuid', 'integer', 'integer'], 'jsonb', 'claim_match_reward_v1 liefert jsonb');

-- claim_reward_v1
SELECT has_function('public', 'claim_reward_v1', ARRAY['uuid', 'integer', 'integer'], 'RPC claim_reward_v1 existiert');
SELECT function_returns('public', 'claim_reward_v1', ARRAY['uuid', 'integer', 'integer'], 'jsonb', 'claim_reward_v1 liefert jsonb');

-- rpc_claim_match_reward_v1
SELECT has_function('public', 'rpc_claim_match_reward_v1', ARRAY['uuid', 'integer', 'integer'], 'RPC rpc_claim_match_reward_v1 existiert');
SELECT function_returns('public', 'rpc_claim_match_reward_v1', ARRAY['uuid', 'integer', 'integer'], 'jsonb', 'rpc_claim_match_reward_v1 liefert jsonb');

-- purchase_cosmetic_v1
SELECT has_function('public', 'purchase_cosmetic_v1', ARRAY['text', 'text', 'integer'], 'RPC purchase_cosmetic_v1 existiert');
SELECT function_returns('public', 'purchase_cosmetic_v1', ARRAY['text', 'text', 'integer'], 'jsonb', 'purchase_cosmetic_v1 liefert jsonb');

-- rpc_purchase_cosmetic_v1
SELECT has_function('public', 'rpc_purchase_cosmetic_v1', ARRAY['text', 'text', 'integer'], 'RPC rpc_purchase_cosmetic_v1 existiert');
SELECT function_returns('public', 'rpc_purchase_cosmetic_v1', ARRAY['text', 'text', 'integer'], 'jsonb', 'rpc_purchase_cosmetic_v1 liefert jsonb');

-- merge_guest_data_v1
SELECT has_function('public', 'merge_guest_data_v1', ARRAY['uuid'], 'RPC merge_guest_data_v1 existiert');
SELECT function_returns('public', 'merge_guest_data_v1', ARRAY['uuid'], 'jsonb', 'merge_guest_data_v1 liefert jsonb');

-- rpc_merge_guest_data_v1
SELECT has_function('public', 'rpc_merge_guest_data_v1', ARRAY['uuid'], 'RPC rpc_merge_guest_data_v1 existiert');
SELECT function_returns('public', 'rpc_merge_guest_data_v1', ARRAY['uuid'], 'jsonb', 'rpc_merge_guest_data_v1 liefert jsonb');

-- get_or_create_daily_quests_v1
SELECT has_function('public', 'get_or_create_daily_quests_v1', ARRAY['date'], 'RPC get_or_create_daily_quests_v1 existiert');
SELECT function_returns('public', 'get_or_create_daily_quests_v1', ARRAY['date'], 'setof record', 'get_or_create_daily_quests_v1 liefert setof record');

-- rpc_get_or_create_daily_quests_v1
SELECT has_function('public', 'rpc_get_or_create_daily_quests_v1', ARRAY['date'], 'RPC rpc_get_or_create_daily_quests_v1 existiert');
SELECT function_returns('public', 'rpc_get_or_create_daily_quests_v1', ARRAY['date'], 'setof record', 'rpc_get_or_create_daily_quests_v1 liefert setof record');

-- claim_daily_quest_v1
SELECT has_function('public', 'claim_daily_quest_v1', ARRAY['uuid'], 'RPC claim_daily_quest_v1 existiert');
SELECT function_returns('public', 'claim_daily_quest_v1', ARRAY['uuid'], 'jsonb', 'claim_daily_quest_v1 liefert jsonb');

-- rpc_claim_daily_quest_v1
SELECT has_function('public', 'rpc_claim_daily_quest_v1', ARRAY['uuid'], 'RPC rpc_claim_daily_quest_v1 existiert');
SELECT function_returns('public', 'rpc_claim_daily_quest_v1', ARRAY['uuid'], 'jsonb', 'rpc_claim_daily_quest_v1 liefert jsonb');

-- claim_daily_bonus_v1
SELECT has_function('public', 'claim_daily_bonus_v1', ARRAY['date'], 'RPC claim_daily_bonus_v1 existiert');
SELECT function_returns('public', 'claim_daily_bonus_v1', ARRAY['date'], 'jsonb', 'claim_daily_bonus_v1 liefert jsonb');

-- rpc_claim_daily_bonus_v1
SELECT has_function('public', 'rpc_claim_daily_bonus_v1', ARRAY['date'], 'RPC rpc_claim_daily_bonus_v1 existiert');
SELECT function_returns('public', 'rpc_claim_daily_bonus_v1', ARRAY['date'], 'jsonb', 'rpc_claim_daily_bonus_v1 liefert jsonb');

-- join_lobby_v1
SELECT has_function('public', 'join_lobby_v1', ARRAY['text'], 'RPC join_lobby_v1 existiert');
SELECT function_returns('public', 'join_lobby_v1', ARRAY['text'], 'jsonb', 'join_lobby_v1 liefert jsonb');

-- rpc_join_lobby_v1
SELECT has_function('public', 'rpc_join_lobby_v1', ARRAY['text'], 'RPC rpc_join_lobby_v1 existiert');
SELECT function_returns('public', 'rpc_join_lobby_v1', ARRAY['text'], 'jsonb', 'rpc_join_lobby_v1 liefert jsonb');

-- ============================================================================
-- 5. SECURITY INVOKER VALIDIERUNG (1 Test)
-- Stellt sicher, dass alle v1_* Views mit security_invoker = true laufen
-- ============================================================================
SELECT is(
    (SELECT count(*) FROM pg_class c
     JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'public' AND c.relkind = 'v' AND c.relname LIKE 'v1_%'
       AND NOT ('security_invoker=true' = ANY(COALESCE(c.reloptions, ARRAY[]::text[])))),
    0::bigint,
    'Alle v1_* Views müssen zwingend mit security_invoker=true konfiguriert sein'
);

-- ============================================================================
-- 6. RUNTIME SIMULATION EINES CLIENTS F1 (AUTHENTIFIZIERT) (8 Tests)
-- ============================================================================
-- Testbenutzer anlegen
INSERT INTO auth.users (id, email)
VALUES ('11111111-1111-1111-1111-111111111111', 'f1_client@example.com'),
       ('22222222-2222-2222-2222-222222222222', 'f1_opponent@example.com')
ON CONFLICT (id) DO NOTHING;

-- Host erstellt Match
INSERT INTO public.matches (id, host_id, room_code, status, match_type)
VALUES ('99999999-9999-9999-9999-999999999999', '22222222-2222-2222-2222-222222222222', 'ROOMF1', 'waiting', 'live')
ON CONFLICT (id) DO NOTHING;

-- Als F1 Client anmelden
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" TO '11111111-1111-1111-1111-111111111111';

SELECT lives_ok(
    'SELECT id, username, coins, xp, level, rank_tier FROM public.v1_player_profiles WHERE id = ''11111111-1111-1111-1111-111111111111''',
    'F1 Client kann eigenes Spielerprofil über v1_player_profiles abfragen'
);

SELECT lives_ok(
    'SELECT id, name, slug, price_coins FROM public.v1_catalog_decks LIMIT 5',
    'F1 Client kann Katalog-Decks über v1_catalog_decks abfragen'
);

SELECT lives_ok(
    'SELECT id, code, name, attributes FROM public.v1_cards LIMIT 5',
    'F1 Client kann Karten über v1_cards abfragen'
);

SELECT lives_ok(
    'SELECT public.claim_match_reward_v1(gen_random_uuid(), 150, 10)',
    'F1 Client kann claim_match_reward_v1 erfolgreich ausführen'
);

SELECT lives_ok(
    'SELECT * FROM public.get_or_create_daily_quests_v1(CURRENT_DATE)',
    'F1 Client kann get_or_create_daily_quests_v1 erfolgreich ausführen'
);

SELECT lives_ok(
    'SELECT public.join_lobby_v1(''ROOMF1'')',
    'F1 Client kann Lobby via join_lobby_v1 beitreten'
);

SELECT lives_ok(
    'UPDATE public.v1_player_profiles SET username = ''F1Tester'' WHERE id = ''11111111-1111-1111-1111-111111111111''',
    'F1 Client kann eigenes Profil über v1_player_profiles aktualisieren'
);

SELECT results_eq(
    'SELECT username FROM public.v1_player_profiles WHERE id = ''11111111-1111-1111-1111-111111111111''',
    'VALUES (''F1Tester''::text)',
    'Username-Änderung über v1_player_profiles muss persistent übernommen werden'
);

-- ============================================================================
-- 7. AKZEPTANZKRITERIUM: EXPAND-PATTERN SCHEMA-STABILITÄT (2 Tests)
-- Eine Spaltenerweiterung auf der Basistabelle verändert den Vertrag v1 nicht!
-- ============================================================================
SET LOCAL ROLE postgres;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS future_v2_extension_column TEXT DEFAULT 'v2_data';

SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" TO '11111111-1111-1111-1111-111111111111';

SELECT columns_are('public', 'v1_player_profiles', ARRAY[
    'id', 'username', 'avatar_url', 'coins', 'xp', 'level',
    'rank_tier', 'elo_rating', 'active_card_skin_id', 'active_card_back_id',
    'expert_bot_wins', 'daily_streak', 'last_daily_bonus_date',
    'created_at', 'updated_at'
], 'AKZEPTANZKRITERIUM: Spaltenerweiterung auf physischer Tabelle leckt nicht in v1_player_profiles');

SELECT lives_ok(
    'SELECT id, username, coins, xp, level FROM public.v1_player_profiles WHERE id = ''11111111-1111-1111-1111-111111111111''',
    'AKZEPTANZKRITERIUM: v1_player_profiles bleibt trotz physischer Tabellenerweiterung zu 100% stabil abfragbar'
);

SELECT * FROM finish();
ROLLBACK;
