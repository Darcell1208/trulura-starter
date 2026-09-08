-- APPLIED 2026-09-08 as migration `posts_feed_respect_privacy`. Idempotent:
-- `create or replace view` can be re-run safely. Verified after applying, by
-- role, in both directions -- see the VERIFIED block at the end of this file.
--
-- Stops public.posts_feed returning private posts to everyone.
--
-- THE LIVE DISCLOSURE, found 2026-09-08 while chasing a Vent post that saved
-- but rendered nowhere:
--
--   posts_feed had reloptions = null, so security_invoker was unset and the
--   view ran with its owner's rights, bypassing RLS on public.posts entirely.
--   posts_read_visible says `post_privacy = 'public' OR user_id = auth.uid()`;
--   the view walked straight past it and returned every row to every caller.
--
-- Verified by role before writing this, as the other account:
--
--   set local role authenticated;
--   set local request.jwt.claims = '{"sub":"350201ed-...","role":"authenticated"}';
--   select ... from public.posts_feed where content_text = 'i am tired';
--   -> Vent | private | is_anonymous true | user_id NULL | i am tired
--
-- Anonymity held -- user_id came back NULL -- but the content did not. Every
-- signed-in user could read every private post, Vent included. anon was
-- already stopped at the grant layer.


-- Why this is not `alter view ... set (security_invoker = on)`.
--
-- That is the obvious fix and it does not work here, in two stages:
--
-- 1. security_invoker checks table PRIVILEGES as the caller as well as RLS.
--    20260904_revoke_posts_direct_select.sql revoked SELECT on public.posts
--    from authenticated, leaving a column grant on (id) only. So flipping the
--    flag alone makes every feed read fail with `permission denied for table
--    posts`. Confirmed against information_schema.role_table_grants before
--    writing this: authenticated holds no table-level SELECT on posts.
--
-- 2. The repair that suggests itself -- grant SELECT on posts back to
--    authenticated and let RLS scope it -- is worse than the bug it fixes.
--    posts_read_visible permits reading every public post, and a direct table
--    read returns user_id INCLUDING on anonymous rows. The CASE in this view is
--    the only thing hiding the author of an anonymous post, and it only applies
--    to reads that come through the view. Granting the table would trade a
--    private-content leak for a deanonymisation leak, and undo the stated goal
--    of 20260904 -- "stop public.posts from exposing user_id on anonymous rows
--    through the client API".
--
-- So the view stays owner-executed, and carries the visibility predicate
-- itself. posts remains ungranted; anonymity remains enforced by the CASE;
-- private posts stop leaving the table.


-- DRIFT WARNING, because this is now a second place where post visibility is
-- decided.
--
-- The WHERE clause below duplicates posts_read_visible on public.posts. Those
-- two must be changed together. If a future migration widens or narrows that
-- policy and leaves this view alone, reads through the view and reads by any
-- other path disagree, and the disagreement is silent -- exactly the
-- one-concept-two-writers shape that 20260907_separate_vibe_from_mood.sql was
-- written to undo for user_states.mood_tag.
--
-- The alternative was worse for the reason in stage 2 above. If posts ever
-- gains a column-level grant covering every column the view reads, this can
-- become a plain security_invoker view with no predicate, and the duplication
-- goes away. That is the preferred end state; it is not reachable today.


-- Column list is identical to the previous definition, in the same order, so
-- PostgREST clients see no change in shape. The only addition is the WHERE.

create or replace view public.posts_feed as
select id,
       case
           when is_anonymous then null::uuid
           else user_id
       end as user_id,
       content_text,
       image_url,
       mood_tag,
       created_at,
       updated_at,
       post_type,
       is_anonymous,
       post_privacy,
       mode,
       experience_mode,
       category
  from public.posts
 where post_privacy = 'public'
    or user_id = (select auth.uid());


-- Deliberately NOT included: any filter on `category`.
--
-- This view still returns Vent posts to the main feed, which blueprint line
-- 2203 says it should not -- "emotional vent posts remain inside Vent
-- environments". That is a containment change with its own product decision
-- attached (does Vent get its own view, or does the client filter?), and
-- mixing it into a disclosure fix would make both harder to review and harder
-- to revert. It is the next change, not this one.


-- VERIFIED 2026-09-08, after applying, by role rather than by reading the
-- definition back.
--
-- As the other account (350201ed), against public.posts_feed:
--   private_rows_visible = 0
--   total_rows_visible   = 1   (the one public post)
--   the_vent_post        = 0   <-- was 1 before this migration
--
-- As the author (d9fa2f57):
--   Vent   | private | is_anonymous true  | user_id NULL | i am tired
--   ForYou | public  | is_anonymous false | user_id d9fa2f57 | hello
--
-- So the author still sees their own private post and everyone else does not,
-- which is what posts_read_visible always said and what the view was failing
-- to honour. Note the author's own anonymous row still comes back with a NULL
-- user_id through this view; that is the CASE doing its job and is unchanged.
--
-- anon was already denied at the grant layer and still is -- it holds no
-- SELECT on posts_feed at all ("permission denied for view posts_feed").
