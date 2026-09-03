-- PENDING: do not apply until tested against Supabase Realtime and post writes.
--
-- Goal: force feed readers through public.posts_feed so anonymous rows never
-- expose posts.user_id through the client API.
--
-- Known risks to test before applying:
-- 1. Realtime subscriptions still listen on public.posts. Supabase Realtime can
--    enforce RLS/permissions, so revoking direct SELECT may stop live updates.
-- 2. Any write path that uses insert().select(), update().select(), or
--    delete().select() against public.posts can have the write succeed while
--    the returned row fails.
--
-- Apply only after verifying:
-- - Home feed still receives live updates.
-- - Create post succeeds.
-- - Any post edit/update path succeeds.
-- - public.posts_feed returns user_id = null for anonymous rows read by a
--   different authenticated user.
-- - direct public.posts SELECT is denied for anon/authenticated clients.

revoke select on public.posts from anon;
revoke select on public.posts from authenticated;
