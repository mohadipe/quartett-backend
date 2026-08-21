-- Migration: Update RLS policies for matches to support joining players
-- Ermöglicht es Spielern, offene Lobbies zu finden und sich als Guest einzutragen.

DROP POLICY IF EXISTS "Players can see their own matches" ON public.matches;
CREATE POLICY "Players can see their own matches"
ON public.matches FOR SELECT
USING (auth.uid() = host_id OR auth.uid() = guest_id OR status = 'waiting');

DROP POLICY IF EXISTS "Players can update their own matches" ON public.matches;
CREATE POLICY "Players can update their own matches"
ON public.matches FOR UPDATE
USING (auth.uid() = host_id OR auth.uid() = guest_id OR (status = 'waiting' AND guest_id IS NULL));
