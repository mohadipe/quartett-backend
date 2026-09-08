BEGIN;
SELECT plan(15);

-- -----------------------------------------------------------------------------
-- 🧪 Smoke-Test Suite: Production Seed & Datenintegrität (STORY-010D / #14)
-- -----------------------------------------------------------------------------

-- 1. Prüfen, ob die 3 Standard-Launch-Decks existieren
SELECT results_eq(
    'SELECT slug FROM public.decks WHERE id = ''00000000-0000-0000-0000-000000000001''',
    $$VALUES ('supercars-2026')$$,
    'Standard-Deck 1 muss Supercars 2026 sein'
);

SELECT results_eq(
    'SELECT slug FROM public.decks WHERE id = ''00000000-0000-0000-0000-000000000002''',
    $$VALUES ('butterflies-europe')$$,
    'Standard-Deck 2 muss Europäische Schmetterlinge sein'
);

SELECT results_eq(
    'SELECT slug FROM public.decks WHERE id = ''00000000-0000-0000-0000-000000000003''',
    $$VALUES ('feuerwehr-einsatz')$$,
    'Standard-Deck 3 muss Klassische Feuerwehr sein'
);

-- 2. Preise und Offizieller Status der 3 Launch-Decks
SELECT results_eq(
    'SELECT price_coins, is_official FROM public.decks WHERE id = ''00000000-0000-0000-0000-000000000001''',
    $$VALUES (0, true)$$,
    'Supercars 2026 muss kostenlos (0 Coins) und offiziell sein'
);

SELECT results_eq(
    'SELECT price_coins, is_official FROM public.decks WHERE id = ''00000000-0000-0000-0000-000000000002''',
    $$VALUES (200, true)$$,
    'Europäische Schmetterlinge muss 200 Coins kosten und offiziell sein'
);

SELECT results_eq(
    'SELECT price_coins, is_official FROM public.decks WHERE id = ''00000000-0000-0000-0000-000000000003''',
    $$VALUES (150, true)$$,
    'Klassische Feuerwehr muss 150 Coins kosten und offiziell sein'
);

-- 3. Veralteter Slug 'feuerwehr-einsatzfahrzeuge' darf nicht existieren
SELECT is_empty(
    'SELECT id FROM public.decks WHERE slug = ''feuerwehr-einsatzfahrzeuge''',
    'Der Legacy-Slug feuerwehr-einsatzfahrzeuge darf nicht existieren'
);

-- 4. Attribut-Definitionen (exakt 5 pro Deck)
SELECT results_eq(
    'SELECT jsonb_array_length(attribute_definitions) FROM public.decks WHERE id = ''00000000-0000-0000-0000-000000000001''',
    ARRAY[5],
    'Supercars 2026 muss genau 5 Attribute definieren'
);

SELECT results_eq(
    'SELECT jsonb_array_length(attribute_definitions) FROM public.decks WHERE id = ''00000000-0000-0000-0000-000000000002''',
    ARRAY[5],
    'Europäische Schmetterlinge muss genau 5 Attribute definieren'
);

SELECT results_eq(
    'SELECT jsonb_array_length(attribute_definitions) FROM public.decks WHERE id = ''00000000-0000-0000-0000-000000000003''',
    ARRAY[5],
    'Klassische Feuerwehr muss genau 5 Attribute definieren'
);

-- 5. Kartenbestand der Standard-Decks (jeweils 8 Karten)
SELECT results_eq(
    'SELECT count(*)::int FROM public.cards WHERE deck_id = ''00000000-0000-0000-0000-000000000001''',
    ARRAY[8],
    'Supercars 2026 muss 8 verifizierte Karten besitzen'
);

SELECT results_eq(
    'SELECT count(*)::int FROM public.cards WHERE deck_id = ''00000000-0000-0000-0000-000000000002''',
    ARRAY[8],
    'Europäische Schmetterlinge muss 8 verifizierte Karten besitzen'
);

SELECT results_eq(
    'SELECT count(*)::int FROM public.cards WHERE deck_id = ''00000000-0000-0000-0000-000000000003''',
    ARRAY[8],
    'Klassische Feuerwehr muss 8 verifizierte Karten besitzen'
);

-- 6. Facade View v1_catalog_decks liefert alle 3 Launch-Decks
SELECT results_eq(
    'SELECT count(*)::int FROM public.v1_catalog_decks WHERE id IN (''00000000-0000-0000-0000-000000000001'', ''00000000-0000-0000-0000-000000000002'', ''00000000-0000-0000-0000-000000000003'')',
    ARRAY[3],
    'Facade View v1_catalog_decks muss alle 3 Standard-Decks bereitstellen'
);

-- 7. Verifikation des Seeding-Cleanup-Mechanismus
-- Test-Artefakt erzeugen und Bereinigung simulieren
INSERT INTO auth.users (id, email)
VALUES ('99999999-9999-9999-9999-999999999999', 'smoke_cleanup_tester@example.com');

UPDATE public.profiles
SET coins = 99999, username = 'fake_production_tester'
WHERE id = '99999999-9999-9999-9999-999999999999';

INSERT INTO public.matches (id, host_id, status)
VALUES ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '99999999-9999-9999-9999-999999999999', 'active');

-- Bereinigungs-Schritt aus seed_official_decks.sql anwenden
DELETE FROM public.matches WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
DELETE FROM public.profiles WHERE id = '99999999-9999-9999-9999-999999999999';

SELECT results_eq(
    'SELECT count(*)::int FROM public.profiles WHERE username = ''fake_production_tester''',
    ARRAY[0],
    'Nach Cleanup dürfen keinerlei Test-Accounts oder Fake-Statistiken verbleiben'
);

SELECT * FROM finish();
ROLLBACK;
