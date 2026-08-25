-- Migration: Community Deck Creator & Reviews RLS Policies

-- 1. Tabellen-Erstellung für Reviews
CREATE TABLE IF NOT EXISTS public.deck_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deck_id UUID NOT NULL REFERENCES public.decks(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(deck_id, user_id)
);

-- 2. RLS aktivieren für deck_reviews
ALTER TABLE public.deck_reviews ENABLE ROW LEVEL SECURITY;

-- 3. RLS-Policies für deck_reviews
CREATE POLICY "Reviews are viewable by everyone"
ON public.deck_reviews FOR SELECT
USING (true);

CREATE POLICY "Authenticated users can create reviews for approved decks"
ON public.deck_reviews FOR INSERT
WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (
        SELECT 1 FROM public.decks
        WHERE decks.id = deck_reviews.deck_id
          AND decks.review_status = 'approved'
    )
);

CREATE POLICY "Users can update their own reviews"
ON public.deck_reviews FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own reviews"
ON public.deck_reviews FOR DELETE
USING (auth.uid() = user_id);

-- 4. RLS-Policies für cards (Schreibzugriff)
CREATE POLICY "Creators can insert cards for their own draft decks"
ON public.cards FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.decks
        WHERE decks.id = cards.deck_id
          AND decks.creator_id = auth.uid()
          AND decks.review_status = 'draft'
    )
);

CREATE POLICY "Creators can update cards for their own draft decks"
ON public.cards FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM public.decks
        WHERE decks.id = cards.deck_id
          AND decks.creator_id = auth.uid()
          AND decks.review_status = 'draft'
    )
);

CREATE POLICY "Creators can delete cards from their own draft decks"
ON public.cards FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM public.decks
        WHERE decks.id = cards.deck_id
          AND decks.creator_id = auth.uid()
          AND decks.review_status = 'draft'
    )
);

-- 5. RLS-Policy zum Löschen von Decks durch den Ersteller
CREATE POLICY "Creators can delete their own draft decks"
ON public.decks FOR DELETE
USING (auth.uid() = creator_id AND review_status = 'draft');

-- 6. Berechtigungen explizit vergeben
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;
