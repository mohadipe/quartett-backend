-- ============================================================================
-- Migration: Backend Healthcheck RPC & Supabase Observability (Issue #26)
-- Datum: 2026-09-08
-- Idempotente Bereitstellung von public.health_check_v1() und public.health_check()
-- ============================================================================

-- 1. Versionierte Healthcheck-Funktion public.health_check_v1()
CREATE OR REPLACE FUNCTION public.health_check_v1()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object(
    'status', 'healthy',
    'timestamp', to_char(now() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'version', '1.0.0',
    'database', 'connected'
  );
$$;

-- 2. Unversionierter Alias public.health_check() für direkte Aufrufe
CREATE OR REPLACE FUNCTION public.health_check()
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.health_check_v1();
$$;

-- 3. Berechtigungen vergeben (anon und authenticated)
GRANT EXECUTE ON FUNCTION public.health_check_v1() TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.health_check() TO anon, authenticated;

-- 4. Funktionskommentare für Schema-Dokumentation
COMMENT ON FUNCTION public.health_check_v1() IS 'Schlanker Backend-Healthcheck zur Prüfung der Datenbankverbindung und Systemgesundheit (v1 Standard).';
COMMENT ON FUNCTION public.health_check() IS 'Schlanker Backend-Healthcheck Alias (kompatibel mit public.health_check_v1).';
