-- Migration 01: Initial Schema (Tables & Extensions)

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Profile & Spieler-Status
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    avatar_url TEXT,
    coins INT DEFAULT 100 CHECK (coins >= 0),
    xp INT DEFAULT 0 CHECK (xp >= 0),
    level INT DEFAULT 1 CHECK (level >= 1),
    elo_rating INT DEFAULT 1000 CHECK (elo_rating >= 0),
    active_card_skin_id TEXT DEFAULT 'default',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Decks (Katalog & Community)
CREATE TABLE IF NOT EXISTS public.decks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slug TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT,
    cover_image_url TEXT,
    price_coins INT DEFAULT 0 CHECK (price_coins >= 0),
    is_official BOOLEAN DEFAULT true,
    is_community BOOLEAN DEFAULT false,
    creator_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    review_status TEXT CHECK (review_status IN ('draft', 'pending', 'approved', 'rejected')) DEFAULT 'approved',
    attribute_definitions JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Karten
CREATE TABLE IF NOT EXISTS public.cards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deck_id UUID NOT NULL REFERENCES public.decks(id) ON DELETE CASCADE,
    code TEXT NOT NULL,
    name TEXT NOT NULL,
    subtitle TEXT,
    image_url TEXT,
    fun_fact TEXT,
    image_credit TEXT,
    attributes JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(deck_id, code)
);

-- 4. Inventar freigeschalteter Decks
CREATE TABLE IF NOT EXISTS public.user_inventory_decks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    deck_id UUID NOT NULL REFERENCES public.decks(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, deck_id)
);

-- 5. Matches & Runden-Persistenz
CREATE TABLE IF NOT EXISTS public.matches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    deck_id UUID REFERENCES public.decks(id) ON DELETE RESTRICT,
    host_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    guest_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    match_type TEXT CHECK (match_type IN ('live', 'async', 'ghost')) DEFAULT 'live',
    status TEXT CHECK (status IN ('waiting', 'active', 'finished', 'abandoned')) DEFAULT 'waiting',
    pot JSONB DEFAULT '[]',
    game_state JSONB,
    turn_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    winner_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- 6. Freundschaften
CREATE TABLE IF NOT EXISTS public.friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    friend_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT CHECK (status IN ('pending', 'accepted', 'blocked')) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, friend_id)
);

-- 7. Kaufbeleg-Historie (In-App-Purchases)
CREATE TABLE IF NOT EXISTS public.purchase_receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    store TEXT CHECK (store IN ('apple', 'google', 'coins')) NOT NULL,
    product_id TEXT NOT NULL,
    transaction_id TEXT UNIQUE NOT NULL,
    purchased_at TIMESTAMPTZ DEFAULT now()
);
