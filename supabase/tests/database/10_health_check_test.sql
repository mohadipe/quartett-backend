BEGIN;
SELECT plan(16);

-- ============================================================================
-- 1. Funktions-Existenz und Rückgabetyp prüfen
-- ============================================================================
SELECT has_function('public', 'health_check', ARRAY[]::text[], 'RPC health_check() muss existieren');
SELECT has_function('public', 'health_check_v1', ARRAY[]::text[], 'RPC health_check_v1() muss existieren');
SELECT function_returns('public', 'health_check', ARRAY[]::text[], 'jsonb', 'health_check() muss jsonb zurückliefern');
SELECT function_returns('public', 'health_check_v1', ARRAY[]::text[], 'jsonb', 'health_check_v1() muss jsonb zurückliefern');

-- ============================================================================
-- 2. Ausführung & Rückgabestruktur für unauthentifizierten Client ('anon')
-- ============================================================================
SET LOCAL ROLE anon;

SELECT lives_ok(
    'SELECT public.health_check()',
    'Rolle anon darf health_check() ohne Fehler ausführen'
);

SELECT lives_ok(
    'SELECT public.health_check_v1()',
    'Rolle anon darf health_check_v1() ohne Fehler ausführen'
);

SELECT is(
    (public.health_check()->>'status')::text,
    'healthy',
    'health_check() liefert status = healthy'
);

SELECT is(
    (public.health_check()->>'version')::text,
    '1.0.0',
    'health_check() liefert version = 1.0.0'
);

SELECT is(
    (public.health_check()->>'database')::text,
    'connected',
    'health_check() liefert database = connected'
);

SELECT ok(
    (public.health_check()->>'timestamp') IS NOT NULL,
    'health_check() liefert einen gesetzten Zeitstempel'
);

SELECT matches(
    (public.health_check()->>'timestamp')::text,
    '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}',
    'Zeitstempel entspricht ISO 8601 UTC Format'
);

-- ============================================================================
-- 3. Ausführung & Berechtigungen für authentifizierten Benutzer ('authenticated')
-- ============================================================================
SET LOCAL ROLE authenticated;

SELECT lives_ok(
    'SELECT public.health_check()',
    'Rolle authenticated darf health_check() ohne Fehler ausführen'
);

SELECT lives_ok(
    'SELECT public.health_check_v1()',
    'Rolle authenticated darf health_check_v1() ohne Fehler ausführen'
);

SELECT is(
    (public.health_check()->>'status')::text,
    'healthy',
    'authenticated erhält status = healthy'
);

SELECT is(
    (public.health_check()->>'database')::text,
    'connected',
    'authenticated erhält database = connected'
);

SELECT is(
    (public.health_check_v1()->>'version')::text,
    '1.0.0',
    'health_check_v1() liefert identische Version 1.0.0'
);

SELECT * FROM finish();
ROLLBACK;
