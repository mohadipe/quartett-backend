-- Seed Data: Initial Launch Decks

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
) ON CONFLICT (slug) DO NOTHING;

-- Deck 2: Europäische Schmetterlinge
INSERT INTO public.decks (id, slug, name, category, description, price_coins, is_official, attribute_definitions)
VALUES (
    '00000000-0000-0000-0000-000000000002',
    'butterflies-europe',
    'Europäische Schmetterlinge',
    'Natur & Tiere',
    'Die faszinierendsten Tag- und Nachtfalter unserer Heimat (Open-Data Deck).',
    0,
    true,
    '[
        {"key": "wingspan_mm", "label": "Flügelspannweite", "unit": "mm", "is_higher_better": true, "format": "integer", "icon_name": "wings"},
        {"key": "lifespan_days", "label": "Lebenserwartung", "unit": "Tage", "is_higher_better": true, "format": "integer", "icon_name": "clock"},
        {"key": "altitude_max_m", "label": "Max. Höhenlage", "unit": "m", "is_higher_better": true, "format": "integer", "icon_name": "mountain"},
        {"key": "caterpillar_duration_weeks", "label": "Raupen-Entwicklung", "unit": "Wochen", "is_higher_better": false, "format": "decimal", "icon_name": "bug"},
        {"key": "flight_speed_kmh", "label": "Fluggeschwindigkeit", "unit": "km/h", "is_higher_better": true, "format": "integer", "icon_name": "speed"}
    ]'::JSONB
) ON CONFLICT (slug) DO NOTHING;
