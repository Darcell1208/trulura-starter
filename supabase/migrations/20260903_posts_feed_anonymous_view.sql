-- Fix is_anonymous leaking posts.user_id to feed readers.
--
-- RLS filters rows, not columns. Before this migration, anonymous posts still
-- returned user_id in API responses, so anonymity was only presentational.
--
-- Reads move to public.posts_feed. The view preserves the current row scope:
--   public posts are visible to signed-in users;
--   private/followers posts are visible only to their author until a graph table
--   exists.
--
-- The view is owner-executed rather than security_invoker because authenticated
-- callers should no longer have direct SELECT on public.posts. The row scope is
-- therefore encoded explicitly in the view WHERE clause.

create or replace view public.posts_feed
with (security_barrier = true)
as
select
  id,
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

revoke all on public.posts_feed from anon;
grant select on public.posts_feed to authenticated;

-- Force feed readers through posts_feed. Insert/update/delete grants and RLS
-- policies on public.posts remain the write path.
revoke select on public.posts from anon;
revoke select on public.posts from authenticated;
