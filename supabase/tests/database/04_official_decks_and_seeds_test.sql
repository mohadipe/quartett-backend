BEGIN;
SELECT plan(10);

-- 1. Prüfen, ob genau 4 offizielle Decks existieren (3 Basis + 1 Premium)
SELECT results_eq(
    'SELECT count(*)::integer FROM public.decks WHERE is_official = true',
    ARRAY[4],
    'Es müssen genau 4 offizielle Standard- und Premium-Decks existieren'
);

-- 2. Prüfen von Deck 1: Supercars 2026
SELECT results_eq(
    'SELECT slug, name, price_coins, is_official FROM public.decks WHERE id = ''00000000-0000-0000-0000-000000000001''',
    $$VALUES ('supercars-2026', 'Supercars 2026', 0, true)$$,
    'Deck 1 muss Supercars 2026 mit 0 Coins sein'
);

-- 3. Prüfen von Deck 2: Europäische Schmetterlinge
SELECT results_eq(
    'SELECT slug, name, price_coins, is_official FROM public.decks WHERE id = ''00000000-0000-0000-0000-000000000002''',
    $$VALUES ('butterflies-europe', 'Europäische Schmetterlinge', 200, true)$$,
    'Deck 2 muss Europäische Schmetterlinge mit 200 Coins sein'
);

-- 4. Prüfen von Deck 3: Klassische Feuerwehr
SELECT results_eq(
    'SELECT slug, name, price_coins, is_official FROM public.decks WHERE id = ''00000000-0000-0000-0000-000000000003''',
    $$VALUES ('feuerwehr-einsatz', 'Klassische Feuerwehr', 150, true)$$,
    'Deck 3 muss Klassische Feuerwehr mit 150 Coins sein'
);

-- 5. Prüfen von Deck 4: Prototypen-Hypercars (Premium)
SELECT results_eq(
    'SELECT slug, name, price_coins, is_official FROM public.decks WHERE id = ''00000000-0000-0000-0000-000000000004''',
    $$VALUES ('prototypen-hypercars', 'Prototypen-Hypercars', 750, true)$$,
    'Deck 4 muss Prototypen-Hypercars mit 750 Coins sein'
);

-- 6. Prüfen, dass veraltete Slugs nicht mehr existieren
SELECT is_empty(
    'SELECT id FROM public.decks WHERE slug = ''feuerwehr-einsatzfahrzeuge''',
    'Der veraltete Slug feuerwehr-einsatzfahrzeuge darf nicht existieren'
);

-- 7. Prüfen, dass die Attribut-Definitionen für alle 4 offiziellen Decks vorhanden sind
SELECT results_eq(
    'SELECT jsonb_array_length(attribute_definitions) FROM public.decks WHERE id = ''00000000-0000-0000-0000-000000000001''',
    ARRAY[5],
    'Supercars 2026 muss 5 Attribut-Definitionen besitzen'
);

SELECT results_eq(
    'SELECT jsonb_array_length(attribute_definitions) FROM public.decks WHERE id = ''00000000-0000-0000-0000-000000000002''',
    ARRAY[5],
    'Europäische Schmetterlinge muss 5 Attribut-Definitionen besitzen'
);

SELECT results_eq(
    'SELECT jsonb_array_length(attribute_definitions) FROM public.decks WHERE id = ''00000000-0000-0000-0000-000000000003''',
    ARRAY[5],
    'Klassische Feuerwehr muss 5 Attribut-Definitionen besitzen'
);

SELECT results_eq(
    'SELECT jsonb_array_length(attribute_definitions) FROM public.decks WHERE id = ''00000000-0000-0000-0000-000000000004''',
    ARRAY[5],
    'Prototypen-Hypercars muss 5 Attribut-Definitionen besitzen'
);

SELECT * FROM finish();
ROLLBACK;
