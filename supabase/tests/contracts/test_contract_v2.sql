-- ============================================================================
-- Contract v2 & Schema Extensions Regression Testsuite (pgTAP)
-- File: supabase/tests/contracts/test_contract_v2.sql
-- Gemäß arc42 Kapitel 8.12 und Issue #17
--
-- Ziel: Testet neue Verträge, Schema-Erweiterungen (Expand & Contract Pattern),
--       Multi-Contract Coexistenz (v1 + v2 nebeneinander) sowie Negativ-Tests
--       (Verifikation, dass inkompatible Typänderungen oder Pflichtfelder
--       ohne Default sofort blockiert werden).
-- ============================================================================

BEGIN;

SELECT plan(29);

-- ============================================================================
-- 1. SCHEMA-ERWEITERUNGEN & EXPAND-PATTERN (8 Tests)
-- Verifiziert, dass Basistabellen additiv erweitert werden können,
-- ohne den Vertrag v1 für bestehende F1-Clients zu verändern.
-- ============================================================================

-- Physische Basistabellen um v2-Spalten additiv erweitern (Expand-Pattern)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS v2_battle_pass_tier INT DEFAULT 1;
ALTER TABLE public.decks ADD COLUMN IF NOT EXISTS v2_season_tag TEXT DEFAULT 'season_1';
ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS v2_ranked_multiplier NUMERIC DEFAULT 1.0;

-- 1.1 Prüfen, dass neue Spalten physisch existieren (3 Tests)
SELECT has_column('public', 'profiles', 'v2_battle_pass_tier', 'Basistabelle profiles besitzt v2_battle_pass_tier');
SELECT has_column('public', 'decks', 'v2_season_tag', 'Basistabelle decks besitzt v2_season_tag');
SELECT has_column('public', 'matches', 'v2_ranked_multiplier', 'Basistabelle matches besitzt v2_ranked_multiplier');

-- 1.2 Isolationstest: v1-Facade-Views dürfen die neuen Spalten NICHT lecken (3 Tests)
SELECT columns_are('public', 'v1_player_profiles', ARRAY[
    'id', 'username', 'avatar_url', 'coins', 'xp', 'level',
    'rank_tier', 'elo_rating', 'active_card_skin_id', 'active_card_back_id',
    'expert_bot_wins', 'daily_streak', 'last_daily_bonus_date',
    'created_at', 'updated_at'
], 'v1_player_profiles bleibt strikt auf v1 isoliert und leckt keine v2-Spalten');

SELECT columns_are('public', 'v1_catalog_decks', ARRAY[
    'id', 'slug', 'name', 'category', 'description', 'cover_image_url',
    'price_coins', 'is_official', 'is_community', 'creator_id',
    'review_status', 'attribute_definitions', 'created_at'
], 'v1_catalog_decks bleibt strikt auf v1 isoliert und leckt keine v2-Spalten');

SELECT columns_are('public', 'v1_matches', ARRAY[
    'id', 'deck_id', 'host_id', 'guest_id', 'match_type', 'status',
    'pot', 'game_state', 'turn_user_id', 'winner_user_id', 'room_code',
    'created_at', 'updated_at'
], 'v1_matches bleibt strikt auf v1 isoliert und leckt keine v2-Spalten');

-- 1.3 Funktionstest: v1-Abfragen bleiben zu 100 % stabil (2 Tests)
SELECT lives_ok(
    'SELECT id, username, level, xp, coins FROM public.v1_player_profiles LIMIT 1',
    'Abfrage auf v1_player_profiles funktioniert nach Tabellenerweiterung weiterhin stabil'
);

SELECT lives_ok(
    'SELECT id, slug, name, price_coins FROM public.v1_catalog_decks LIMIT 1',
    'Abfrage auf v1_catalog_decks funktioniert nach Tabellenerweiterung weiterhin stabil'
);


-- ============================================================================
-- 2. MULTI-CONTRACT COEXISTENZ (V1 + V2 PARALLEL) (10 Tests)
-- Simuliert die Bereitstellung eines neuen v2-Vertrags (F2) neben v1 (F1).
-- ============================================================================

-- v2 Facade-View erstellen (beinhaltet neue v2-Felder)
CREATE OR REPLACE VIEW public.v2_player_profiles WITH (security_invoker = true) AS
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
    v2_battle_pass_tier,
    created_at,
    updated_at
FROM public.profiles;

