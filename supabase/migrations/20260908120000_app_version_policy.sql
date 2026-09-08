-- =============================================================================
-- Migration: 20260908120000_app_version_policy.sql
-- Kontext: Issue #18 - App-Version-Policy & Zwangsupdate-Mechanismus
-- Gemäß arc42 Kapitel 8.12 (Contract Retirement & Multi-Stage)
-- =============================================================================

-- 1. Tabelle system_app_policies
CREATE TABLE IF NOT EXISTS public.system_app_policies (
    id TEXT PRIMARY KEY DEFAULT 'default',
    min_supported_version TEXT NOT NULL DEFAULT '0.1.0',
    latest_version TEXT NOT NULL DEFAULT '0.1.19',
    store_url TEXT NOT NULL DEFAULT 'https://play.google.com/store/apps/details?id=de.quartett.app.quartett_app',
    maintenance_mode BOOLEAN NOT NULL DEFAULT FALSE,
    maintenance_message TEXT DEFAULT 'Das Spiel befindet sich im Wartungsmodus. Bitte versuche es später noch einmal.',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Initialer Standard-Eintrag
INSERT INTO public.system_app_policies (id, min_supported_version, latest_version, store_url, maintenance_mode, maintenance_message)
VALUES (
    'default',
    '0.1.0',
    '0.1.19',
    'https://play.google.com/store/apps/details?id=de.quartett.app.quartett_app',
    false,
    'Das Spiel befindet sich im Wartungsmodus. Bitte versuche es später noch einmal.'
)
ON CONFLICT (id) DO NOTHING;

-- 2. Row Level Security (RLS)
ALTER TABLE public.system_app_policies ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Allow public read access on system_app_policies" ON public.system_app_policies;
CREATE POLICY "Allow public read access on system_app_policies"
    ON public.system_app_policies
    FOR SELECT
    TO anon, authenticated
    USING (true);

-- 3. Contract-Facade View (v1)
CREATE OR REPLACE VIEW public.v1_system_app_policies
WITH (security_invoker = true) AS
SELECT
    id,
    min_supported_version,
    latest_version,
    store_url,
    maintenance_mode,
    maintenance_message,
    created_at,
    updated_at
FROM public.system_app_policies;

GRANT SELECT ON public.system_app_policies TO anon, authenticated;
GRANT SELECT ON public.v1_system_app_policies TO anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.system_app_policies FROM anon, authenticated;
REVOKE INSERT, UPDATE, DELETE ON public.v1_system_app_policies FROM anon, authenticated;

-- 4. SemVer Parser Helper
CREATE OR REPLACE FUNCTION public.parse_semver(v TEXT)
RETURNS integer[]
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_clean TEXT;
    parts TEXT[];
    major INT := 0;
    minor INT := 0;
    patch INT := 0;
BEGIN
    IF v IS NULL OR trim(v) = '' THEN
        RETURN ARRAY[-1, -1, -1];
    END IF;

    -- 'v0.1.14' -> '0.1.14'
    v_clean := ltrim(trim(v), 'vV');
    -- '0.1.19+20' -> '0.1.19', '0.2.0-beta' -> '0.2.0'
    v_clean := split_part(split_part(v_clean, '+', 1), '-', 1);
    parts := string_to_array(v_clean, '.');

    IF array_length(parts, 1) >= 1 THEN
        major := COALESCE(NULLIF(regexp_replace(parts[1], '[^0-9]', '', 'g'), '')::int, 0);
    END IF;
    IF array_length(parts, 1) >= 2 THEN
        minor := COALESCE(NULLIF(regexp_replace(parts[2], '[^0-9]', '', 'g'), '')::int, 0);
    END IF;
    IF array_length(parts, 1) >= 3 THEN
        patch := COALESCE(NULLIF(regexp_replace(parts[3], '[^0-9]', '', 'g'), '')::int, 0);
    END IF;

    RETURN ARRAY[major, minor, patch];
EXCEPTION WHEN OTHERS THEN
    RETURN ARRAY[-1, -1, -1];
END;
$$;

-- 5. RPC check_app_version_v1
CREATE OR REPLACE FUNCTION public.check_app_version_v1(client_version TEXT)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    policy RECORD;
    c_semver INT[];
    min_semver INT[];
    latest_semver INT[];
    v_status TEXT;
    v_update_required BOOLEAN := false;
BEGIN
    SELECT * INTO policy
    FROM public.system_app_policies
    ORDER BY created_at DESC
    LIMIT 1;

    IF NOT FOUND THEN
        policy.min_supported_version := '0.1.0';
        policy.latest_version := '0.1.19';
        policy.store_url := 'https://play.google.com/store/apps/details?id=de.quartett.app.quartett_app';
        policy.maintenance_mode := false;
        policy.maintenance_message := 'Das Spiel befindet sich im Wartungsmodus. Bitte versuche es später noch einmal.';
    END IF;

    -- Wartungsmodus hat Vorrang
    IF policy.maintenance_mode IS TRUE THEN
        RETURN jsonb_build_object(
            'status', 'MAINTENANCE',
            'maintenance_mode', true,
            'maintenance_message', COALESCE(policy.maintenance_message, 'Das Spiel befindet sich im Wartungsmodus. Bitte versuche es später noch einmal.'),
            'client_version', client_version,
            'min_supported_version', policy.min_supported_version,
            'min_version', policy.min_supported_version,
            'latest_version', policy.latest_version,
            'store_url', policy.store_url,
            'update_required', false
        );
    END IF;

    c_semver := public.parse_semver(client_version);
    min_semver := public.parse_semver(policy.min_supported_version);
    latest_semver := public.parse_semver(policy.latest_version);

    IF c_semver < min_semver THEN
        v_status := 'UPDATE_REQUIRED';
        v_update_required := true;
    ELSIF c_semver < latest_semver THEN
        v_status := 'UPDATE_OPTIONAL';
        v_update_required := false;
    ELSE
        v_status := 'OK';
        v_update_required := false;
    END IF;

    RETURN jsonb_build_object(
        'status', v_status,
        'maintenance_mode', false,
        'maintenance_message', NULL,
        'client_version', client_version,
        'min_supported_version', policy.min_supported_version,
        'min_version', policy.min_supported_version,
        'latest_version', policy.latest_version,
        'store_url', policy.store_url,
        'update_required', v_update_required
    );
END;
$$;

-- 6. Unversionierter Wrapper
CREATE OR REPLACE FUNCTION public.check_app_version(client_version TEXT)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN public.check_app_version_v1(client_version);
END;
$$;

-- Berechtigungen
GRANT EXECUTE ON FUNCTION public.parse_semver(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_app_version_v1(TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_app_version(TEXT) TO anon, authenticated;
