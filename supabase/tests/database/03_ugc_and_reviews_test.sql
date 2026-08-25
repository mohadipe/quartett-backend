BEGIN;
SELECT plan(11);

-- 1. Prüfen, ob die neue Tabelle "deck_reviews" RLS aktiviert hat
SELECT results_eq(
    'SELECT relrowsecurity FROM pg_class WHERE relname = ''deck_reviews'' AND relnamespace = ''public''::regnamespace',
    ARRAY[true],
    'Tabelle "deck_reviews" muss RLS aktiviert haben'
);

-- 2. Prüfen, ob die exakten RLS Policies auf "deck_reviews" existieren
SELECT results_eq(
    'SELECT count(*)::int FROM pg_policies WHERE tablename = ''deck_reviews'' AND schemaname = ''public''',
    ARRAY[4],
    'Tabelle "deck_reviews" muss genau 4 RLS-Policies besitzen (Select, Insert, Update, Delete)'
);

-- 3. Prüfen, ob die Policies auf "cards" nun 4 betragen (1 alte Select + 3 neue Write-Policies)
SELECT results_eq(
    'SELECT count(*)::int FROM pg_policies WHERE tablename = ''cards'' AND schemaname = ''public''',
    ARRAY[4],
    'Tabelle "cards" muss genau 4 RLS-Policies besitzen (Select, Insert, Update, Delete)'
);

-- 4. Test-User anlegen
INSERT INTO auth.users (id, email)
VALUES ('22222222-2222-2222-2222-222222222222', 'creator_user@example.com');

-- 5. Test für Draft-Deck Erstellung und Cards-Einfügung unter RLS
SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" TO '22222222-2222-2222-2222-222222222222';

-- Deck anlegen als draft
INSERT INTO public.decks (id, slug, name, category, description, is_official, is_community, creator_id, review_status, attribute_definitions)
VALUES (
    '33333333-3333-3333-3333-333333333333',
    'my-custom-deck',
    'My Custom Deck',
    'Fahrzeuge',
    'A custom vehicle deck',
    false,
    true,
    '22222222-2222-2222-2222-222222222222',
    'draft',
    '[]'::jsonb
);

-- Versuchen, eine Karte einzufügen (sollte dank der neuen Policy klappen)
SELECT lives_ok(
    $$
    INSERT INTO public.cards (id, deck_id, code, name, subtitle, attributes)
    VALUES ('44444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333', 'A1', 'Test Card', 'Sub', '{}'::jsonb)
    $$,
    'Ersteller eines Draft-Decks muss Karten einfügen dürfen'
);

-- Versuchen, Karte zu aktualisieren
SELECT lives_ok(
    $$
    UPDATE public.cards
    SET name = 'Updated Test Card'
    WHERE id = '44444444-4444-4444-4444-444444444444'
    $$,
    'Ersteller eines Draft-Decks muss Karten aktualisieren dürfen'
);

-- Versuchen, Draft-Deck auf approved zu aktualisieren (veröffentlichen)
SELECT lives_ok(
    $$
    UPDATE public.decks
    SET review_status = 'approved'
    WHERE id = '33333333-3333-3333-3333-333333333333'
    $$,
    'Ersteller muss sein eigenes Draft-Deck auf approved aktualisieren dürfen (Veröffentlichung)'
);

-- ZWEITER SPEICHER-ZYKLUS (Editieren & Erneutes Speichern/Veröffentlichen)
-- 1. Deck Metadaten erneut als Draft upserten (mit demselben ID und Slug)
SELECT lives_ok(
    $$
    INSERT INTO public.decks (id, slug, name, category, description, is_official, is_community, creator_id, review_status, attribute_definitions)
    VALUES (
        '33333333-3333-3333-3333-333333333333',
        'my-custom-deck',
        'My Custom Deck',
        'Fahrzeuge',
        'A custom vehicle deck updated',
        false,
        true,
        '22222222-2222-2222-2222-222222222222',
        'draft',
        '[]'::jsonb
    )
    ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        review_status = EXCLUDED.review_status
    $$,
    'Erneutes Upserten des Decks als Draft muss klappen'
);

-- 2. Bestehende Karten löschen
SELECT lives_ok(
    $$
    DELETE FROM public.cards
    WHERE deck_id = '33333333-3333-3333-3333-333333333333'
    $$,
    'Löschen der Karten des Draft-Decks muss klappen'
);

-- 3. Neue Karten einfügen
SELECT lives_ok(
    $$
    INSERT INTO public.cards (id, deck_id, code, name, subtitle, attributes)
    VALUES ('44444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333', 'A1', 'Test Card', 'Sub', '{}'::jsonb)
    $$,
    'Erneutes Einfügen der Karten des Draft-Decks muss klappen'
);

-- 4. Deck wieder veröffentlichen
SELECT lives_ok(
    $$
    UPDATE public.decks
    SET review_status = 'approved'
    WHERE id = '33333333-3333-3333-3333-333333333333'
    $$,
    'Erneutes Veröffentlichen des Decks muss klappen'
);

-- Versuchen, Draft-Deck zu löschen
SELECT lives_ok(
    $$
    -- Zuerst wieder auf draft setzen, damit das Löschen erlaubt ist
    UPDATE public.decks SET review_status = 'draft' WHERE id = '33333333-3333-3333-3333-333333333333';
    DELETE FROM public.decks
    WHERE id = '33333333-3333-3333-3333-333333333333'
    $$,
    'Ersteller muss sein eigenes Draft-Deck löschen dürfen'
);

SELECT * FROM finish();
ROLLBACK;
