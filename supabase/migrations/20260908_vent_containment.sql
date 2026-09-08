-- Splits the feed in two so Vent containment is a database fact.
--
-- Blueprint line 2203: "emotional vent posts remain inside Vent environments".
-- Line 2689: "strict boundaries are enforced between feed environments".
-- Neither was true. posts_feed had no category filter at all, so a Vent post
-- was returned to the main Aura feed and only the CASE on user_id kept its
-- author hidden. De-identification is not containment: the person was hidden,
-- the disclosure was not.
--
-- Product decision by Darcell, 2026-09-08, choosing two views over a client
-- filter: "containment that depends on the client asking correctly is what
-- produced this bug. Make it a database fact." A client that forgets to filter
-- now gets a feed with no Vent in it, rather than a feed that quietly leaks.
--
--   posts_feed  -- everything EXCEPT Vent
--   vent_feed   -- ONLY Vent
--
-- The two are disjoint and their union is the whole table, so nothing becomes
-- unreachable by moving the boundary into SQL.


-- Both views carry the same privacy predicate, added in
-- 20260908_posts_feed_respect_privacy.sql: `post_privacy = 'public' or
-- user_id = auth.uid()`. That migration explains at length why the predicate
-- lives in the view rather than coming from RLS via security_invoker -- short
-- version: authenticated holds no table-level SELECT on public.posts, and
-- granting it back would expose user_id on anonymous rows and undo
-- 20260904_revoke_posts_direct_select.sql.
--
-- The drift warning there now applies to THREE places, not two:
-- posts_read_visible on public.posts, this file's posts_feed, and this file's
-- vent_feed. Change one and you must change all three. They are written
-- identically and adjacently here to make that as hard to get wrong as
-- possible.


-- Category matching is case-insensitive and fails CLOSED.
--
-- posts.category is NOT NULL and today holds only 'ForYou' and 'Vent'
-- (confirmed by select category, count(*) before writing this). The client
-- writes it through PostService._normalizeCategory, which capitalises. But a
-- row written as 'vent' by any other path must not escape into the main feed,
-- so the exclusion is `lower(btrim(category)) <> 'vent'` and the inclusion is
-- its exact complement. A category value that is unexpected lands in
-- posts_feed, which is the right default for a bucket that is not Vent; a
-- value that merely differs in case or whitespace still counts as Vent.

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
 where (post_privacy = 'public' or user_id = (select auth.uid()))
   and lower(btrim(category)) <> 'vent';


create or replace view public.vent_feed as
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
 where (post_privacy = 'public' or user_id = (select auth.uid()))
   and lower(btrim(category)) = 'vent';


-- Grants: mirror posts_feed exactly -- authenticated and service_role, never
-- anon. A new view in the public schema can pick up default privileges, so the
-- revoke is explicit rather than assumed. anon holds no SELECT on posts_feed
-- ("permission denied for view posts_feed"), and vent_feed must not be the
-- looser of the two.

revoke all on public.vent_feed from anon;
grant select on public.vent_feed to authenticated;
grant select on public.vent_feed to service_role;


-- Paired Dart change (same commit): PostService gains _ventFeedView and
-- getPostsByCategory('Vent') reads vent_feed instead of filtering posts_feed
-- client-side. Without that the Vent screen would go permanently empty, since
-- posts_feed no longer returns anything for it to filter.


-- APPLIED 2026-09-08 as migration `vent_containment`. Idempotent:
-- `create or replace view` and the grants can all be re-run.
--
-- VERIFIED after applying, by role, both directions.
--
-- As the other account (350201ed):
--   vent_feed   rows_visible = 0, the_vent_post = 0
--   posts_feed  rows_visible = 1, the_vent_post = 0   (only the public post)
--
-- As the author (d9fa2f57):
--   vent_feed   Vent   | private | i am tired
--   posts_feed  ForYou | public  | hello
--
-- Note the second line: the author's own Vent post does NOT appear in
-- posts_feed either. Containment is by environment, not by viewer -- Vent
-- content stays in Vent even for the person who wrote it, which is what
-- blueprint 2203 asks for and what the main feed no longer has any way to
-- return.
