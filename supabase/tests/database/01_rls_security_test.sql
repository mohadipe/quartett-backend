BEGIN;
SELECT plan(11);

-- 1. Prüfen, ob alle relevanten Tabellen RLS (Row Level Security) aktiviert haben
SELECT results_eq(
    'SELECT relrowsecurity FROM pg_class WHERE relname = ''profiles'' AND relnamespace = ''public''::regnamespace',
    ARRAY[true],
    'Tabelle "profiles" muss RLS aktiviert haben'
);

SELECT results_eq(
    'SELECT relrowsecurity FROM pg_class WHERE relname = ''decks'' AND relnamespace = ''public''::regnamespace',
    ARRAY[true],
    'Tabelle "decks" muss RLS aktiviert haben'
);

SELECT results_eq(
    'SELECT relrowsecurity FROM pg_class WHERE relname = ''matches'' AND relnamespace = ''public''::regnamespace',
    ARRAY[true],
    'Tabelle "matches" muss RLS aktiviert haben'
);

SELECT results_eq(
    'SELECT relrowsecurity FROM pg_class WHERE relname = ''user_inventory_decks'' AND relnamespace = ''public''::regnamespace',
    ARRAY[true],
    'Tabelle "user_inventory_decks" muss RLS aktiviert haben'
);

SELECT results_eq(
    'SELECT relrowsecurity FROM pg_class WHERE relname = ''user_achievements'' AND relnamespace = ''public''::regnamespace',
    ARRAY[true],
    'Tabelle "user_achievements" muss RLS aktiviert haben'
);

SELECT results_eq(
    'SELECT relrowsecurity FROM pg_class WHERE relname = ''match_history'' AND relnamespace = ''public''::regnamespace',
    ARRAY[true],
    'Tabelle "match_history" muss RLS aktiviert haben'
);

-- 2. Prüfen, ob die exakten RLS Policies auf den Tabellen existieren
SELECT results_eq(
    'SELECT count(*)::int FROM pg_policies WHERE tablename = ''decks'' AND schemaname = ''public''',
    ARRAY[3],
    'Tabelle "decks" muss genau 3 RLS-Policies besitzen (Approved viewable, Create community, Edit draft)'
);

SELECT results_eq(
    'SELECT count(*)::int FROM pg_policies WHERE tablename = ''matches'' AND schemaname = ''public''',
    ARRAY[2],
    'Tabelle "matches" muss genau 2 RLS-Policies besitzen (Players view own, Players update own)'
);

SELECT results_eq(
    'SELECT count(*)::int FROM pg_policies WHERE tablename = ''profiles'' AND schemaname = ''public''',
    ARRAY[2],
    'Tabelle "profiles" muss genau 2 RLS-Policies besitzen (Public viewable, User update own)'
);

SELECT results_eq(
    'SELECT count(*)::int FROM pg_policies WHERE tablename = ''user_achievements'' AND schemaname = ''public''',
    ARRAY[2],
    'Tabelle "user_achievements" muss genau 2 RLS-Policies besitzen (Users see own, Users add own)'
);

SELECT results_eq(
    'SELECT count(*)::int FROM pg_policies WHERE tablename = ''match_history'' AND schemaname = ''public''',
    ARRAY[2],
    'Tabelle "match_history" muss genau 2 RLS-Policies besitzen (Anyone read, Authenticated insert)'
);

SELECT * FROM finish();
ROLLBACK;
