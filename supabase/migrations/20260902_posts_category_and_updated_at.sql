-- Applied to the live project on 2026-09-02/03 as the migrations
-- `posts_add_category` and `posts_add_updated_at_and_category_not_null`.
-- This file states the intended end result in one place; it is written to be
-- safely re-runnable.
--
-- ---------------------------------------------------------------------------
-- 1. posts.category
-- ---------------------------------------------------------------------------
-- The feed bucket a post belongs to (ForYou / Vent / Mood). This is a
-- different axis from posts.post_type, which holds the post's *format*
-- (text / image / video / link).
--
-- create_post_screen.dart set Post.category to 'Vent', but _toRow never
-- persisted it and _fromAuraRow hardcoded 'ForYou' on read. So
-- getPostsByCategory('Vent') could never match a row, and Vent Space had
-- rendered nothing since it was written -- an empty screen that looked like a
-- design choice rather than a bug.
--
-- CAUTION, learned here: two sessions added this column about an hour apart.
-- `add column if not exists` skips the entire clause when the column already
-- exists, `not null` and `default` included, and still reports success. The
-- first migration created it nullable with no default; the second's
-- `not null default` was silently discarded while its `add constraint` still
-- applied. The CHECK could not catch the resulting NULL, because CHECK passes
-- on NULL rather than rejecting it. The `alter column` statements below are
-- what actually set the definition. Always read back
-- information_schema.columns afterwards.

alter table public.posts
  add column if not exists category text not null default 'ForYou';

update public.posts set category = 'ForYou' where category is null;

alter table public.posts alter column category set default 'ForYou';
alter table public.posts alter column category set not null;

alter table public.posts
  drop constraint if exists posts_category_check;

-- Mirrors _normalizeCategory in lib/services/post_service.dart; keep in step.
alter table public.posts
  add constraint posts_category_check
  check (category in ('ForYou', 'Vent', 'Mood'));

-- ---------------------------------------------------------------------------
-- 2. posts.updated_at
-- ---------------------------------------------------------------------------
-- trg_posts_updated_at fires BEFORE UPDATE on public.posts and executes
-- set_updated_at(), which assigns new.updated_at. public.posts had no such
-- column, so EVERY update on posts failed with:
--
--   42703: record "new" has no field "updated_at"
--
-- That made posts_update_own a dead policy and editing a post impossible.
-- Nothing surfaced it because no post had ever been edited.
--
-- Adding the column is preferred over dropping the trigger: the Dart Post
-- model already carries updatedAt, and _fromAuraRow had been faking it from
-- created_at. profiles, users and post_moods all already pair this column
-- with the same trigger; posts was the outlier.

alter table public.posts
  add column if not exists updated_at timestamptz not null default now();
