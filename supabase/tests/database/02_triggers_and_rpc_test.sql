BEGIN;
SELECT plan(4);

-- 1. Prüfen, ob die Trigger- und RPC-Funktionen existieren
SELECT has_function(
    'public', 'handle_new_user',
    'Trigger-Funktion handle_new_user muss existieren'
);

SELECT has_function(
    'public', 'rpc_claim_match_reward',
    ARRAY['uuid', 'integer', 'integer'],
    'RPC-Funktion rpc_claim_match_reward(uuid, int, int) muss existieren'
);

-- 2. Test-User anlegen und Trigger-Ausführung prüfen
INSERT INTO auth.users (id, email)
VALUES ('11111111-1111-1111-1111-111111111111', 'test_user@example.com');

SELECT results_eq(
    'SELECT coins, level, xp FROM public.profiles WHERE id = ''11111111-1111-1111-1111-111111111111''',
    'VALUES (100, 1, 0)',
    'Trigger on_auth_user_created muss neues Profil mit 100 Start-Münzen, Level 1 und 0 XP anlegen'
);

-- 3. Belohnungs-RPC Funktion testen (XP +600, Coins +50 ➔ Level 2)
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" TO '11111111-1111-1111-1111-111111111111';

SELECT lives_ok(
    'SELECT public.rpc_claim_match_reward(gen_random_uuid(), 600, 50)',
    'rpc_claim_match_reward muss für authentifizierten Spieler ohne Fehler durchlaufen'
);

SELECT * FROM finish();
ROLLBACK;
