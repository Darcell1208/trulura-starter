-- Applied to the live project on 2026-09-02 as migration `posts_close_anon_read`.
--
-- Live schema observed before drafting:
-- public.posts (
--   id, user_id, content_text, image_url, mood_tag, created_at,
--   post_type, is_anonymous, post_privacy, mode, experience_mode
-- )
-- check constraint: post_privacy in ('public', 'followers', 'private')
--
-- The problem this fixes: posts_read_visible granted SELECT to
-- {anon, authenticated}. The anon key ships inside the client app, so the
-- entire public feed was readable and scrapable without an account -- the
-- same exposure class as the profiles_public_read policy dropped earlier.
--
-- IMPORTANT: the drop statements below use the policy names that actually
-- exist in the live database (posts_read_visible, posts_select_public,
-- posts_insert_own, posts_update_own, posts_delete_own). An earlier draft of
-- this file dropped prose-style names that matched nothing, so the anon grant
-- survived and the new policies were merely OR-ed on top of it, changing
-- nothing. Permissive policies combine with OR: adding a policy can only
-- widen access, never narrow it. Narrowing requires dropping the policy that
-- grants too much.
--
-- Read scoping rationale:
--   public    -> readable by any signed-in user; a social feed needs
--                cross-user discovery.
--   private   -> author only, via the user_id arm.
--   followers -> no follows/connections table exists yet
--                (connection_service.dart is a local placeholder), so these
--                fall through to author-only. That is the safe direction to
--                fail. Add a follower read arm when the graph table lands.
--
-- Writes were already correct and are left untouched: posts_insert_own,
-- posts_update_own and posts_delete_own all check auth.uid() = user_id.

alter table public.posts enable row level security;

-- posts_select_public carried a predicate identical to posts_read_visible.
-- Collapse the two into one authenticated-only policy.
drop policy if exists posts_read_visible on public.posts;
drop policy if exists posts_select_public on public.posts;

create policy posts_read_visible on public.posts
  for select to authenticated
  using (post_privacy = 'public' or user_id = (select auth.uid()));

-- NOTE: this migration does NOT make is_anonymous safe. RLS filters rows,
-- not columns, so every reader of an anonymous post still receives its
-- user_id in the API response. Closing that requires a column-restricted
-- view or explicit column grants, tracked separately.
