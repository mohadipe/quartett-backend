BEGIN;
SELECT plan(6);

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

-- 2. Test-Daten anlegen
INSERT INTO public.decks (slug, name, category, description, review_status, attribute_definitions)
VALUES 
    ('test-approved', 'Genehmigtes Deck', 'Test', 'Beschreibung', 'approved', '[]'::jsonb),
    ('test-draft', 'Entwurf Deck', 'Test', 'Beschreibung', 'draft', '[]'::jsonb);

-- 3. Prüfen, ob als anonymer Gast nur 'approved' Decks sichtbar sind
SET LOCAL ROLE anon;

SELECT results_eq(
    'SELECT slug FROM public.decks WHERE slug LIKE ''test-%''',
    'ARRAY[''test-approved''::text]',
    'Anonymer Nutzer darf NUR freigegebene Decks (approved) sehen, keine Entwürfe (draft)'
);

-- 4. Prüfen, dass Anonymus keine Decks ohne Erlaubnis manipulieren kann
SELECT throws_ok(
    'DELETE FROM public.decks WHERE slug = ''test-approved''',
    'Anonymer Nutzer darf keine Decks löschen'
);

SELECT * FROM finish();
ROLLBACK;
