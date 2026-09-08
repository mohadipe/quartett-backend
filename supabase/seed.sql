-- Seed Data: Initial Launch Decks & Cards

-- 0. Cleanup eventueller Altlasten oder abweichender Slugs
DELETE FROM public.decks 
WHERE slug = 'feuerwehr-einsatzfahrzeuge' 
  AND id != '00000000-0000-0000-0000-000000000003';

-- -----------------------------------------------------------------------------
-- 1. Decks
-- -----------------------------------------------------------------------------

-- Deck 1: Supercars 2026
INSERT INTO public.decks (
    id, slug, name, category, description, cover_image_url, price_coins, is_official, is_community, review_status, attribute_definitions
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'supercars-2026',
    'Supercars 2026',
    'Fahrzeuge',
    'Die schnellsten und spektakulärsten Hypersportwagen der Welt.',
    'assets/decks/supercars/cover.jpg',
    0,
    true,
    false,
    'approved',
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
    cover_image_url = EXCLUDED.cover_image_url,
    price_coins = EXCLUDED.price_coins,
    is_official = EXCLUDED.is_official,
    is_community = EXCLUDED.is_community,
    review_status = EXCLUDED.review_status,
    attribute_definitions = EXCLUDED.attribute_definitions;

-- Deck 2: Europäische Schmetterlinge
INSERT INTO public.decks (
    id, slug, name, category, description, cover_image_url, price_coins, is_official, is_community, review_status, attribute_definitions
) VALUES (
    '00000000-0000-0000-0000-000000000002',
    'butterflies-europe',
    'Europäische Schmetterlinge',
    'Natur & Tiere',
    'Die faszinierendsten Tag- und Nachtfalter unserer Heimat (Open-Data Deck).',
    'assets/decks/butterflies/cover.jpg',
    200,
    true,
    false,
    'approved',
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
    cover_image_url = EXCLUDED.cover_image_url,
    price_coins = EXCLUDED.price_coins,
    is_official = EXCLUDED.is_official,
    is_community = EXCLUDED.is_community,
    review_status = EXCLUDED.review_status,
    attribute_definitions = EXCLUDED.attribute_definitions;

-- Deck 3: Klassische Feuerwehr
INSERT INTO public.decks (
    id, slug, name, category, description, cover_image_url, price_coins, is_official, is_community, review_status, attribute_definitions
) VALUES (
    '00000000-0000-0000-0000-000000000003',
    'feuerwehr-einsatz',
    'Klassische Feuerwehr',
    'Fahrzeuge',
    'Die schlagkräftigsten Lösch-, Rettungs- und Sonderfahrzeuge der modernen Feuerwehr.',
    'assets/decks/feuerwehr/cover.jpg',
    150,
    true,
    false,
    'approved',
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
    cover_image_url = EXCLUDED.cover_image_url,
    price_coins = EXCLUDED.price_coins,
    is_official = EXCLUDED.is_official,
    is_community = EXCLUDED.is_community,
    review_status = EXCLUDED.review_status,
    attribute_definitions = EXCLUDED.attribute_definitions;

-- Deck 4: Prototypen-Hypercars (Premium)
INSERT INTO public.decks (
    id, slug, name, category, description, cover_image_url, price_coins, is_official, is_community, review_status, attribute_definitions
) VALUES (
    '00000000-0000-0000-0000-000000000004',
    'prototypen-hypercars',
    'Prototypen-Hypercars',
    'Fahrzeuge',
    'Zukunftsvisionen, Rekordjäger und Technologieträger der extremsten Konzept-Hypercars.',
    'assets/decks/prototypen/cover.jpg',
    750,
    true,
    false,
    'approved',
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
    cover_image_url = EXCLUDED.cover_image_url,
    price_coins = EXCLUDED.price_coins,
    is_official = EXCLUDED.is_official,
    is_community = EXCLUDED.is_community,
    review_status = EXCLUDED.review_status,
    attribute_definitions = EXCLUDED.attribute_definitions;

-- -----------------------------------------------------------------------------
-- 2. Karten-Katalog für offizielle Decks (public.cards)
-- -----------------------------------------------------------------------------

-- Deck 1: Supercars 2026 Karten
INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000001', 'A1', 'Stuttgart GT-Aero', '4.0L Boxer Saugmotor', 'assets/decks/supercars/a1_gt3rs.jpg', 'Sein riesiger Schwanenhals-Heckflügel erzeugt 860 kg Abtrieb bei 285 km/h.', '{"power_hp": 525, "vmax": 296, "accel_0_100": 3.2, "displacement_ccm": 3996, "weight_kg": 1450}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000001', 'A2', 'Maranello Rosso Hybrid', '4.0L V8 Bi-Turbo Hybrid', 'assets/decks/supercars/a2_maranello_xx.jpg', 'Kombiniert einen bärenstarken Biturbo-V8 mit drei Elektromotoren zu Allradantrieb.', '{"power_hp": 1030, "vmax": 340, "accel_0_100": 2.3, "displacement_ccm": 3990, "weight_kg": 1570}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000001', 'A3', 'Apex Carbon Sprint', 'Leichtbau-V8 Mittelmotor', 'assets/decks/supercars/a3_apex_750s.jpg', 'Dank Carbon-Monocoque wiegt er trocken unter 1.300 kg – ein echtes Rennstrecken-Tool.', '{"power_hp": 750, "vmax": 332, "accel_0_100": 2.8, "displacement_ccm": 3994, "weight_kg": 1281}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000001', 'A4', 'Toro Bull V12', '6.5L V12 Plug-In-Hybrid', 'assets/decks/supercars/a4_toro_v12.jpg', 'Dreht als frei saugender Zwölfzylinder kreischend bis auf unglaubliche 9.500 U/min.', '{"power_hp": 1015, "vmax": 350, "accel_0_100": 2.5, "displacement_ccm": 6498, "weight_kg": 1772}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000001', 'B1', 'Nordic Streamline 500', '5.0L V8 Bi-Turbo High-Speed', 'assets/decks/supercars/b1_nordic_500.jpg', 'Gebaut für die Jagd nach der 500-km/h-Marke mit extrem niedrigem Luftwiderstandsbeiwert.', '{"power_hp": 1600, "vmax": 500, "accel_0_100": 2.6, "displacement_ccm": 5000, "weight_kg": 1390}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000001', 'B2', 'Alsace Grand V16', '8.3L V16 Saugmotor Hybrid', 'assets/decks/supercars/b2_alsace_v16.jpg', 'Der 1 Meter lange V16-Motor wurde in Kooperation mit Cosworth entwickelt.', '{"power_hp": 1800, "vmax": 445, "accel_0_100": 2.0, "displacement_ccm": 8300, "weight_kg": 1995}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000001', 'B3', 'Volt Hyper EV', 'Voll-Elektrisches Hypercar', 'assets/decks/supercars/b3_volt_nevera.jpg', 'Vier radindividuelle Elektromotoren ermöglichen ein perfektes Torque Vectoring in Millisekunden.', '{"power_hp": 1914, "vmax": 412, "accel_0_100": 1.81, "displacement_ccm": 0, "weight_kg": 2150}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000001', 'B4', 'Modena Sculpted V12', '6.0L V12 Biturbo Kunstwerk', 'assets/decks/supercars/b4_modena_utopia.jpg', 'Ein seltenes Meisterwerk automobiler Handwerkskunst mit klassischer 7-Gang-Handschaltung.', '{"power_hp": 864, "vmax": 354, "accel_0_100": 2.9, "displacement_ccm": 5980, "weight_kg": 1280}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

-- Deck 2: Europäische Schmetterlinge Karten
INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000002', 'A1', 'Schwalbenschwanz', 'Papilio machaon', 'assets/decks/butterflies/a1_schwalbenschwanz.jpg', 'Er gehört zu den größten und farbenprächtigsten Tagfaltern Mitteleuropas.', '{"wingspan_mm": 75, "lifespan_days": 25, "altitude_max_m": 2000, "caterpillar_duration_weeks": 4.5, "flight_speed_kmh": 25}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000002', 'A2', 'Tagpfauenauge', 'Aglais io', 'assets/decks/butterflies/a2_tagpfauenauge.jpg', 'Die großen Augenflecke auf seinen Flügeln verwirren und schrecken Fressfeinde wie Vögel ab.', '{"wingspan_mm": 60, "lifespan_days": 330, "altitude_max_m": 2500, "caterpillar_duration_weeks": 3.5, "flight_speed_kmh": 20}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000002', 'A3', 'Trauermantel', 'Nymphalis antiopa', 'assets/decks/butterflies/a3_trauermantel.jpg', 'Überwintert geschützt als ausgewachsener Falter und erscheint bereits an den ersten sonnigen Märztagen.', '{"wingspan_mm": 75, "lifespan_days": 300, "altitude_max_m": 2000, "caterpillar_duration_weeks": 5.0, "flight_speed_kmh": 22}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000002', 'A4', 'Zitronenfalter', 'Gonepteryx rhamni', 'assets/decks/butterflies/a4_zitronenfalter.jpg', 'Besitzt körpereigenes Frostschutzmittel (Glycerin) und übersteht Temperaturen bis minus 20 Grad Celsius.', '{"wingspan_mm": 55, "lifespan_days": 360, "altitude_max_m": 2800, "caterpillar_duration_weeks": 4.0, "flight_speed_kmh": 18}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000002', 'B1', 'Wiener Nachtpfauenauge', 'Saturnia pyri', 'assets/decks/butterflies/b1_wiener_pfauenauge.jpg', 'Der größte Schmetterling Europas mit einer gewaltigen Spannweite von bis zu 15 cm.', '{"wingspan_mm": 150, "lifespan_days": 10, "altitude_max_m": 1200, "caterpillar_duration_weeks": 8.0, "flight_speed_kmh": 18}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000002', 'B2', 'Totenkopfschwärmer', 'Acherontia atropos', 'assets/decks/butterflies/b2_totenkopffalter.jpg', 'Kann bei Gefahr hörbare Pfeifgeräusche erzeugen und stiehlt Honig aus Bienenstöcken.', '{"wingspan_mm": 130, "lifespan_days": 45, "altitude_max_m": 3000, "caterpillar_duration_weeks": 6.5, "flight_speed_kmh": 54}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000002', 'B3', 'Taubenschwänzchen', 'Macroglossum stellatarum', 'assets/decks/butterflies/b3_taubenschwaenzchen.jpg', 'Wird oft mit einem Kolibri verwechselt, da es mit 80 Flügelschlägen pro Sekunde vor Blüten in der Luft steht.', '{"wingspan_mm": 45, "lifespan_days": 120, "altitude_max_m": 3000, "caterpillar_duration_weeks": 3.0, "flight_speed_kmh": 80}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000002', 'B4', 'Apollofalter', 'Parnassius apollo', 'assets/decks/butterflies/b4_apollofalter.jpg', 'Ein streng geschützter Gebirgsbewohner mit samtig weißen Flügeln und roten Augenflecken.', '{"wingspan_mm": 80, "lifespan_days": 21, "altitude_max_m": 3500, "caterpillar_duration_weeks": 5.5, "flight_speed_kmh": 20}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

-- Deck 3: Klassische Feuerwehr Karten
INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000003', 'A1', 'Hilfeleistungslöschgruppenfahrzeug (HLF 20)', 'Allrounder der Berufsfeuerwehr', 'assets/decks/feuerwehr/a1_hlf20.jpg', 'Das HLF 20 ist das Schweizer Taschenmesser der Feuerwehr und rückt bei fast jedem Alarm als erstes aus.', '{"power_hp": 320, "water_tank_l": 2000, "pump_capacity_lpm": 2000, "rescue_height_m": 8, "crew_size": 9}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000003', 'A2', 'Drehleiter mit Korb (DLAK 23/12)', 'Höhenrettung & Brandbekämpfung', 'assets/decks/feuerwehr/a2_dlak2312.jpg', 'Der Rettungskorb erreicht eine Nennrettungshöhe von 23 Metern bei 12 Metern Ausladung – bis zum 7. Stockwerk!', '{"power_hp": 300, "water_tank_l": 0, "pump_capacity_lpm": 1500, "rescue_height_m": 32, "crew_size": 3}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000003', 'A3', 'Tanklöschfahrzeug (TLF 4000)', 'Schwere Waldbrand- & Autobahnbekämpfung', 'assets/decks/feuerwehr/a3_tlf4000.jpg', 'Besitzt einen Dachmonitor, der während der Fahrt Wasser oder Schaum bis zu 70 Meter weit werfen kann.', '{"power_hp": 340, "water_tank_l": 4000, "pump_capacity_lpm": 3000, "rescue_height_m": 4, "crew_size": 3}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000003', 'A4', 'Rüstwagen (RW 2)', 'Schwere technische Hilfeleistung', 'assets/decks/feuerwehr/a4_rw2.jpg', 'Mit seiner 50-kN-Seilwinde und hydraulischem Schneidgerät befreit er Insassen aus verunfallten Lkw.', '{"power_hp": 290, "water_tank_l": 0, "pump_capacity_lpm": 0, "rescue_height_m": 5, "crew_size": 3}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000003', 'B1', 'Flugfeldlöschfahrzeug (FLF Panther 8x8)', 'Das 1.400 PS Giganten-Fahrzeug', 'assets/decks/feuerwehr/b1_panther8x8.jpg', 'Beschleunigt trotz über 50 Tonnen Gewicht in unter 25 Sekunden von 0 auf 80 km/h.', '{"power_hp": 1400, "water_tank_l": 12500, "pump_capacity_lpm": 10000, "rescue_height_m": 16, "crew_size": 4}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000003', 'B2', 'Großtanklöschfahrzeug (GTLF 10000)', 'Maximaler Wassernachschub', 'assets/decks/feuerwehr/b2_gtlf10000.jpg', 'Führt 10.000 Liter Wasser mit – ausreichend, um einen Vollbrand in abgelegenen Industriegebieten abzusichern.', '{"power_hp": 480, "water_tank_l": 10000, "pump_capacity_lpm": 6000, "rescue_height_m": 4, "crew_size": 3}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000003', 'B3', 'Einsatzleitwagen 2 (ELW 2)', 'Rollende Führungszentrale', 'assets/decks/feuerwehr/b3_elw2.jpg', 'Verfügt über Funkarbeitsplätze, Satelliteninternet und einen eigenen Besprechungsraum für Großschadenslagen.', '{"power_hp": 220, "water_tank_l": 0, "pump_capacity_lpm": 0, "rescue_height_m": 4, "crew_size": 6}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;

INSERT INTO public.cards (deck_id, code, name, subtitle, image_url, fun_fact, attributes)
VALUES ('00000000-0000-0000-0000-000000000003', 'B4', 'Wechselladerfahrzeug mit AB-Gefahrgut (WLF)', 'Spezialeinsatz bei Chemie- & Gefahrstoffunfällen', 'assets/decks/feuerwehr/b4_wlf_gefahrgut.jpg', 'Der Abrollbehälter führt Vollschutzanzüge, Chemikalienpumpen und Messgeräte für atomare, biologische und chemische Gefahren mit.', '{"power_hp": 440, "water_tank_l": 0, "pump_capacity_lpm": 0, "rescue_height_m": 4, "crew_size": 2}'::jsonb)
ON CONFLICT (deck_id, code) DO UPDATE SET name = EXCLUDED.name, subtitle = EXCLUDED.subtitle, image_url = EXCLUDED.image_url, fun_fact = EXCLUDED.fun_fact, attributes = EXCLUDED.attributes;


