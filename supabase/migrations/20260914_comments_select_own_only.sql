-- APPLIED 2026-09-14 as migration `comments_select_own_only` (version 20260914133748),
-- while public.comments held 0 rows. Verified after applying, by role, against the
-- live change -- see VERIFIED at the end.
--
-- REPLAY: deliberately not idempotent. `drop policy` has no IF EXISTS and
-- `create policy` fails if the policy exists, so re-running fails loudly
-- instead of silently doing nothing.
--
-- ============================================================================
-- READ THIS FIRST -- WHAT THIS DOES NOT DO
-- ============================================================================
--
-- This closes the open read. It does NOT build the read path comments need.
-- Before comments ship, other people's comments still have to be served
-- through a view that nulls user_id on comments under anonymous posts, as
-- TruLura_PO_Decision_Vent_Identity_And_Blocking.md section 2b requires.
--
-- That view has an unresolved conflict to settle first. Section 2a derives a
-- commenter's per-thread name from post id + user id. If the view nulls
-- user_id, the client cannot derive the name. A plain hash of the two ids is
-- not a substitute: every profile id is readable through
-- public.profiles_public, so the hash can be reversed by trying them all. The
-- name, or a token for it, has to be produced server-side.
--
-- ============================================================================
-- THE HOLE
-- ============================================================================
--
-- comments_select_authenticated was `USING (true)`, so any signed-in user
-- could read every comment row, user_id and post_id included. On an anonymous
-- Vent that ships each commenter's real uuid to every client. If the author
-- comments on their own vent, comments.user_id joined to comments.post_id
-- identifies the author of the vent itself, with a plain client query. anon
-- also held every table privilege; RLS denied it only because no policy
-- named anon.
--
-- Closed while the table was empty, so no comment was ever exposed.
--
-- ============================================================================
-- THE FIX, AND WHY THIS SHAPE
-- ============================================================================
--
-- Own rows only, the same shape public.profiles took today
-- (20260914_profiles_scope_reads.sql):
--   - comments_select_authenticated is dropped
--   - comments_select_own (user_id = auth.uid()) replaces it
--   - anon loses every privilege on the table
-- The existing own-row insert, update and delete policies are unchanged.
--
-- Rejected after a dry run: revoking SELECT from authenticated with no
-- replacement policy. It hid everyone's comments, but it also broke the
-- author's own edits. UPDATE ... WHERE id = ... failed with 42501, because the
-- WHERE clause needs SELECT on the column. A column grant alone would not have
-- rescued it: with no SELECT policy, RLS hides every row, so an update by id
-- would report success and change nothing.


-- Drop by verified live name, no IF EXISTS: a wrong name must fail, not no-op.
drop policy comments_select_authenticated on public.comments;

create policy comments_select_own on public.comments
  for select
  to authenticated
  using (user_id = (select auth.uid()));

revoke all on public.comments from anon;

notify pgrst, 'reload schema';


-- VERIFIED 2026-09-14, after applying, by role against the live change. The
-- probe transaction contained no DDL and was rolled back; 0 comment rows
-- remain.
--
--   Policies on public.comments: comments_select_own [SELECT],
--     comments_insert_own [INSERT], comments_update_own [UPDATE],
--     comments_delete_own [DELETE] -- all to authenticated
--   anon: no privilege on public.comments
--
--   as 350201ed: INSERT own comment                    OK
--                INSERT with another user's user_id    42501 row-level security
--                SELECT comments                       1 row (own)
--   as d9fa2f57: SELECT comments                       0 rows
--                SELECT where user_id = 350201ed       0 rows
--                UPDATE 350201ed's comment by id       0 rows affected
--                DELETE 350201ed's comment by id       0 rows affected
--   as 350201ed: UPDATE own comment by id              1 row affected
--                DELETE own comment by id              1 row affected
--   as anon:     SELECT comments                       42501 permission denied
--                INSERT                                42501 permission denied
