-- APPLIED 2026-09-08 as migration `blocks_integrity`. The two `set not null`
-- statements are idempotent; `add constraint blocks_no_self_block` is not and
-- will fail loudly on a replay, which is the intended behaviour.
--
-- Feature 5, phase 1 of 3: close the two holes in `blocks` before the app
-- starts writing to it.
--
-- Written against the live schema read on 2026-09-08. The table already has
-- what matters: FKs to profiles(id) ON DELETE CASCADE on both sides, a unique
-- index on (user_id, blocked_user_id), indexes on each column, and three
-- policies TO authenticated -- select/insert/delete, all predicated on
-- user_id = auth.uid(). No UPDATE policy, which is right; a block has nothing
-- to edit. None of that is touched here.
--
-- What is missing is that both uuid columns are nullable and nothing prevents
-- a row from blocking its own author.


-- 1. Both sides required.
--
-- A block with a NULL blocked_user_id is not a block, it is a row that will
-- never match anything and will never be cleaned up. The insert policy hides
-- half of this already -- `user_id = auth.uid()` evaluates to NULL, not true,
-- for a NULL user_id, so the policy rejects it -- but blocked_user_id has no
-- such accidental guard, and relying on an RLS predicate to enforce a data
-- invariant is the wrong layer regardless.
--
-- Spelled as `alter column ... set not null` rather than folded into an `add
-- column` clause. The columns already exist, and in this repo two sessions
-- once added the same column an hour apart with `add column if not exists`,
-- silently discarding the second one's `not null default` while its separate
-- constraint still applied. Changing an existing column is its own statement.
--
-- Safe on the current table: 0 rows as of 2026-09-08, so neither statement can
-- fail on existing data. If it does fail, that means rows were written between
-- this file being authored and applied -- which is the exact class of stale
-- premise that broke 20260907_separate_vibe_from_mood.sql. Read the error
-- rather than forcing past it.

alter table public.blocks alter column user_id set not null;
alter table public.blocks alter column blocked_user_id set not null;


-- 2. No self-blocks.
--
-- Nothing in the UI offers this -- the block action is only reachable from
-- another person's profile sheet or a chat thread's overflow menu -- but the
-- unique index would happily store (me, me), and every read path that asks
-- "is this user blocked" would then answer yes for the viewer themselves.
-- Cheap to prevent, tedious to diagnose later.

alter table public.blocks
  add constraint blocks_no_self_block
  check (user_id <> blocked_user_id);


-- Deliberately NOT included: anything that makes a block take effect.
--
-- After this migration a block is durable and private to its owner, and that
-- is all. It does not stop the blocked user from sending messages -- messages
-- and conversations RLS does not consult this table. Enforcement is phase 3,
-- held back at Darcell's instruction until persistence has been verified in
-- the running app, because it means editing the messaging policies that
-- 20260907_close_self_join_hole.sql just tightened.
--
-- Until phase 3 lands, the only enforcement is client-side, in
-- chat_thread_screen.dart and trulura_profile_preview_sheet.dart. Do not
-- describe blocking as enforced before then.
