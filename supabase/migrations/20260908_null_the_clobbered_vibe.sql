-- APPLIED 2026-09-08. Note: applied with execute_sql, so it is NOT recorded in
-- the supabase_migrations ledger -- `list_migrations` will not show it. This
-- file is the only record. It is idempotent and safe to re-run.
--
-- Clears the one profiles.vibe value that step 1 of
-- `20260907_separate_vibe_from_mood.sql` wrote in error.
--
-- That migration copied user_states.mood_tag into profiles.vibe on the premise
-- that mood_tag could only ever hold a Vibe, because MoodSyncService had never
-- successfully written it. True when the file was written; false by the time it
-- was applied -- a MoodSync UI test in between had overwritten d9fa2f57's
-- 'Reflective' with 'flirty'. So the copy moved a Mood into the Vibe column and
-- the original onboarding Vibe was lost from the database. See that file's
-- closing note for the full account.
--
--   d9fa2f57  profiles.vibe = 'flirty'   <-- not a Vibe; the 7 Vibe values are
--                                            capitalised: Reflective, Dreamy,
--                                            Calm, Flirty, Healing, Energetic,
--                                            Creative
--
-- 'Reflective' is recoverable from this repo's history, but not from anything
-- that knows it is still true. Darcell's instruction, and the reason this
-- migration nulls rather than restores:
--
--   "I picked it quickly during onboarding and don't actually remember --
--    restoring a guessed value isn't better than an empty one."
--
-- NULL is the honest state: the app has no Vibe on record for this user, which
-- is exactly what is true. It is also already the state of every other profile
-- row that predates the Vibe path, so nothing downstream is being handed a
-- shape it has not already seen.
--
-- No runtime effect beyond removing the wrong value. profiles.vibe is
-- write-only from Dart today -- UserService._persistVibe (user_service.dart:134)
-- writes it and nothing reads it back; AppProvider hydrates User.moodTags from
-- the profile's own moodTags/mood_tags key (app_provider.dart:278), not from
-- vibe. Onboarding will write a real value here the next time it runs.
--
-- The guard is the point. The migration this one repairs failed because it
-- assumed at apply time a fact that was only checked at author time. So the
-- condition here is not "this row" or "this value" but the vocabulary itself,
-- read from onboarding_vibe_screen.dart:22 -- clear whatever is not a Vibe.
-- Re-running is safe, and if Darcell re-picks a Vibe before this is applied,
-- that value is in the list and survives untouched.

update public.profiles
   set vibe = null
 where vibe is not null
   and vibe not in ('Reflective', 'Dreamy', 'Calm', 'Flirty', 'Healing',
                    'Energetic', 'Creative');

-- Today that matches exactly one row -- d9fa2f57 ('flirty') -- and leaves
-- 350201ed ('Dreamy') alone.
