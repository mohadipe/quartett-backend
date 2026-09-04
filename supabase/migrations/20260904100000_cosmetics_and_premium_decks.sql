-- Migration: Coin-Senken, Premium-Decks & Kosmetische Upgrades (STORY-001)

-- 1. Erweiterung Profile um aktiven Kartenrücken
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS active_card_back_id TEXT DEFAULT 'default';

-- 2. Kosmetik-Inventar für Spieler
CREATE TABLE IF NOT EXISTS public.user_cosmetics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    item_type TEXT NOT NULL, -- 'card_back', 'card_foil', 'avatar_frame'
    item_id TEXT NOT NULL,   -- z.B. 'card_back_carbon', 'card_back_retro', 'card_back_gold', 'foil_holo'
    unlocked_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, item_type, item_id)
);

-- RLS für user_cosmetics
ALTER TABLE public.user_cosmetics ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'user_cosmetics' AND policyname = 'Users see only own cosmetics'
    ) THEN
        CREATE POLICY "Users see only own cosmetics"
        ON public.user_cosmetics FOR SELECT
        USING (auth.uid() = user_id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'user_cosmetics' AND policyname = 'Users can add to own cosmetics'
    ) THEN
        CREATE POLICY "Users can add to own cosmetics"
        ON public.user_cosmetics FOR INSERT
        WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

