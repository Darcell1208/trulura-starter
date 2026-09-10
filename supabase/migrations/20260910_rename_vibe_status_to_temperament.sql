-- NOT YET APPLIED. Do not run this before the Dart in step 1 below has shipped.
--
-- Renames profiles.vibe_status -> profiles.temperament, and drops the dead
-- profiles.persona column.
--
-- WHY
-- ---
-- Per docs/TruLura_PO_Decision_Vibe_And_Temperament.md there are two live
-- concepts and they were both called "vibe":
--
--   profiles.vibe         expressive, current, changes often. Reflective,
--                         Dreamy, Calm, Flirty, Healing, Energetic, Creative.
--                         Feeds the aura and the feed. Keeps its name.
--   profiles.vibe_status  dispositional temperament. oldSoul, grounded.
--                         Does not change week to week. Renamed here.
--
-- profiles.persona is dropped rather than reused. It is null for every row and
-- no code reads or writes it, but the word is already live in the UI for
-- something else entirely -- profile setup Step 2 labels the identity-mode
-- chips "Persona", and those write active_identity_mode. An empty column whose
-- name already means a different thing is a trap for the next schema reader.
--
-- ORDER. THIS FILE IS STEP 2 OF 3.
-- -------------------------------
-- vibe_status is LIVE: populated for every existing profile and written on
-- every save. It sits in _persistProfile's `safePayload`, which goes through
-- .upsert() with NO error tolerance -- unlike `optionalPayload`, which already
-- swallows missing-column errors. So applying this migration first makes every
-- profile save fail with PGRST204 until new Dart ships.
--
--   Step 1 (app, MUST ship first): move the temperament write out of
--     safePayload into a dedicated write that tries `temperament` first and
--     falls back to `vibe_status` on a missing-column error, using the existing
--     _isMissingColumnError helper. Make the three read sites accept
--     `temperament ?? vibe_status`. This build works against BOTH schemas, so
--     there is no window where a write targets a column that is not there.
--
--   Step 2 (this file): rename the column, drop the dead one.
--
--   Step 3 (app, after this is confirmed applied): delete the vibe_status
--     fallback from the write and the reads. Not urgent; harmless until done.
--
-- Rename rather than add-and-backfill, deliberately: this table already has
-- more vocabulary than it can carry, and a second column holding the same
-- values during a transition is one more thing that can be read by mistake.
--
-- REPLAY SAFETY
-- -------------
-- Both statements are guarded so re-running is a no-op rather than an error.
-- Nothing here is destructive to replay: the rename only fires if the old name
-- still exists, and the drop only fires if persona still exists.
--
-- Verified against the live database on 2026-09-10 before writing: no
-- constraint, index, policy, view, or function references either column, so a
-- bare rename cannot break a dependent object. Re-verify before applying --
-- that check is a snapshot and this file may sit unapplied for a while.

begin;

-- 1. vibe_status -> temperament, only if it has not already happened.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'vibe_status'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'profiles'
      and column_name = 'temperament'
  ) then
    alter table public.profiles rename column vibe_status to temperament;
  end if;
end $$;

-- 1b. Rename the two values that overlapped the vibe vocabulary.
--
-- TruVibeLabel held {oldSoul, healing, reflective, radiant, grounded,
-- mysterious} and the vibe vocabulary is {Reflective, Dreamy, Calm, Flirty,
-- Healing, Energetic, Creative}. They shared 'reflective' and 'healing', which
-- made a value in the wrong column undetectable by inspection -- an invariant
-- that cannot be verified is not an invariant. The Dart enum becomes
-- TruTemperament with contemplative and mending in the same pass.
--
-- THIS IS NOT OPTIONAL EVEN THOUGH NO ROW HOLDS THOSE VALUES TODAY.
-- Checked 2026-09-10: vibe_status is oldSoul x2, grounded x1. That is a
-- snapshot and this file may sit unapplied for days. The walkthrough's
-- "Primary vibe" dropdown offers every TruVibeLabel value including
-- reflective and healing, and _persistProfile writes vibe_status on every
-- profile save, so a row can acquire one at any moment. Without these updates
-- TruTemperamentX.tryParse returns null for such a row and the value is lost
-- silently -- the same shape as the frozen aura, where an unmappable value
-- became a null nobody saw.
update public.profiles set temperament = 'contemplative'
  where temperament = 'reflective';
update public.profiles set temperament = 'mending'
  where temperament = 'healing';

comment on column public.profiles.temperament is
  'Dispositional temperament (TruTemperament: oldSoul, grounded, ...). Stable; '
  'does not change week to week. NOT profiles.vibe, which is the expressive, '
  'current-state value that feeds the aura and the feed, and NOT '
  'user_states.mood_tag, which is Mood. These three never share storage and no '
  'one of them may read another as a fallback. See '
  'docs/TruLura_PO_Decision_Vibe_And_Temperament.md.';

-- 2. Drop the dead persona column.
alter table public.profiles drop column if exists persona;

commit;

-- POST-APPLY VERIFICATION -- run this, do not trust the statements above.
-- `alter ... if exists` and guarded DO blocks are exactly the kind of statement
-- that reports success while doing nothing.
--
--   select column_name from information_schema.columns
--   where table_schema='public' and table_name='profiles'
--     and column_name in ('vibe','vibe_status','temperament','persona')
--   order by column_name;
--
-- Expect exactly: temperament, vibe.
-- If vibe_status is still listed, the rename did not fire. If persona is still
-- listed, the drop did not fire.
--
--   select username, vibe, temperament from public.profiles;
--
-- Expect the temperament values that were in vibe_status -- oldSoul, oldSoul,
-- grounded as of 2026-09-10 -- with vibe unchanged (Dreamy, Dreamy,
-- reflective). A rename preserves data; if temperament is null anywhere,
-- something added a new column instead of renaming.
--
-- And confirm no overlapping value survived the 1b updates:
--
--   select count(*) from public.profiles
--   where temperament in ('reflective', 'healing');
--
-- Expect 0. A non-zero count means a row was written between the updates and
-- this check, which is possible if the app was live during the migration --
-- rerun the two updates, they are idempotent.
--
-- Note `vibe` legitimately holds 'reflective' for moname. That is the
-- expressive vocabulary and it is correct there. The point of renaming the
-- temperament values was to make exactly that distinction visible: after this,
-- 'reflective' can only mean vibe and 'contemplative' can only mean
-- temperament, so a value in the wrong column is detectable by reading it.