-- v2 RPC-Funktion definieren (unterstützt zusätzlichen battle_pass_xp Parameter)
CREATE OR REPLACE FUNCTION public.claim_match_reward_v2(
    p_match_id UUID,
    p_xp_gain INT,
    p_coins_gain INT,
    p_battle_pass_xp INT DEFAULT 0
)
RETURNS JSONB AS $$
BEGIN
    -- Interner Aufruf mit Weiterleitung
    RETURN public.claim_match_reward_v1(p_match_id, p_xp_gain, p_coins_gain);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2.1 Prüfen, ob v2-Objekte korrekt bereitgestellt sind (4 Tests)
SELECT has_view('public', 'v2_player_profiles', 'v2_player_profiles Facade View existiert');
SELECT has_column('public', 'v2_player_profiles', 'id', 'v2_player_profiles besitzt id');
SELECT has_column('public', 'v2_player_profiles', 'v2_battle_pass_tier', 'v2_player_profiles liefert v2_battle_pass_tier');
SELECT ok(
    (SELECT 'security_invoker=true' = ANY(c.reloptions)
     FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'public' AND c.relname = 'v2_player_profiles'),
    'v2_player_profiles besitzt security_invoker=true'
);

-- 2.2 Prüfen der versionierten v2 RPC-Signatur (2 Tests)
SELECT has_function('public', 'claim_match_reward_v2', ARRAY['uuid', 'integer', 'integer', 'integer'], 'claim_match_reward_v2 existiert');
SELECT function_returns('public', 'claim_match_reward_v2', ARRAY['uuid', 'integer', 'integer', 'integer'], 'jsonb', 'claim_match_reward_v2 liefert jsonb');

-- 2.3 Parallele Client-Nutzung (F1 und F2 gleichzeitig im selben System) (4 Tests)
-- Testbenutzer sicherstellen
INSERT INTO auth.users (id, email)
VALUES ('55555555-5555-5555-5555-555555555555', 'v2_tester@example.com')
ON CONFLICT (id) DO NOTHING;

SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" TO '55555555-5555-5555-5555-555555555555';

-- F1 Client liest Vertrag v1
SELECT lives_ok(
    'SELECT id, username, level, coins FROM public.v1_player_profiles WHERE id = ''55555555-5555-5555-5555-555555555555''',
    'F1 Client liest erfolgreich über v1_player_profiles'
);

-- F2 Client liest Vertrag v2 (inkl. v2_battle_pass_tier)
SELECT lives_ok(
    'SELECT id, username, level, coins, v2_battle_pass_tier FROM public.v2_player_profiles WHERE id = ''55555555-5555-5555-5555-555555555555''',
    'F2 Client liest erfolgreich über v2_player_profiles inklusive neuer v2-Felder'
);

-- F1 ruft claim_match_reward_v1 (3 Parameter)
SELECT lives_ok(
    'SELECT public.claim_match_reward_v1(gen_random_uuid(), 100, 20)',
    'F1 Client ruft claim_match_reward_v1 erfolgreich auf'
);

-- F2 ruft claim_match_reward_v2 (4 Parameter)
SELECT lives_ok(
    'SELECT public.claim_match_reward_v2(gen_random_uuid(), 100, 20, 50)',
    'F2 Client ruft claim_match_reward_v2 erfolgreich auf'
);


-- ============================================================================
-- 3. NEGATIV-TESTS: REGRESSIONS- & SCHEMA-SCHUTZ (11 Tests)
-- Verifiziert, dass inkompatible Änderungen (Typänderungen, Pflichtfelder ohne
-- Default, Spaltenentfernungen) durch PostgreSQL und pgTAP sofort blockiert werden.
-- ============================================================================
SET LOCAL ROLE postgres;

-- 3.1 Negativ-Test: NOT NULL Spalte ohne DEFAULT auf Tabelle mit Daten (1 Test)
-- Ein Entwickler versucht fälschlicherweise ein Pflichtfeld ohne Default hinzuzufügen.
SELECT throws_ok(
    'ALTER TABLE public.profiles ADD COLUMN illegal_required_field TEXT NOT NULL;',
    '23502',
    NULL::text,
    'NEGATIV-TEST: NOT NULL Spalte ohne DEFAULT auf Tabelle mit Daten wird von Postgres abgewiesen (23502 not_null_violation)'
);

