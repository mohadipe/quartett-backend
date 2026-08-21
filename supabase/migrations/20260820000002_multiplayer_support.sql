-- Migration 05: Multiplayer & Ghost Match Support

-- 1. Spalte "room_code" zur Tabelle public.matches hinzufügen
ALTER TABLE public.matches ADD COLUMN IF NOT EXISTS room_code TEXT;

-- Check-Constraint für 6-stelligen Code
ALTER TABLE public.matches DROP CONSTRAINT IF EXISTS check_room_code_length;
ALTER TABLE public.matches ADD CONSTRAINT check_room_code_length CHECK (room_code IS NULL OR length(room_code) = 6);

-- Unique-Index für Raum-Code im Wartezustand (damit ein Raum-Code nicht zeitgleich doppelt existiert)
CREATE UNIQUE INDEX IF NOT EXISTS matches_active_room_code_idx ON public.matches (room_code) WHERE (status = 'waiting');

-- 2. Tabelle "match_history" für Ghost-Matches anlegen
CREATE TABLE IF NOT EXISTS public.match_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    deck_id UUID REFERENCES public.decks(id) ON DELETE CASCADE,
    card_sequence JSONB NOT NULL,
    chosen_attributes JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS für die neue Tabelle aktivieren
ALTER TABLE public.match_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies für match_history
DROP POLICY IF EXISTS "Anyone can read match history" ON public.match_history;
CREATE POLICY "Anyone can read match history"
ON public.match_history FOR SELECT
USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert own match history" ON public.match_history;
CREATE POLICY "Authenticated users can insert own match history"
ON public.match_history FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- 3. matches-Tabelle sicher zur Supabase-Realtime-Publikation hinzufügen
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_publication_rel pr
        JOIN pg_class c ON pr.prrelid = c.oid
        JOIN pg_publication p ON pr.prpubid = p.oid
        WHERE p.pubname = 'supabase_realtime' AND c.relname = 'matches'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.matches;
    END IF;
END $$;
