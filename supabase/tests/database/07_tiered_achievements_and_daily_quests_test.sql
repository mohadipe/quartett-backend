BEGIN;
SELECT plan(23);

-- 1. Prüfen, ob Spalte claimed_tier in public.user_achievements existiert
SELECT has_column(
    'public', 'user_achievements', 'claimed_tier',
    'Tabelle "user_achievements" muss Spalte "claimed_tier" besitzen'
);

-- 2. Prüfen, ob neue Spalten in profiles existieren
SELECT has_column(
    'public', 'profiles', 'expert_bot_wins',
    'Tabelle "profiles" muss Spalte "expert_bot_wins" besitzen'
);

SELECT has_column(
    'public', 'profiles', 'daily_streak',
    'Tabelle "profiles" muss Spalte "daily_streak" besitzen'
);

SELECT has_column(
    'public', 'profiles', 'last_daily_bonus_date',
    'Tabelle "profiles" muss Spalte "last_daily_bonus_date" besitzen'
);

-- 3. Prüfen, ob Tabelle public.daily_quests existiert
SELECT has_table(
    'public', 'daily_quests',
    'Tabelle "daily_quests" muss existieren'
);

-- 4. Spalten in daily_quests prüfen
SELECT has_column('public', 'daily_quests', 'id', 'daily_quests muss Spalte id besitzen');
SELECT has_column('public', 'daily_quests', 'user_id', 'daily_quests muss Spalte user_id besitzen');
SELECT has_column('public', 'daily_quests', 'quest_date', 'daily_quests muss Spalte quest_date besitzen');
SELECT has_column('public', 'daily_quests', 'quest_key', 'daily_quests muss Spalte quest_key besitzen');
SELECT has_column('public', 'daily_quests', 'category', 'daily_quests muss Spalte category besitzen');
SELECT has_column('public', 'daily_quests', 'current_val', 'daily_quests muss Spalte current_val besitzen');
SELECT has_column('public', 'daily_quests', 'target_val', 'daily_quests muss Spalte target_val besitzen');
SELECT has_column('public', 'daily_quests', 'reward_coins', 'daily_quests muss Spalte reward_coins besitzen');
SELECT has_column('public', 'daily_quests', 'is_claimed', 'daily_quests muss Spalte is_claimed besitzen');

-- 5. RLS auf daily_quests aktiviert
SELECT results_eq(
    'SELECT relrowsecurity FROM pg_class WHERE relname = ''daily_quests'' AND relnamespace = ''public''::regnamespace',
    ARRAY[true],
    'Tabelle "daily_quests" muss RLS aktiviert haben'
);

-- 6. RPC Funktionen prüfen
SELECT has_function(
    'public', 'rpc_get_or_create_daily_quests',
    ARRAY['date'],
    'RPC Funktion rpc_get_or_create_daily_quests(date) muss existieren'
);

SELECT has_function(
    'public', 'rpc_claim_daily_quest',
    ARRAY['uuid'],
    'RPC Funktion rpc_claim_daily_quest(uuid) muss existieren'
);

SELECT has_function(
    'public', 'rpc_claim_daily_bonus',
    ARRAY['date'],
    'RPC Funktion rpc_claim_daily_bonus(date) muss existieren'
);

-- 7. Test-User anlegen und Quests generieren
INSERT INTO auth.users (id, email)
VALUES ('77777777-7777-7777-7777-777777777777', 'quest_tester@example.com');

UPDATE public.profiles
SET coins = 100, daily_streak = 0
WHERE id = '77777777-7777-7777-7777-777777777777';

SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" TO '77777777-7777-7777-7777-777777777777';

-- 8. rpc_get_or_create_daily_quests muss 3 Quests erzeugen
SELECT results_eq(
    'SELECT count(*)::int FROM public.rpc_get_or_create_daily_quests(CURRENT_DATE)',
    ARRAY[3],
    'rpc_get_or_create_daily_quests muss genau 3 Quests zurückgeben'
);

-- 9. Idempotenz: Zweiter Aufruf erzeugt keine Duplikate
SELECT results_eq(
    'SELECT count(*)::int FROM public.rpc_get_or_create_daily_quests(CURRENT_DATE)',
    ARRAY[3],
    'Zweiter Aufruf von rpc_get_or_create_daily_quests muss dieselben 3 Quests liefern'
);

-- 10. Quest abschließen und einlösen
DO $$
DECLARE
    v_first_id UUID;
    v_target INT;
BEGIN
    SELECT id, target_val INTO v_first_id, v_target
    FROM public.daily_quests
    WHERE user_id = '77777777-7777-7777-7777-777777777777' AND quest_date = CURRENT_DATE
    ORDER BY category LIMIT 1;

    UPDATE public.daily_quests
    SET current_val = v_target
    WHERE id = v_first_id;
END $$;

SELECT results_eq(
    'SELECT (public.rpc_claim_daily_quest(id)->>''success'')::boolean FROM public.daily_quests WHERE user_id = ''77777777-7777-7777-7777-777777777777'' AND current_val = target_val LIMIT 1',
    ARRAY[true],
    'rpc_claim_daily_quest muss bei erreichtem Missionsziel erfolgreich sein'
);

-- 11. Alle 3 Quests abschließen und einlösen
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN SELECT id, target_val FROM public.daily_quests WHERE user_id = '77777777-7777-7777-7777-777777777777' AND is_claimed = false LOOP
        UPDATE public.daily_quests SET current_val = r.target_val WHERE id = r.id;
        PERFORM public.rpc_claim_daily_quest(r.id);
    END LOOP;
END $$;

-- 12. Tages-Bonus einlösen
SELECT results_eq(
    'SELECT (public.rpc_claim_daily_bonus(CURRENT_DATE)->>''success'')::boolean',
    ARRAY[true],
    'rpc_claim_daily_bonus muss bei 3 eingelösten Quests erfolgreich sein'
);

-- 13. Erneutes Einlösen am selben Tag muss scheitern
SELECT throws_ok(
    'SELECT public.rpc_claim_daily_bonus(CURRENT_DATE)',
    NULL,
    'Erneutes Einlösen des Tagesbonus am selben Tag muss abgewiesen werden'
);

SELECT * FROM finish();
ROLLBACK;
