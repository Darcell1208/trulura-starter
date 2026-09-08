-- APPLIED 2026-09-07 as migration `close_post_reactions_anon_read`; verified by role.
--
-- Closes an anon read exposure on public.post_reactions, proved by role on
-- 2026-09-07 against the live database:
--
--   anon SELECT sees    = 1 rows
--     user_id=350201ed-... post=ba34572c-... type=glow
--   anon posts visible  = 0   (denied, 42501)
--
-- That is the whole problem in two lines: anon cannot read the post, but can
-- read who reacted to it. post_reactions carries user_id and post_id, so the
-- reaction table hands out exactly the identity linkage that
-- 20260904_revoke_posts_direct_select.sql revoked SELECT on public.posts to
-- prevent. It is worse for anonymous posts, where the author's own reaction to
-- their own post correlates a real user_id with content published as anonymous.
--
-- Cause: two permissive SELECT policies exist and permissive policies are
-- OR-ed, so the broader one decides.
--
--   post_reactions_read_all            SELECT  to {anon, authenticated}  using (true)
--   post_reactions_select_authenticated SELECT to {authenticated}        using (true)
--
-- The second is entirely subsumed by the first for authenticated users, so
-- dropping the first loses nothing for signed-in readers and closes anon.
--
-- Writes were checked too and are NOT affected: as anon, DELETE removed 0 rows
-- and UPDATE changed 0 rows, with the row count unchanged afterwards. RLS
-- filters DELETE and UPDATE rather than raising, so a bare "no error" is not
-- evidence either way -- these numbers come from GET DIAGNOSTICS ROW_COUNT.
-- There is no UPDATE policy on this table at all, for any role.

drop policy if exists post_reactions_read_all on public.post_reactions;

-- Defence in depth. RLS is what actually denies anon once the policy above is
-- gone, but anon should not hold the table privilege either: if a future
-- policy is ever written `to public` without a role clause, the grant is what
-- would make it live immediately.
--
-- The app never reads reactions as anon -- anon cannot read public.posts at
-- all, so a reaction count has nothing to attach to.
revoke all on public.post_reactions from anon;

-- Leaves on post_reactions:
--   post_reactions_select_authenticated  SELECT to authenticated using (true)
--   post_reactions_insert_own            INSERT to authenticated
--   post_reactions_delete_own            DELETE to authenticated (auth.uid() = user_id)
--
-- Reaction counts stay world-readable to signed-in users, which is what the
-- feed needs. Whether a signed-in user should see *who* reacted to an
-- anonymous post is a separate product question, not addressed here.

-- Verified after applying, by role, in a rolled-back transaction:
--   anon post_reactions: denied at privilege layer (42501)
--   authenticated reads  = 1 rows (feed unaffected)
--   authenticated insert : ok
--   authenticated delete own: 1 row(s)
--
-- anon now fails on the missing grant before RLS is consulted at all, which is
-- a stronger stop than the policy drop alone.
