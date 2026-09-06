BEGIN;
SELECT plan(30);

-- 1. Prüfen, ob die Facade-Views existieren
SELECT has_view('public', 'v1_player_profiles', 'Facade View v1_player_profiles muss existieren');
SELECT has_view('public', 'v1_profiles', 'Facade View v1_profiles muss existieren');
SELECT has_view('public', 'v1_catalog_decks', 'Facade View v1_catalog_decks muss existieren');
SELECT has_view('public', 'v1_decks', 'Facade View v1_decks muss existieren');
SELECT has_view('public', 'v1_cards', 'Facade View v1_cards muss existieren');
SELECT has_view('public', 'v1_matches', 'Facade View v1_matches muss existieren');
SELECT has_view('public', 'v1_match_history', 'Facade View v1_match_history muss existieren');
SELECT has_view('public', 'v1_user_inventory_decks', 'Facade View v1_user_inventory_decks muss existieren');
SELECT has_view('public', 'v1_user_achievements', 'Facade View v1_user_achievements muss existieren');
SELECT has_view('public', 'v1_user_cosmetics', 'Facade View v1_user_cosmetics muss existieren');
SELECT has_view('public', 'v1_deck_reviews', 'Facade View v1_deck_reviews muss existieren');
SELECT has_view('public', 'v1_daily_quests', 'Facade View v1_daily_quests muss existieren');

-- 2. Prüfen, ob versionierte RPC-Funktionen existieren
SELECT has_function('public', 'claim_reward_v1', ARRAY['uuid', 'integer', 'integer'], 'RPC claim_reward_v1(uuid, int, int) muss existieren');
SELECT has_function('public', 'claim_match_reward_v1', ARRAY['uuid', 'integer', 'integer'], 'RPC claim_match_reward_v1(uuid, int, int) muss existieren');
SELECT has_function('public', 'purchase_cosmetic_v1', ARRAY['text', 'text', 'integer'], 'RPC purchase_cosmetic_v1(text, text, int) muss existieren');
SELECT has_function('public', 'merge_guest_data_v1', ARRAY['uuid'], 'RPC merge_guest_data_v1(uuid) muss existieren');
SELECT has_function('public', 'get_or_create_daily_quests_v1', ARRAY['date'], 'RPC get_or_create_daily_quests_v1(date) muss existieren');
SELECT has_function('public', 'claim_daily_quest_v1', ARRAY['uuid'], 'RPC claim_daily_quest_v1(uuid) muss existieren');
SELECT has_function('public', 'claim_daily_bonus_v1', ARRAY['date'], 'RPC claim_daily_bonus_v1(date) muss existieren');
SELECT has_function('public', 'join_lobby_v1', ARRAY['text'], 'RPC join_lobby_v1(text) muss existieren');

-- 3. Test-User anlegen
INSERT INTO auth.users (id, email)
VALUES ('77777777-7777-7777-7777-777777777777', 'v1_tester@example.com');

INSERT INTO auth.users (id, email)
VALUES ('88888888-8888-8888-8888-888888888888', 'v1_host@example.com');

-- 4. Facade-Views Abfragen als authentifizierter Benutzer testen
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" TO '77777777-7777-7777-7777-777777777777';

SELECT lives_ok(
    'SELECT id, username, level, xp, coins FROM public.v1_player_profiles WHERE id = ''77777777-7777-7777-7777-777777777777''',
    'Abfrage auf v1_player_profiles muss erfolgreich sein'
);

SELECT lives_ok(
    'SELECT id, name, slug FROM public.v1_catalog_decks LIMIT 5',
    'Abfrage auf v1_catalog_decks muss erfolgreich sein'
);

-- 5. Versionierte RPCs testen
SELECT lives_ok(
    'SELECT public.claim_reward_v1(gen_random_uuid(), 300, 25)',
    'claim_reward_v1 muss für authentifizierten Benutzer funktionieren'
);

SELECT lives_ok(
    'SELECT public.claim_match_reward_v1(gen_random_uuid(), 300, 25)',
    'claim_match_reward_v1 muss für authentifizierten Benutzer funktionieren'
);

SELECT lives_ok(
    'SELECT public.get_or_create_daily_quests_v1(CURRENT_DATE)',
    'get_or_create_daily_quests_v1 muss Quests für aktuellen Benutzer zurückliefern'
);

-- 6. Lobby-Join via Facade-Layer testen
-- Host erstellt Match
SET LOCAL "request.jwt.claim.sub" TO '88888888-8888-8888-8888-888888888888';
INSERT INTO public.matches (id, host_id, room_code, status, match_type)
VALUES ('99999999-9999-9999-9999-999999999999', '88888888-8888-8888-8888-888888888888', 'ROOMV1', 'waiting', 'live');

-- Gast ruft join_lobby_v1 auf
SET LOCAL "request.jwt.claim.sub" TO '77777777-7777-7777-7777-777777777777';
SELECT lives_ok(
    'SELECT public.join_lobby_v1(''ROOMV1'')',
    'join_lobby_v1 muss Raum beitreten können'
);

SELECT results_eq(
    'SELECT guest_id, status FROM public.v1_matches WHERE id = ''99999999-9999-9999-9999-999999999999''',
    'VALUES (''77777777-7777-7777-7777-777777777777''::uuid, ''active''::text)',
    'Match-Status und guest_id müssen nach join_lobby_v1 in v1_matches aktualisiert sein'
);

-- 7. Facade View Updatability (UPDATE via View)
SELECT lives_ok(
    'UPDATE public.v1_player_profiles SET username = ''GibbsUpdated'' WHERE id = ''77777777-7777-7777-7777-777777777777''',
    'Update über v1_player_profiles muss erfolgreich durchführbar sein'
);

SELECT results_eq(
    'SELECT username FROM public.v1_player_profiles WHERE id = ''77777777-7777-7777-7777-777777777777''',
    'VALUES (''GibbsUpdated''::text)',
    'Username muss über v1_player_profiles geändert worden sein'
);

-- 8. Akzeptanzkriterium: Expand & Contract (Schema-Erweiterung bricht v1 nicht)
SET LOCAL ROLE postgres;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS future_feature_v2_field TEXT DEFAULT 'new_data';

SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" TO '77777777-7777-7777-7777-777777777777';

SELECT lives_ok(
    'SELECT id, username, level, xp, coins FROM public.v1_player_profiles WHERE id = ''77777777-7777-7777-7777-777777777777''',
    'AKZEPTANZKRITERIUM: v1_player_profiles bleibt trotz physischer Schema-Erweiterung zu 100% stabil abfragbar'
);

SELECT * FROM finish();
ROLLBACK;
