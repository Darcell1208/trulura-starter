-- De-duplicates public.spark_interactions and gives connection requests the
-- uniqueness they assume.
--
-- The table was evidently created twice, by two migrations that never knew
-- about each other. Verified against the live database before writing:
--
--   FKs      fk_spark_from_user            + spark_interactions_from_user_id_fkey
--            fk_spark_to_user              + spark_interactions_to_user_id_fkey
--            fk_spark_post   (SET NULL)    + spark_interactions_post_id_fkey (CASCADE)
--   Indexes  spark_from_idx                + idx_spark_from_user_id
--            spark_to_idx                  + idx_spark_to_user_id
--   Policies spark_insert_from_self        + spark_interactions_insert_sender
--            spark_select_involving_me     + spark_interactions_select_participants
--
-- Each pair is the same rule twice, except the post_id FKs, which actively
-- disagree about what happens when a post is deleted.
--
-- WHY THIS MATTERS BEYOND TIDINESS. Duplicate foreign keys between the same two
-- tables make PostgREST embeds ambiguous -- PGRST201, "more than one
-- relationship was found" -- which is what broke embeds on public.messages
-- earlier and was fixed there the same way. spark_interactions has FOUR
-- relationships to profiles where it should have two, so any attempt to join a
-- connection request to the requester's profile is broken before it is written.
-- That join is the next thing needed: a pending request cannot be rendered
-- without the sender's name.
--
-- Which of each pair survives:
--
-- * FKs: the `fk_spark_*` set, matching how public.messages was resolved
--   (`fk_messages_sender`, `fk_messages_conversation` are what remain there).
--   For post_id this also picks ON DELETE SET NULL over CASCADE, which is the
--   better rule on its own merits: deleting a post should not erase the record
--   that one person reached out to another.
-- * Policies: the pair written as `(select auth.uid())` rather than bare
--   `auth.uid()`. Same predicate, but the subquery form is evaluated once per
--   statement instead of once per row.
-- * Indexes: `spark_from_idx` / `spark_to_idx`, to match the `fk_spark_*`
--   naming that survives above.


-- 1. Duplicate foreign keys. Dropping one of a pair leaves the other enforcing;
--    referential integrity is unchanged at every point.

alter table public.spark_interactions
  drop constraint if exists spark_interactions_from_user_id_fkey,
  drop constraint if exists spark_interactions_to_user_id_fkey,
  drop constraint if exists spark_interactions_post_id_fkey;


-- 2. Duplicate indexes.

drop index if exists public.idx_spark_from_user_id;
drop index if exists public.idx_spark_to_user_id;


-- 3. Duplicate policies. Permissive policies are OR-ed, so two identical rules
--    grant exactly what one does -- this removes noise, not access. Verify with
--    a by-role read afterwards rather than trusting that sentence.

drop policy if exists spark_interactions_insert_sender on public.spark_interactions;
drop policy if exists spark_interactions_select_participants on public.spark_interactions;


-- 4. One pending request per pair.
--
-- ConnectionService.sendConnectionRequest checks for an existing row before
-- inserting, but nothing at the database level enforced it, so two taps racing
-- each other both insert and the recipient sees the same request twice.
--
-- PARTIAL, on `post_id is null`, and the partiality is the point: a
-- person-to-person connection request has no post attached and should be
-- unique per pair, while a spark left on a post is per-post and may legitimately
-- repeat between the same two people. A plain unique index on
-- (from_user_id, to_user_id) would forbid the second kind, which is a product
-- decision nobody has made.
--
-- Safe to add now: the table holds 0 rows, and 0 duplicate person-to-person
-- pairs -- both confirmed immediately before applying. If this ever fails on a
-- re-run, read the duplicates rather than forcing past it.

create unique index if not exists spark_interactions_pending_pair_unique
  on public.spark_interactions (from_user_id, to_user_id)
  where post_id is null;


-- Deliberately NOT included: any change to who can read or write. The surviving
-- policies are the same predicates that were already in force --
-- insert where from_user_id = auth.uid(), select where the caller is either
-- participant, delete where the caller is the sender. The recipient's read is
-- what makes a request visible to the person it was sent to, and it stays.


-- APPLIED 2026-09-09 as migration `spark_interactions_cleanup`. Every statement
-- is IF EXISTS / IF NOT EXISTS, so it is safe to re-run.
--
-- VERIFIED after applying, by reading the catalog back and then by role:
--
--   FKs      fk_spark_from_user, fk_spark_to_user, fk_spark_post (SET NULL)
--            -- one per column, so PostgREST has two relationships to profiles
--            instead of four and an embed is no longer ambiguous.
--   Policies spark_insert_from_self, spark_select_involving_me,
--            spark_delete_from_self -- one each.
--   Indexes  spark_from_idx, spark_to_idx, spark_interactions_post_id_idx,
--            spark_interactions_pending_pair_unique, pkey.
--
-- Access unchanged, proven rather than asserted: in a rolled-back transaction,
-- 350201ed inserted a request to d9fa2f57 and then d9fa2f57 read it back --
-- recipient_can_read = 1. The table was confirmed back to 0 rows afterwards.
--
-- The embed fix is not itself exercised: no code joins spark_interactions to
-- profiles yet. Rendering a pending request is the next piece, and it is what
-- the duplicate FKs would have blocked.