-- 3.2 Negativ-Test: Pflichtfeld ohne Default auf neuer Tabelle bricht v1-Inserts (2 Tests)
CREATE TABLE public.test_simulated_expansion (
    id UUID PRIMARY KEY,
    v1_field TEXT NOT NULL,
    v2_mandatory_field TEXT NOT NULL
);

CREATE VIEW public.v1_simulated_expansion WITH (security_invoker = true) AS
SELECT id, v1_field FROM public.test_simulated_expansion;

SELECT throws_ok(
    'INSERT INTO public.v1_simulated_expansion (id, v1_field) VALUES (gen_random_uuid(), ''test'')',
    '23502',
    NULL::text,
    'NEGATIV-TEST: Insert über v1 View scheitert, wenn neue Tabelle Pflichtfeld ohne Default hat (23502)'
);

ALTER TABLE public.test_simulated_expansion ALTER COLUMN v2_mandatory_field SET DEFAULT 'auto_default';

SELECT lives_ok(
    'INSERT INTO public.v1_simulated_expansion (id, v1_field) VALUES (gen_random_uuid(), ''test'')',
    'POSITIV-TEST: Insert über v1 View gelingt, sobald das neue Feld einen DEFAULT besitzt'
);

-- 3.3 Negativ-Test: Spaltenentfernung auf Basistabelle mit View-Abhängigkeit (3 Tests)
-- Postgres schützt aktive Contracts davor, dass referenzierte Basistabellenspalten gelöscht werden.
SELECT throws_ok(
    'ALTER TABLE public.profiles DROP COLUMN coins;',
    '2BP01',
    NULL::text,
    'NEGATIV-TEST: Postgres verhindert das Löschen von Spalten mit abhängigen v1-Views (2BP01 dependent_objects_still_exist)'
);

SELECT throws_ok(
    'ALTER TABLE public.decks DROP COLUMN name;',
    '2BP01',
    NULL::text,
    'NEGATIV-TEST: Postgres verhindert das Löschen von Spalten der v1_catalog_decks (2BP01)'
);

SELECT throws_ok(
    'ALTER TABLE public.cards DROP COLUMN attributes;',
    '2BP01',
    NULL::text,
    'NEGATIV-TEST: Postgres verhindert das Löschen von Spalten der v1_cards (2BP01)'
);

-- 3.4 Negativ-Test: Inkompatible Typänderung auf Basistabelle (3 Tests)
-- Postgres schützt aktive Contracts vor Typänderungen an referenzierten Spalten.
SELECT throws_ok(
    'ALTER TABLE public.profiles ALTER COLUMN coins TYPE TEXT;',
    '0A000',
    NULL::text,
    'NEGATIV-TEST: Postgres verhindert inkompatible Typänderung an Spalten mit aktiven Views (0A000 feature_not_supported)'
);

SELECT throws_ok(
    'ALTER TABLE public.profiles ALTER COLUMN xp TYPE BIGINT;',
    '0A000',
    NULL::text,
    'NEGATIV-TEST: Postgres verhindert Typänderung von integer auf bigint für v1_player_profiles (0A000)'
);

SELECT throws_ok(
    'ALTER TABLE public.decks ALTER COLUMN price_coins TYPE NUMERIC;',
    '0A000',
    NULL::text,
    'NEGATIV-TEST: Postgres verhindert Typänderung von integer auf numeric für v1_catalog_decks (0A000)'
);

-- 3.5 Negativ-Test: Typvalidierung bei ungültigen Eingaben (1 Test)
SELECT throws_ok(
    'INSERT INTO public.v1_player_profiles (id, username, coins) VALUES (gen_random_uuid(), ''x'', ''ungueltige_zahl'')',
    '22P02',
    NULL::text,
    'NEGATIV-TEST: Ungültiger Datentyp wird bei View-Operationen strikt abgewiesen (22P02 invalid_text_representation)'
);

-- 3.6 Sicherheitsregel: RLS-Schutz auf allen physischen Tabellen (1 Test)
SELECT is(
    (SELECT count(*) FROM pg_class c
     JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relrowsecurity = false
       AND c.relname NOT LIKE '_prisma%' AND c.relname NOT LIKE 'schema_migrations'
       AND c.relname NOT LIKE 'test_%'),
    0::bigint,
    'Alle physischen Basistabellen müssen zwingend RLS aktiviert haben'
);

SELECT * FROM finish();
ROLLBACK;
