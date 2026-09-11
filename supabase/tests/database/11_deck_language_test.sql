BEGIN;
SELECT plan(6);

-- 1. Prüfen, ob Spalte language auf public.decks existiert
SELECT has_column('public', 'decks', 'language', 'Spalte language existiert auf public.decks');

-- 2. Datentyp VARCHAR(5) prüfen
SELECT col_type_is('public', 'decks', 'language', 'character varying(5)', 'Spalte language ist VARCHAR(5)');

-- 3. Default 'de' prüfen
SELECT col_default_is('public', 'decks', 'language', 'de', 'Spalte language hat Default ''de''');

-- 4. Prüfen, ob community_decks View existiert
SELECT has_view('public', 'community_decks', 'View community_decks existiert');

-- 5. Prüfen, ob v1_catalog_decks die Spalte language projiziert
SELECT has_column('public', 'v1_catalog_decks', 'language', 'v1_catalog_decks projiziert language');

-- 6. Insert ohne Sprachangabe erhält Default 'de'
INSERT INTO public.decks (id, slug, name, category, description, is_official, is_community, attribute_definitions)
VALUES ('aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee', 'test-lang-deck', 'Lang Test', 'Fahrzeuge', 'Desc', false, true, '[]'::jsonb);

SELECT results_eq(
    'SELECT language FROM public.decks WHERE id = ''aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee''',
    'VALUES (''de''::character varying)',
    'Neues Deck ohne Sprachangabe erhält automatisch language = ''de'''
);

SELECT * FROM finish();
ROLLBACK;
