BEGIN;
SELECT plan(12);

-- 1. Tabelle public.user_cosmetics existiert
SELECT has_table('public', 'user_cosmetics', 'Tabelle public.user_cosmetics muss existieren');

-- 2. Spalten in user_cosmetics prüfen
SELECT has_column('public', 'user_cosmetics', 'id', 'user_cosmetics muss id besitzen');
SELECT has_column('public', 'user_cosmetics', 'user_id', 'user_cosmetics muss user_id besitzen');
SELECT has_column('public', 'user_cosmetics', 'item_type', 'user_cosmetics muss item_type besitzen');
SELECT has_column('public', 'user_cosmetics', 'item_id', 'user_cosmetics muss item_id besitzen');
SELECT has_column('public', 'user_cosmetics', 'unlocked_at', 'user_cosmetics muss unlocked_at besitzen');

-- 3. Spalte active_card_back_id in profiles prüfen
SELECT has_column('public', 'profiles', 'active_card_back_id', 'profiles muss active_card_back_id besitzen');

-- 4. RPC Funktion rpc_purchase_cosmetic existiert
SELECT has_function(
    'public', 'rpc_purchase_cosmetic',
    ARRAY['text', 'text', 'integer'],
    'RPC-Funktion rpc_purchase_cosmetic(text, text, int) muss existieren'
);

-- 5. Test-User anlegen
INSERT INTO auth.users (id, email)
VALUES ('22222222-2222-2222-2222-222222222222', 'cosmetics_tester@example.com');

UPDATE public.profiles
SET coins = 500
WHERE id = '22222222-2222-2222-2222-222222222222';

SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" TO '22222222-2222-2222-2222-222222222222';

-- 6. Kauf von Kartenrücken erfolgreich: 350 Coins abziehen, rest 150 Coins
SELECT lives_ok(
    'SELECT public.rpc_purchase_cosmetic(''card_back'', ''card_back_carbon'', 350)',
    'Kauf von card_back_carbon für 350 Coins muss erfolgreich sein'
);

-- 7. Profil-Update verifizieren: coins = 150, active_card_back_id = card_back_carbon
SELECT results_eq(
    'SELECT coins, active_card_back_id FROM public.profiles WHERE id = ''22222222-2222-2222-2222-222222222222''',
    $$VALUES (150, 'card_back_carbon')$$,
    'Profil muss nach Kauf 150 Coins und active_card_back_id card_back_carbon haben'
);

-- 8. Kauf mit camelCase cardBack testen (für 100 Coins, rest 50)
SELECT lives_ok(
    'SELECT public.rpc_purchase_cosmetic(''cardBack'', ''card_back_retro'', 100)',
    'Kauf von card_back_retro mit camelCase cardBack muss normalisiert werden'
);

SELECT results_eq(
    'SELECT coins, active_card_back_id FROM public.profiles WHERE id = ''22222222-2222-2222-2222-222222222222''',
    $$VALUES (50, 'card_back_retro')$$,
    'Profil muss nach weiterem Kauf 50 Coins und active_card_back_id card_back_retro haben'
);

SELECT * FROM finish();
ROLLBACK;
