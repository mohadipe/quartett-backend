-- Seed Data: Initial Launch Decks

-- 0. Cleanup eventueller Altlasten oder abweichender Slugs
DELETE FROM public.decks 
WHERE slug = 'feuerwehr-einsatzfahrzeuge' 
  AND id != '00000000-0000-0000-0000-000000000003';

-- Deck 1: Supercars 2026
INSERT INTO public.decks (id, slug, name, category, description, price_coins, is_official, attribute_definitions)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'supercars-2026',
    'Supercars 2026',
    'Fahrzeuge',
    'Die schnellsten und spektakulärsten Hypersportwagen der Welt.',
    0,
    true,
    '[
        {"key": "power_hp", "label": "Leistung", "unit": "PS", "is_higher_better": true, "format": "integer", "icon_name": "flash"},
        {"key": "vmax", "label": "Höchstgeschwindigkeit", "unit": "km/h", "is_higher_better": true, "format": "integer", "icon_name": "flag"},
        {"key": "accel_0_100", "label": "0–100 km/h", "unit": "s", "is_higher_better": false, "format": "decimal", "icon_name": "speed"},
        {"key": "displacement_ccm", "label": "Hubraum", "unit": "ccm", "is_higher_better": true, "format": "integer", "icon_name": "engine"},
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

-- Deck 2: Europäische Schmetterlinge
INSERT INTO public.decks (id, slug, name, category, description, price_coins, is_official, attribute_definitions)
VALUES (
    '00000000-0000-0000-0000-000000000002',
    'butterflies-europe',
    'Europäische Schmetterlinge',
    'Natur & Tiere',
    'Die faszinierendsten Tag- und Nachtfalter unserer Heimat (Open-Data Deck).',
    200,
    true,
    '[
        {"key": "wingspan_mm", "label": "Flügelspannweite", "unit": "mm", "is_higher_better": true, "format": "integer", "icon_name": "wings"},
        {"key": "lifespan_days", "label": "Lebenserwartung", "unit": "Tage", "is_higher_better": true, "format": "integer", "icon_name": "clock"},
        {"key": "altitude_max_m", "label": "Max. Höhenlage", "unit": "m", "is_higher_better": true, "format": "integer", "icon_name": "mountain"},
        {"key": "caterpillar_duration_weeks", "label": "Raupen-Entwicklung", "unit": "Wochen", "is_higher_better": false, "format": "decimal", "icon_name": "bug"},
        {"key": "flight_speed_kmh", "label": "Fluggeschwindigkeit", "unit": "km/h", "is_higher_better": true, "format": "integer", "icon_name": "speed"}
    ]'::JSONB
) ON CONFLICT (id) DO UPDATE SET
    slug = EXCLUDED.slug,
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    description = EXCLUDED.description,
    price_coins = EXCLUDED.price_coins,
    is_official = EXCLUDED.is_official,
    attribute_definitions = EXCLUDED.attribute_definitions;

-- Deck 3: Klassische Feuerwehr
INSERT INTO public.decks (id, slug, name, category, description, price_coins, is_official, attribute_definitions)
VALUES (
    '00000000-0000-0000-0000-000000000003',
    'feuerwehr-einsatz',
    'Klassische Feuerwehr',
    'Fahrzeuge',
    'Die schlagkräftigsten Lösch-, Rettungs- und Sonderfahrzeuge der modernen Feuerwehr.',
    150,
    true,
    '[
        {"key": "power_hp", "label": "Motorleistung", "unit": "PS", "is_higher_better": true, "format": "integer", "icon_name": "flash"},
        {"key": "water_tank_l", "label": "Löschwassertank", "unit": "l", "is_higher_better": true, "format": "integer", "icon_name": "local_fire_department"},
        {"key": "pump_capacity_lpm", "label": "Pumpenleistung", "unit": "l/min", "is_higher_better": true, "format": "integer", "icon_name": "water_drop"},
        {"key": "rescue_height_m", "label": "Rettungshöhe", "unit": "m", "is_higher_better": true, "format": "integer", "icon_name": "height"},
        {"key": "crew_size", "label": "Besatzung", "unit": "Personen", "is_higher_better": true, "format": "integer", "icon_name": "group"}
    ]'::JSONB
) ON CONFLICT (id) DO UPDATE SET
    slug = EXCLUDED.slug,
    name = EXCLUDED.name,
    category = EXCLUDED.category,
    description = EXCLUDED.description,
    price_coins = EXCLUDED.price_coins,
    is_official = EXCLUDED.is_official,
    attribute_definitions = EXCLUDED.attribute_definitions;

-- Deck 4: Prototypen-Hypercars (Premium)
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

