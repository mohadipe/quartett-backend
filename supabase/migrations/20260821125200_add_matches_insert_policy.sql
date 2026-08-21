-- Migration: Add missing INSERT policy for matches table
-- Erlaubt es angemeldeten Benutzern, eigene Matches zu hosten.

DROP POLICY IF EXISTS "Authenticated users can insert matches" ON public.matches;
CREATE POLICY "Authenticated users can insert matches"
ON public.matches FOR INSERT
WITH CHECK (auth.uid() = host_id);
