BEGIN;
SELECT plan(22);

-- 1. Tabellen- und Spalten-Existenz prüfen
SELECT has_table('public', 'system_app_policies', 'Tabelle system_app_policies muss existieren');
SELECT has_column('public', 'system_app_policies', 'id', 'Spalte id muss existieren');
SELECT has_column('public', 'system_app_policies', 'min_supported_version', 'Spalte min_supported_version muss existieren');
SELECT has_column('public', 'system_app_policies', 'latest_version', 'Spalte latest_version muss existieren');
SELECT has_column('public', 'system_app_policies', 'store_url', 'Spalte store_url muss existieren');
SELECT has_column('public', 'system_app_policies', 'maintenance_mode', 'Spalte maintenance_mode muss existieren');

-- 2. Facade-View v1_system_app_policies prüfen
SELECT has_view('public', 'v1_system_app_policies', 'Facade-View v1_system_app_policies muss existieren');

-- 3. RPC-Funktionen prüfen
SELECT has_function('public', 'check_app_version', ARRAY['text'], 'RPC check_app_version(text) muss existieren');
SELECT has_function('public', 'check_app_version_v1', ARRAY['text'], 'RPC check_app_version_v1(text) muss existieren');

-- 4. Initialen Policy-Eintrag für kontrollierte Tests anlegen
DELETE FROM public.system_app_policies;
INSERT INTO public.system_app_policies (id, min_supported_version, latest_version, store_url, maintenance_mode, maintenance_message)
VALUES ('default', '0.2.0', '0.3.0', 'https://play.google.com/store/apps/details?id=de.quartett.app.quartett_app', false, 'Wartungsarbeiten laufen.');

-- 5. Lese- und Schreibzugriff für 'anon' testen (RLS)
SET LOCAL ROLE anon;

SELECT lives_ok(
    'SELECT id, min_supported_version, latest_version, store_url, maintenance_mode FROM public.system_app_policies LIMIT 1',
    'Anon-Rolle darf system_app_policies lesen'
);

SELECT lives_ok(
    'SELECT id, min_supported_version, latest_version, store_url, maintenance_mode FROM public.v1_system_app_policies LIMIT 1',
    'Anon-Rolle darf Facade-View v1_system_app_policies lesen'
);

SELECT throws_ok(
    'INSERT INTO public.system_app_policies (id, min_supported_version, latest_version, store_url) VALUES (''hacked'', ''1.0.0'', ''1.0.0'', ''bad'')',
    '42501',
    NULL,
    'Anon-Rolle darf KEINE Policies einfügen'
);

SELECT throws_ok(
    'UPDATE public.system_app_policies SET min_supported_version = ''9.9.9'' WHERE id = ''default''',
    '42501',
    NULL,
    'Anon-Rolle darf KEINE Policies aktualisieren'
);

-- 6. RPC-Aufrufe mit 'anon' und 'authenticated' testen
SELECT is(
    (public.check_app_version('0.1.10')->>'status')::text,
    'UPDATE_REQUIRED',
    'Version 0.1.10 unter min 0.2.0 muss UPDATE_REQUIRED liefern'
);

SELECT is(
    (public.check_app_version('0.1.10')->>'update_required')::boolean,
    true,
    'update_required muss true sein bei 0.1.10'
);

SELECT is(
    (public.check_app_version('0.2.0')->>'status')::text,
    'UPDATE_OPTIONAL',
    'Version 0.2.0 zwischen min 0.2.0 und latest 0.3.0 muss UPDATE_OPTIONAL liefern'
);

SELECT is(
    (public.check_app_version('0.3.0')->>'status')::text,
    'OK',
    'Version 0.3.0 auf latest Stand muss OK liefern'
);

SELECT is(
    (public.check_app_version('0.3.5')->>'status')::text,
    'OK',
    'Version 0.3.5 über latest Stand muss OK liefern'
);

-- SemVer mit Build-Metadaten testen (z. B. 0.1.19+20)
SELECT is(
    (public.check_app_version('0.1.19+20')->>'status')::text,
    'UPDATE_REQUIRED',
    'Version 0.1.19+20 unter min 0.2.0 muss UPDATE_REQUIRED liefern'
);

-- 7. Wartungsmodus testen
SET LOCAL ROLE postgres;
UPDATE public.system_app_policies SET maintenance_mode = true WHERE id = 'default';

SET LOCAL ROLE anon;
SELECT is(
    (public.check_app_version('0.3.0')->>'status')::text,
    'MAINTENANCE',
    'Bei aktivem Wartungsmodus muss status MAINTENANCE zurückgegeben werden'
);

SELECT is(
    (public.check_app_version('0.3.0')->>'maintenance_mode')::boolean,
    true,
    'maintenance_mode Flag muss true sein'
);

-- Ungültige / Leere Version testen
SELECT is(
    (public.check_app_version(NULL)->>'status')::text,
    'MAINTENANCE',
    'Auch bei NULL-Version hat Wartungsmodus Vorrang'
);

SELECT * FROM finish();
ROLLBACK;
