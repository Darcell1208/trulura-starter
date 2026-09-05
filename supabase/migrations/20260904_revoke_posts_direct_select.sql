-- APPLIED 2026-09-04. Verified against the live database: public.posts has no
-- table-level SELECT for anon or authenticated, and authenticated holds a
-- column-level SELECT on (id) only.
--
-- Goal: stop public.posts from exposing user_id on anonymous rows through the
-- client API.
--
-- Nothing in the app reads columns from public.posts directly -- every read
-- goes through public.posts_feed (see PostService._feedView), which is
-- security_barrier and owner-executed, and so is unaffected by these grants.
--
-- Why the column grant on (id) is here at all:
--
-- It was added to keep Supabase Realtime alive. postgres_changes decides
-- whether to deliver an event by re-running a visibility probe as the
-- subscriber's role; with no SELECT privilege at all that probe fails at the
-- privilege layer, before RLS is consulted, so no events would be delivered.
-- Granting only (id) satisfies the probe while withholding user_id -- and
-- content_text, mood_tag, image_url and everything else -- from the realtime
-- payload. It is drift-safe: a column added to posts later is not granted by
-- default, which fails in the safe direction.
--
-- That reasoning is sound but currently moot. public.posts is NOT a member of
-- the supabase_realtime publication -- confirmed against pg_publication_tables,
-- whose public members are device_users, glow_sessions, mood_events, moods,
-- sparks and vents. Without publication membership Postgres never emits the
-- WAL messages Realtime replays, so the `public:posts` postgres_changes
-- subscription in HomeFeedScreen (lib/screens/home/home_feed_screen.dart:438)
-- has never fired -- not once, and not because of this migration. The feed has
-- always been driven solely by its initial load and pull-to-refresh, both of
-- which read posts_feed and are unaffected here. The same is true of the
-- `public:post_reactions` subscription just below it; post_reactions is not in
-- the publication either.
--
-- So this migration does not break live updates, because there were none to
-- break. If posts is ever added to supabase_realtime, the (id) grant means the
-- subscription starts working without reopening the user_id leak. Adding it is
-- a separate, deliberate change -- it is not done here.
--
-- Order matters. The table-level grant must be revoked first; a table-level
-- SELECT subsumes column-level grants, so granting columns without revoking
-- first would change nothing.

revoke select on public.posts from anon;
revoke select on public.posts from authenticated;

grant select (id) on public.posts to authenticated;