-- 3. Atomare Kauf-Funktion für kosmetische Upgrades
CREATE OR REPLACE FUNCTION public.rpc_purchase_cosmetic(
    p_item_type TEXT,
    p_item_id TEXT,
    p_price INT
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_current_coins INT;
    v_already_owned BOOLEAN;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    IF p_price < 0 THEN
        RAISE EXCEPTION 'Ungültiger Preis: %', p_price;
    END IF;

    -- 1. Prüfen, ob Item bereits freigeschaltet ist
    SELECT EXISTS (
        SELECT 1 FROM public.user_cosmetics
        WHERE user_id = v_user_id AND item_type = p_item_type AND item_id = p_item_id
    ) INTO v_already_owned;

    IF v_already_owned THEN
        SELECT coins INTO v_current_coins FROM public.profiles WHERE id = v_user_id;
        RETURN jsonb_build_object(
            'success', true,
            'already_owned', true,
            'coins', v_current_coins,
            'item_type', p_item_type,
            'item_id', p_item_id,
            'message', 'Bereits im Besitz'
        );
    END IF;

    -- 2. Münzguthaben prüfen
    SELECT coins INTO v_current_coins FROM public.profiles WHERE id = v_user_id;
    IF v_current_coins IS NULL OR v_current_coins < p_price THEN
        RAISE EXCEPTION 'Nicht genügend Münzen vorhanden (benötigt: %, vorhanden: %)', p_price, COALESCE(v_current_coins, 0);
    END IF;

    -- 3. Münzen abziehen
    UPDATE public.profiles
    SET coins = coins - p_price,
        updated_at = now()
    WHERE id = v_user_id
    RETURNING coins INTO v_current_coins;

    -- 4. Kosmetik-Item freischalten
    INSERT INTO public.user_cosmetics (user_id, item_type, item_id, unlocked_at)
    VALUES (v_user_id, p_item_type, p_item_id, now());

    -- Falls es sich um einen Kartenrücken handelt, diesen direkt als aktiven Kartenrücken setzen
    IF p_item_type = 'card_back' THEN
        UPDATE public.profiles
        SET active_card_back_id = p_item_id,
            updated_at = now()
        WHERE id = v_user_id;
    END IF;

    RETURN jsonb_build_object(
        'success', true,
        'already_owned', false,
        'coins', v_current_coins,
        'item_type', p_item_type,
        'item_id', p_item_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Aktualisierung der Gast-Merge-Funktion um user_cosmetics
CREATE OR REPLACE FUNCTION public.rpc_merge_guest_data(p_guest_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_new_user_id UUID := auth.uid();
    v_guest_coins INT;
    v_guest_xp INT;
    v_new_coins INT;
    v_new_xp INT;
    v_new_level INT;
BEGIN
    IF v_new_user_id IS NULL THEN
        RAISE EXCEPTION 'Nicht authentifiziert';
    END IF;

    IF v_new_user_id = p_guest_id THEN
        RETURN jsonb_build_object('success', true, 'message', 'IDs sind identisch, kein Merge nötig');
    END IF;

    -- 1. Gast-Profil Daten holen
    SELECT coins, xp INTO v_guest_coins, v_guest_xp
    FROM public.profiles
    WHERE id = p_guest_id;

    IF v_guest_coins IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Gast-Profil nicht gefunden');
    END IF;

    -- 2. Münzen und XP übertragen
    UPDATE public.profiles
    SET
        coins = coins + GREATEST(0, v_guest_coins - 100),
        xp = xp + v_guest_xp,
        level = 1 + FLOOR((xp + v_guest_xp) / 500),
        updated_at = now()
    WHERE id = v_new_user_id
    RETURNING coins, xp, level INTO v_new_coins, v_new_xp, v_new_level;

    -- 3. Matches umschreiben
    UPDATE public.matches SET host_id = v_new_user_id WHERE host_id = p_guest_id;
    UPDATE public.matches SET guest_id = v_new_user_id WHERE guest_id = p_guest_id;
    UPDATE public.matches SET winner_user_id = v_new_user_id WHERE winner_user_id = p_guest_id;

    -- 4. Achievements übertragen
    INSERT INTO public.user_achievements (user_id, achievement_id, unlocked_at)
    SELECT v_new_user_id, achievement_id, unlocked_at
    FROM public.user_achievements
    WHERE user_id = p_guest_id
    ON CONFLICT (user_id, achievement_id) DO NOTHING;

    -- 5. Inventar/Decks übertragen
    INSERT INTO public.user_inventory_decks (user_id, deck_id, unlocked_at)
    SELECT v_new_user_id, deck_id, unlocked_at
    FROM public.user_inventory_decks
    WHERE user_id = p_guest_id
    ON CONFLICT (user_id, deck_id) DO NOTHING;

    -- 6. Kosmetik-Items übertragen
    INSERT INTO public.user_cosmetics (user_id, item_type, item_id, unlocked_at)
    SELECT v_new_user_id, item_type, item_id, unlocked_at
    FROM public.user_cosmetics
    WHERE user_id = p_guest_id
    ON CONFLICT (user_id, item_type, item_id) DO NOTHING;

    -- 7. Gast-Profil löschen
    DELETE FROM public.profiles WHERE id = p_guest_id;

    RETURN jsonb_build_object(
        'success', true,
        'coins', v_new_coins,
        'xp', v_new_xp,
        'level', v_new_level
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Premium-Themendeck: Prototypen-Hypercars (750 Coins)
INSERT INTO public.decks (id, slug, name, category, description, price_coins, is_official, attribute_definitions)
VALUES (
    '00000000-0000-0000-0000-000000000004',
    'prototypen-hypercars',
    'Prototypen-Hypercars',
    'Fahrzeuge',
    'Zukunftsvisionen, Rekordjäger und Technologieträger der extremsten Konzept-Hypercars.',
    750,
    true,
    '[
        {"key": "power_hp", "label": "Systemleistung", "unit": "PS", "is_higher_better": true, "format": "integer", "icon_name": "flash"},
        {"key": "vmax", "label": "Höchstgeschwindigkeit", "unit": "km/h", "is_higher_better": true, "format": "integer", "icon_name": "flag"},
        {"key": "accel_0_100", "label": "0–100 km/h", "unit": "s", "is_higher_better": false, "format": "decimal", "icon_name": "speed"},
        {"key": "battery_kwh", "label": "Akkukapazität", "unit": "kWh", "is_higher_better": true, "format": "integer", "icon_name": "battery"},
        {"key": "weight_kg", "label": "Leergewicht", "unit": "kg", "is_higher_better": false, "format": "integer", "icon_name": "weight"}
    ]'::JSONB
) ON CONFLICT (id) DO UPDATE SET
    slug = EXCLUDED.slug,
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    description = EXCLUDED.description,
    price_coins = EXCLUDED.price_coins,
    is_official = EXCLUDED.is_official,
    attribute_definitions = EXCLUDED.attribute_definitions;
