BEGIN;
SELECT plan(14);

-- 1. Prüfen, ob die Hilfsfunktionen existieren
SELECT has_function(
    'public', 'get_level_from_xp',
    ARRAY['integer'],
    'Funktion get_level_from_xp(int) muss existieren'
);

SELECT has_function(
    'public', 'get_rank_tier_from_level',
    ARRAY['integer'],
    'Funktion get_rank_tier_from_level(int) muss existieren'
);

-- 2. Stufenberechnung get_level_from_xp verifizieren
SELECT results_eq(
    'SELECT public.get_level_from_xp(0), public.get_level_from_xp(150), public.get_level_from_xp(300), public.get_level_from_xp(1499)',
    'VALUES (1, 1, 2, 5)',
    'Bronze Stufen: 0-299 XP = Lvl 1, 300 XP = Lvl 2, 1499 XP = Lvl 5'
);

SELECT results_eq(
    'SELECT public.get_level_from_xp(1500), public.get_level_from_xp(6499)',
    'VALUES (6, 15)',
    'Silber Stufen: 1500 XP = Lvl 6, 6499 XP = Lvl 15'
);

SELECT results_eq(
    'SELECT public.get_level_from_xp(6500), public.get_level_from_xp(18499)',
    'VALUES (16, 30)',
    'Gold Stufen: 6500 XP = Lvl 16, 18499 XP = Lvl 30'
);

SELECT results_eq(
    'SELECT public.get_level_from_xp(18500), public.get_level_from_xp(42499)',
    'VALUES (31, 50)',
    'Platin Stufen: 18500 XP = Lvl 31, 42499 XP = Lvl 50'
);

SELECT results_eq(
    'SELECT public.get_level_from_xp(42500), public.get_level_from_xp(142499), public.get_level_from_xp(200000)',
    'VALUES (51, 100, 100)',
    'Diamant Stufen: 42500 XP = Lvl 51, 142499 XP = Lvl 100, 200000 XP gedeckelt auf Lvl 100'
);

-- 3. Rang-Tiers get_rank_tier_from_level verifizieren
SELECT results_eq(
    'SELECT public.get_rank_tier_from_level(1), public.get_rank_tier_from_level(5)',
    $$VALUES ('bronze', 'bronze')$$,
    'Level 1 bis 5 sind bronze'
);

SELECT results_eq(
    'SELECT public.get_rank_tier_from_level(6), public.get_rank_tier_from_level(15)',
    $$VALUES ('silber', 'silber')$$,
    'Level 6 bis 15 sind silber'
);

SELECT results_eq(
    'SELECT public.get_rank_tier_from_level(16), public.get_rank_tier_from_level(30)',
    $$VALUES ('gold', 'gold')$$,
    'Level 16 bis 30 sind gold'
);

SELECT results_eq(
    'SELECT public.get_rank_tier_from_level(31), public.get_rank_tier_from_level(50)',
    $$VALUES ('platin', 'platin')$$,
    'Level 31 bis 50 sind platin'
);

SELECT results_eq(
    'SELECT public.get_rank_tier_from_level(51), public.get_rank_tier_from_level(100)',
    $$VALUES ('diamant', 'diamant')$$,
    'Level 51 bis 100 sind diamant'
);

-- 4. Test-User für rpc_claim_match_reward anlegen
INSERT INTO auth.users (id, email)
VALUES ('33333333-3333-3333-3333-333333333333', 'tier_tester@example.com');

UPDATE public.profiles
SET xp = 1400, level = 5, coins = 100
WHERE id = '33333333-3333-3333-3333-333333333333';

SET LOCAL ROLE authenticated;
SET LOCAL "request.jwt.claim.sub" TO '33333333-3333-3333-3333-333333333333';

-- 5. Match-Belohnung mit Tier-Aufstieg (Bronze -> Silber): +100 XP -> 1500 XP (Lvl 6), +25 Coins + 100 Tier-Bonus = 225 Coins
SELECT results_eq(
    'SELECT (res->>''level'')::text, (res->>''tier'')::text, (res->>''tier_promoted'')::text, (res->>''coins'')::text FROM (SELECT public.rpc_claim_match_reward(gen_random_uuid(), 100, 25) AS res) t',
    $$VALUES ('6'::text, 'silber'::text, 'true'::text, '225'::text)$$,
    'Aufstieg von Bronze zu Silber muss Lvl 6, tier silber, tier_promoted true und 225 Coins (100 Start + 25 Match + 100 Tier-Bonus) ergeben'
);

-- 6. Normaler Match-Gewinn ohne Tier-Aufstieg (Silber bleibt Silber)
SELECT results_eq(
    'SELECT (res->>''level'')::text, (res->>''tier_promoted'')::text, (res->>''coins'')::text FROM (SELECT public.rpc_claim_match_reward(gen_random_uuid(), 100, 25) AS res) t',
    $$VALUES ('6'::text, 'false'::text, '250'::text)$$,
    'Normaler Sieg ohne Tier-Aufstieg vergibt reguläre 25 Coins ohne Tier-Bonus (225 + 25 = 250 Coins)'
);

SELECT * FROM finish();
ROLLBACK;
