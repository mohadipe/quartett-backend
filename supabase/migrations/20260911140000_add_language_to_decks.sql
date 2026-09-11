-- Migration: Add language column to public.decks and update catalog facade views
-- Issue #33: [FEAT] I18N Decks: Datenmodell-Erweiterung, Deck-Sprachkennzeichnung & Badges

-- 1. Add column 'language' with default 'de' to public.decks
ALTER TABLE public.decks
ADD COLUMN IF NOT EXISTS language VARCHAR(5) DEFAULT 'de';

-- 2. Update Contract-Facade-Views for Decks (new columns must be appended at the end for CREATE OR REPLACE VIEW)
CREATE OR REPLACE VIEW public.v1_catalog_decks WITH (security_invoker = true) AS
SELECT
    id,
    slug,
    name,
    category,
    description,
    cover_image_url,
    price_coins,
    is_official,
    is_community,
    creator_id,
    review_status,
    attribute_definitions,
    created_at,
    language
FROM public.decks;

CREATE OR REPLACE VIEW public.v1_decks WITH (security_invoker = true) AS
SELECT * FROM public.v1_catalog_decks;

-- 3. Compatibility View for community_decks
CREATE OR REPLACE VIEW public.community_decks WITH (security_invoker = true) AS
SELECT
    id,
    slug,
    name,
    category,
    description,
    cover_image_url,
    price_coins,
    is_official,
    is_community,
    creator_id,
    review_status,
    attribute_definitions,
    created_at,
    language
FROM public.decks
WHERE is_community = true;

-- 4. Permissions & Cache Reload
GRANT SELECT, INSERT, UPDATE, DELETE ON public.v1_catalog_decks TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.v1_decks TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.community_decks TO anon, authenticated;

NOTIFY pgrst, 'reload schema';
