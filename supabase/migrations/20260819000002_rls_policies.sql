-- Migration 02: Row Level Security (RLS) Policies

-- Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone"
ON public.profiles FOR SELECT
USING (true);

CREATE POLICY "Users can update their own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = id);

-- Decks
ALTER TABLE public.decks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Approved decks are viewable by everyone"
ON public.decks FOR SELECT
USING (review_status = 'approved' OR creator_id = auth.uid());

CREATE POLICY "Users can create community decks"
ON public.decks FOR INSERT
WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Creators can edit their own draft decks"
ON public.decks FOR UPDATE
USING (auth.uid() = creator_id)
WITH CHECK (auth.uid() = creator_id AND review_status IN ('draft', 'approved'));

-- Cards
ALTER TABLE public.cards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Cards are viewable by everyone"
ON public.cards FOR SELECT
USING (true);

-- User Inventory
ALTER TABLE public.user_inventory_decks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see only own inventory"
ON public.user_inventory_decks FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can add to own inventory"
ON public.user_inventory_decks FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Matches
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Players can see their own matches"
ON public.matches FOR SELECT
USING (auth.uid() = host_id OR auth.uid() = guest_id);

CREATE POLICY "Players can update their own matches"
ON public.matches FOR UPDATE
USING (auth.uid() = host_id OR auth.uid() = guest_id);

-- Friendships
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users see their friendships"
ON public.friendships FOR SELECT
USING (auth.uid() = user_id OR auth.uid() = friend_id);
