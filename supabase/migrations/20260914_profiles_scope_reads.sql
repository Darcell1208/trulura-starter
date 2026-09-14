-- APPLIED 2026-09-14 as migration `profiles_scope_reads` (version 20260914132439).
-- Verified after applying, by role, against the live change -- see VERIFIED at the end.
--
-- REPLAY: deliberately not idempotent. `drop policy` has no IF EXISTS and
-- `create view` has no OR REPLACE, so re-running fails loudly instead of
-- silently doing nothing.
--
-- ============================================================================
-- READ THIS FIRST -- WHAT THIS DOES NOT DO
-- ============================================================================
--
-- This migration does NOT filter profiles by the person's privacy setting, and
-- neither did the alternative that was rejected. No database column holds one.
-- profileVisibility, allowScreenshots and messageAutoDelete exist only in the
-- device's local cache (TruLura_Build_Status.md #17).
--
-- So every signed-in user can still read the ten allowlisted columns of EVERY
-- profile through public.profiles_public -- including a profile whose owner set
-- it to private in the app. That gap is load-bearing: the day a privacy column
-- exists on the server, this view has to start honouring it, or "private"
-- means nothing to anyone reading through the API.
--
-- Also still readable through the view: display_name, which handle_new_user
-- derives from the email local part until the display_name naming decision
-- (IC-4 in TruLura_Build_Status.md).
--
-- ============================================================================
-- THE HOLE
-- ============================================================================
--
-- profiles_select_authenticated was `USING (true)` for the authenticated role,
-- so any signed-in user read every column of every profiles row: bio, vibe,
-- temperament, gender_identity, age_range, relationship_intent, the expression
-- answers. The Supabase anon key is public (it is in .env history and compiled
-- into the Flutter client) and signup is open, so "any signed-in user" meant
-- anyone.
--
-- Measured by role before the change (in a rolled-back transaction):
--   as 350201ed: 3 rows visible -- own 1, others 2
--   as d9fa2f57: 3 rows visible -- own 1, others 2
--   as anon:     0 rows
--
-- ============================================================================
-- THE FIX, AND WHY THIS SHAPE
-- ============================================================================
--
-- The table becomes own-row only: profiles_select_authenticated is dropped and
-- profiles_select_own remains. Other people are read through
-- public.profiles_public, an owner-executed view with a column allowlist,
-- granted to authenticated only. This is the pattern posts_feed and vent_feed
-- already use.
--
-- Rejected: own-row only with no view (option A). Product Owner decision,
-- 2026-09-14, verbatim:
--
--   "A isn't a smaller B, it's a broken app -- Explore and Sync empty, chat and
--    feed names showing "New member." That's a feature removal, not a security
--    fix, and it would get reverted. B also matches the pattern already used
--    twice (posts_feed, vent_feed): owner-rights view, column allowlist,
--    authenticated-only grant. Three surfaces with one defense is easier to
--    audit than two plus an exception."
--
-- Client change shipped with this migration. The four readers of OTHER users'
-- rows moved from public.profiles to public.profiles_public:
--   - UserService.getAllUsers              (Explore, Sync)
--   - UserService.getUserById              (feed author names, blocked users)
--   - ChatService._profilesById            (conversation member names)
--   - ChatService's New Message people list
-- Reads of your own row still use public.profiles.
--
-- ============================================================================
-- WARNINGS FOR WHOEVER CHANGES THIS NEXT
-- ============================================================================
--
-- The column list is the contract. Adding a column widens what every
-- signed-in user can read about every other user. Decide it; do not append it.
-- A reader that needs a column not listed gets null from `select()`, or an
-- error from a named select.
--
-- Old clients: builds from code before this change read other users from
-- public.profiles and now receive only their own row. In those builds Explore
-- and Sync are empty and names show "New member" until the app is rebuilt.
-- That is this migration working, not breaking.


-- Drop by verified live name, no IF EXISTS: a wrong name must fail, not no-op.
drop policy profiles_select_authenticated on public.profiles;

create view public.profiles_public as
select id,
       username,
       display_name,
       bio,
       about_me,
       profile_photo_url,
       avatar_url,
       vibe,
       created_at,
       updated_at
  from public.profiles;

comment on view public.profiles_public is
  'Owner-executed read path for other users'' profiles: ten-column allowlist, authenticated only (same pattern as posts_feed, vent_feed). Does NOT filter by a profile privacy setting: no database column holds one. Added by 20260914_profiles_scope_reads.';

revoke all on public.profiles_public from anon, authenticated, public;
grant select on public.profiles_public to authenticated, service_role;

notify pgrst, 'reload schema';


-- VERIFIED 2026-09-14, after applying, by role against the live change (the
-- probe transaction was rolled back; the migration itself was not):
--
--   as 350201ed: public.profiles        1 row  -- own 1, others 0
--                public.profiles_public 3 rows -- own 1, others 2
--   as d9fa2f57: public.profiles        1 row  -- own 1, others 0
--                public.profiles_public 3 rows -- own 1, others 2
--   as anon:     public.profiles        0 rows
--
--   SELECT on profiles_public: anon = false, authenticated = true, public = false
--   SELECT policies on public.profiles: profiles_select_own only
--   profiles_public: owner postgres, reloptions none (owner-executed),
--     columns id, username, display_name, bio, about_me, profile_photo_url,
--     avatar_url, vibe, created_at, updated_at; comment present
--   Existing rows: 3, usernames unchanged
