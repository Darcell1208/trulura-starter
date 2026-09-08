-- APPLIED 2026-09-07 as migration `separate_vibe_from_mood`.
--
-- Gives user_states.mood_tag a single writer and a single vocabulary, and
-- relocates the onboarding Vibe to the column that was already there for it.
--
-- The collision, found while diagnosing why MoodSync appeared not to persist:
--
--   user_states.mood_tag  d9fa2f57 = 'Reflective'   updated 2026-09-01
--                         350201ed = 'Dreamy'       updated 2026-09-07
--
-- Two writers, two vocabularies, one column:
--
--   MoodSyncService.recordMood  writes Mood.name -- lowercase, 5 values:
--                               reflective, flirty, calm, social, healing
--   UserService._persistMood    writes _firstNonEmpty(user.moodTags) -- the
--                               onboarding Vibe, capitalised, 7 values:
--                               Reflective, Dreamy, Calm, Flirty, Healing,
--                               Energetic, Creative
--
-- These are not the same concept. onboarding_vibe_screen.dart says so in its
-- own comment -- "Phase-1: store vibe as a mood tag" -- i.e. it was parked
-- here as an admitted stopgap. 'Dreamy', 'Energetic' and 'Creative' have no
-- Mood equivalent, and 'social' has no Vibe equivalent, so neither vocabulary
-- is a subset of the other.
--
-- The practical effect: MoodSyncService.currentMood() cannot map 'Dreamy' to a
-- Mood, returns null, and AuraStateController falls back to the Mood.calm
-- placeholder -- for that user, permanently, no matter what they pick.
--
-- profiles.vibe is text, nullable, and NULL for every existing row; nothing in
-- the Dart codebase reads or writes it. It is the natural home. Note that
-- profiles.vibe_status is NOT available -- it already holds TruVibeLabel
-- ('oldSoul', 'grounded'), which is a third, separate vocabulary.


-- 1. Preserve the onboarding Vibe before mood_tag is normalised.
--
-- Runs first and unconditionally. Everything currently in mood_tag was written
-- by the Vibe path -- MoodSyncService has never successfully written this
-- column -- so every existing value is a Vibe and belongs in profiles.vibe.
--
-- Guarded on `p.vibe is null` so a re-run cannot clobber a real vibe set later
-- through the new path.

update public.profiles p
   set vibe = us.mood_tag
  from public.user_states us
 where us.user_id = p.id
   and us.mood_tag is not null
   and btrim(us.mood_tag) <> ''
   and p.vibe is null;


-- 2. Normalise mood_tag to the Mood enum, and null what does not belong.
--
-- Lowercasing first rescues the values that ARE valid moods under a different
-- casing ('Reflective' -> 'reflective'). Anything still outside the enum after
-- that was only ever a Vibe, is now safely copied into profiles.vibe by step
-- 1, and is cleared here rather than left to poison every future read.
--
-- NULL is the correct result for those users: it means "no mood set", which is
-- true, and which AuraStateController already handles by keeping its
-- placeholder rather than inventing a value.

update public.user_states
   set mood_tag = lower(btrim(mood_tag))
 where mood_tag is not null;

update public.user_states
   set mood_tag = null
 where mood_tag is not null
   and mood_tag not in ('reflective', 'flirty', 'calm', 'social', 'healing');


-- 3. Enforce the vocabulary from here on.
--
-- Without this, nothing stops a future writer from parking another concept in
-- this column exactly as the Vibe path did. The CHECK is what makes "one
-- writer, one vocabulary" an actual guarantee rather than a convention.
--
-- NULL stays allowed -- "no mood set" is a legitimate state, and a NOT NULL
-- here would force every row to claim a mood the user never chose.
--
-- If the Mood enum ever gains a value, this constraint must be updated in the
-- same change. That coupling is deliberate and preferable to an unconstrained
-- column: a migration that fails loudly beats a value that silently never
-- hydrates.

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'user_states_mood_tag_enum') then
    alter table public.user_states
      add constraint user_states_mood_tag_enum
      check (mood_tag is null or mood_tag in
             ('reflective', 'flirty', 'calm', 'social', 'healing'));
  end if;
end $$;


-- Expected end state on the current two rows:
--   d9fa2f57  user_states.mood_tag = 'reflective'   profiles.vibe = 'Reflective'
--   350201ed  user_states.mood_tag = NULL           profiles.vibe = 'Dreamy'
--
-- Paired Dart change (same commit): UserService._persistMood becomes
-- _persistVibe and writes profiles.vibe instead of user_states.mood_tag, so
-- MoodSyncService is the only writer of mood_tag.

-- ACTUAL end state after applying, which differs from the prediction above:
--   d9fa2f57  mood_tag = 'flirty'   profiles.vibe = 'flirty'   <-- WRONG
--   350201ed  mood_tag = NULL       profiles.vibe = 'Dreamy'   <-- correct
--
-- Step 1's premise -- "everything in mood_tag today is a Vibe, since
-- MoodSyncService has never written it" -- was true when this file was written
-- and false when it was applied. A successful MoodSync UI test in between
-- overwrote d9fa2f57's 'Reflective' with 'flirty', so step 1 copied a Mood
-- value into the Vibe column and the original onboarding Vibe was lost from
-- the database.
--
-- The lesson is not about this column: a data migration whose correctness
-- depends on "nothing has written here yet" must re-check that premise at
-- apply time, not at author time, in any system with concurrent writers.
