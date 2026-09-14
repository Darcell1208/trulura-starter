# TruLura Product Owner Decision Record — Vibe, Temperament & Mood

**Decision date:** 2026-09-10
**Decided by:** Darcell (Product Owner)
**Amended 2026-09-13:** three rulings confirmed or made, and the column rename now live — see *Addendum* at the end of this record. The text above the addendum is unchanged.
**Amended 2026-09-14:** `profiles.persona` is dropped (applied 2026-09-14), Vibe is Aura, and Vibe is Layer 1 — see *Addendum — 2026-09-14*.
**Classification: Product Owner Decision, 2026.** The Blueprint does not
address any of this. It has no pseudonym concept, no vibe taxonomy, and does
not distinguish expressive state from disposition. Everything below is authored
here. Companion to `TruLura_PO_Decision_Aura_Architecture.md`, which settled
that Mood is not Aura; this settles the two remaining vocabularies that were
still colliding with it.

---

## The ruling: two concepts, not one

**`vibe` — expressive, current, changes often.** Reflective, Dreamy, Calm,
Flirty, Healing, Energetic, Creative. Feeds the aura and the feed. This is what
signup asks for, and **signup should keep asking it.**

**`vibe_status` — dispositional temperament.** oldSoul, grounded. Does not
change week to week. This is not a vibe, and the walkthrough must stop labelling
it "Primary vibe."

**Mood stays separate**, per the Aura record: short-lived, feeds Aura State, not
identity.

### Why two and not one

Collapsing them would lose something real. "How do you feel and want to be seen
right now" and "what is your standing temperament" are different questions with
different lifetimes. One turns over in days and drives what the feed shows; the
other is stable and describes a person rather than a moment. A single field
answering both would answer neither — it would either churn too fast to be a
temperament or sit too still to tune a feed.

What was wrong was never that both concepts existed. It was that both were
called "vibe."

### The constraint this record exists to enforce

**Two concepts with disjoint value sets must never share a column — including
sharing one by way of a read fallback.**

That is the actual lesson from the aura freeze, and it is worth stating exactly
because the bug was invisible and per-user. Vibe was being written into
`user_states.mood_tag`, the Mood column. Vibe's seven values are not a subset of
Mood's five: Dreamy, Energetic and Creative have no Mood equivalent.
`MoodSyncService.currentMood()` could not map 'Dreamy' to a Mood, returned null,
and `AuraStateController` fell back to its `Mood.calm` placeholder **forever**,
for that user alone — which is why it survived testing.

No shared columns between `vibe`, `vibe_status` and Mood. Ever.

### The stronger form: no concept reads another concept's storage, even as a fallback

"No shared columns" is not sufficient, and today proved it. The `moodTags`
hydrate fell through to `user_states.mood_tag` when it found nothing — different
column, different table, and still the same collision, because **the value path
was shared even though the storage was not**. A Mood value arrived in a field
that is supposed to hold a Vibe, by exactly the route the column rule was
written to prevent.

So the rule is: **no concept reads another concept's storage, in any
circumstance, including as a fallback, a default, or a migration convenience.**
If the right column is empty, the correct answer is empty. A plausible value
from the wrong vocabulary is worse than a null, because null is visibly missing
and a wrong-vocabulary value looks like data.

### And a hazard the rule does not yet cover: the value sets overlap

`TruVibeLabel` is `{oldSoul, healing, reflective, radiant, grounded,
mysterious}`. The vibe vocabulary is `{Reflective, Dreamy, Calm, Flirty,
Healing, Energetic, Creative}`. **They share `reflective` and `healing`.**

This is worse than the frozen-aura case rather than better. That bug was
*self-announcing*: 'Dreamy' had no Mood equivalent, so the mapping returned null
and something visibly broke. Two vocabularies that overlap fail silently
instead — a bare `reflective` cannot be attributed to a vocabulary by
inspection, by a reader or by code, so a misattributed value survives review and
looks correct in the database.

Not resolved here. The options are to make the two sets disjoint by renaming the
overlapping temperament values, or to accept the overlap and rely on the columns
never being crossed — which is the assumption that has already failed twice.

---

## Ordered work, and what is done

### 1. `profiles.vibe` was write-only — FIXED

Independent of the naming, and a user-facing bug: someone answered a question at
signup and the answer reached nothing.

`onboarding_vibe_screen` wrote `profiles.vibe`. The hydrate in
`AppProvider._syncCurrentUserFromSupabase` looked for `moodTags` / `mood_tags`,
and **`profiles` has neither column**. So the value never returned to the User
model. It survived only in local cache and vanished on a fresh device — which is
why `_hasVibe` scored zero and the completion banner read 54%.

The read now sources `profiles.vibe`.

> **Correction (2026-09-12): "FIXED" was only half true when written.**
> `AppProvider`'s own read sourced `profiles.vibe`, but `AppProvider` loads its
> cached user through `UserService.getCurrentUser()`, and that path still read
> `user_states.mood_tag` into the Vibe field. Mood kept reaching Vibe through
> the cache fallback after this section said it could not. Closed in `b343abe`,
> which also stopped `ProfileCompletionService._hasVibe` scoring a non-default
> temperament as Vibe. The last Mood read standing in for Vibe -- the
> onboarding gate's `needsOnboarding` -- is removed together with the gate;
> see `TruLura_PO_Decision_Onboarding_Gate_And_Defaults.md`.

**The old fallback was worse than absent.** It read `user_states.mood_tag` — the
Mood column — so `moodTags` silently backfilled from a different concept with a
disjoint value set. That is the exact sharing that froze the aura. Dropped
rather than kept as a backstop. Safe to drop: `profiles.vibe` is populated for
every existing user (`Dreamy`, `Dreamy`, `reflective`), so nothing was lost.

### 2. Check `persona` before renaming — DONE, AND IT BLOCKS THE RENAME

The instruction was: if `persona` is empty and `vibe_status` is doing persona's
job, they are one field with two names, so consolidate rather than rename.

Checked, and **they are not one field with two names.**

- **`profiles.persona` is a dead column.** Null for every user, and no code
  reads or writes it — verified by grep for the column name across `lib/`.
- **The word "Persona" is already taken in the UI, by something else entirely.**
  Profile setup Step 2 renders a "Persona" heading above `TruIdentityMode` chips
  — Social, Dating, Creator, Friendship — which write `active_identity_mode`,
  not `vibe_status`.

So renaming `vibe_status` to `persona` would collide with an existing, live
meaning and land the value in a column whose name already denotes identity mode
to every reader of the UI. That would create the same failure this record
exists to prevent, one word for two objects, in a new place.

**There are four things here, not three:**

| Column | Holds | Status |
|---|---|---|
| `profiles.vibe` | Reflective, Dreamy, Calm… | expressive state, live, now readable |
| `profiles.vibe_status` | oldSoul, grounded | dispositional temperament, live, misnamed |
| `profiles.active_identity_mode` | social, dating, creator… | identity layer — **this** is what the UI calls "Persona" |
| `profiles.persona` | null | dead column, no code, no data |

### 3. The rename — NOT DONE, needs a name that is not "persona"

`vibe_status` still needs a name that says what it is, but "persona" is not
available. Candidates worth considering: `temperament`, `disposition`. The
walkthrough's "Primary vibe" label needs to change with it.

`profiles.persona` should be dropped rather than repurposed — a dead column with
a contested name is a trap for whoever reads the schema next.

Neither is done, and neither should be guessed at.

---

## What this record does not decide

- The final name for `vibe_status`, and whether `profiles.persona` is dropped in
  the same migration.
- Whether signup should stop asking for **intent** and **interests**. Those two
  genuinely do duplicate the walkthrough — same destination
  (`matchmaking_profiles`), later flow wins — and are a separate decision. Vibe
  is not part of that question, which was the finding that prompted this record.
  Its prerequisite -- whether any profile field may gate entry to the app -- was
  decided on 2026-09-12 in `TruLura_PO_Decision_Onboarding_Gate_And_Defaults.md`:
  none may. Whether signup stops asking intent and interests is still open.

---

## Addendum — 2026-09-13: three rulings, and the rename

**Decided by:** Darcell (Product Owner), 2026-09-13
**Classification: Product Owner Decisions, 2026.** Rulings 1 and 3 confirm positions already written above. Ruling 2 is new and settles the hazard this record left open. Nothing above this addendum was rewritten; what it has made out of date is listed at the end.

### Ruling 1 — Vibe and temperament are two concepts, not one — CONFIRMED

- **`vibe`** — expressive, changes often: Reflective, Dreamy, Calm, Flirty, Healing, Energetic, Creative. Feeds the aura and the feed. Stored in `profiles.vibe`.
- **`temperament`** — dispositional, stable: oldSoul, grounded (the full set is oldSoul, mending, contemplative, radiant, grounded, mysterious). Stored in `profiles.temperament`.
- **Why:** collapsing them loses a real distinction, and sharing a column froze the aura state when 'Dreamy' had no Mood equivalent.
- This also settles the name, which *What this record does not decide* left open: the concept and its column are `temperament`.

### Ruling 2 — Vocabularies for distinct concepts must be disjoint — DECIDED

- On the temperament side, `reflective` is renamed `contemplative` and `healing` is renamed `mending`.
- **Why:** when two sets share values, a value in the wrong column cannot be detected by inspection, and an invariant you cannot verify is not one.
- This settles *And a hazard the rule does not yet cover* above, choosing the rename over relying on the columns never being crossed.

### Ruling 3 — No concept reads another concept's storage, even as a fallback, even when column names differ — CONFIRMED

- **Why:** the `moodTags` hydrate fell through to `user_states.mood_tag`. "No shared columns" would not have caught it, because the columns were different and the value path was shared.
- Already stated above under *The stronger form*; confirmed unchanged.

### State, measured 2026-09-14 03:27 UTC

- **The column rename is live.** Migration `20260914030033 rename_profiles_vibe_status_to_temperament` ran at 03:00:33 UTC. It renamed the column and set a column comment, and nothing else. `profiles.vibe_status` no longer exists.
- **Values:** temperament `oldSoul` ×2 and `grounded` ×1; vibe `Dreamy` ×2 and `reflective` ×1. No row held `reflective` or `healing` as a temperament, so Ruling 2 needed no data change.
- **Code:** `TruTemperament` already uses `contemplative` and `mending` (`lib/models/user.dart:475-485`).
- **Not enforced by the database.** `profiles` has no CHECK constraint on `vibe` or `temperament`. Disjointness is held only by the Dart enums and by review.
- **`profiles.persona` still exists.** The migration that ran did not drop it; whether to drop it is still open.
- **The repo migration file does not match what ran.** `supabase/migrations/20260910_rename_vibe_status_to_temperament.sql` still opens `NOT YET APPLIED`. Run now, its column rename is a no-op, its value rename touches no rows, and its step 2 **drops `profiles.persona`**. Its header needs correcting before anyone runs it. Not edited in this documentation-only pass.
- **Dead fallbacks, now removable:** `vibe_status` is still tried or read at `lib/services/user_service.dart:169` and `:504`, and `lib/providers/app_provider.dart:325`. `lib/models/user.dart:219` also reads it as an old local-cache key.

### Found today, not decided — a third vocabulary overlaps both

`CompatibilityService` labels quiz emotional tone `'reflective'`, `'playful'`, `'grounded'` and `'open'` (`lib/services/compatibility_service.dart:594-600`). `reflective` is a vibe value and `grounded` is a temperament value, so Ruling 2 is already broken in code, by a set neither record names. Where `emotionalTone` is stored, if anywhere, was not checked.

### Out of date above this addendum

- **`vibe_status` — dispositional temperament**, the four-column table, and *3. The rename — NOT DONE*: the column is now `temperament`, and the rename is live.
- **And a hazard the rule does not yet cover**: settled by Ruling 2.
- **What this record does not decide**, first bullet: the name is decided. Whether `profiles.persona` is dropped is still open. *(Decided 2026-09-14 — see* Addendum — 2026-09-14 *below.)*

---

## Addendum — 2026-09-14: persona dropped, and Vibe is Aura

**Decided by:** Darcell (Product Owner), 2026-09-14
**Classification: Product Owner Decisions, 2026 — Class D in the Product Owner's tracker.** Nothing above this addendum was rewritten.

### Ruling 4 — `profiles.persona` is dropped — DECIDED, APPLIED 2026-09-14

> "Drop it"

- **Stated with the ruling:** "Empty column, no readers, and the word is already used in the UI for active_identity_mode."
- **How:** apply the repo's own `supabase/migrations/20260910_rename_vibe_status_to_temperament.sql` unchanged. Its rename step is guarded and will no-op, its value step rewrites any temperament `reflective`/`healing` to `contemplative`/`mending`, and its step 2 drops `persona`.
- **Irreversible.** The column must be verified all-null immediately before the file runs, not from an earlier check.
- **Status, 2026-09-14 18:54 UTC:** verified immediately before the attempt — `persona` null in 3 of 3 rows; no view, function, policy, index or constraint depends on it; no temperament row holds `reflective` or `healing`. **The file was not applied:** the session's permission layer blocked the migration. `profiles.persona` still exists. That check is now a snapshot and must be repeated before the file runs.
- **Applied, 2026-09-14, by the Product Owner in the Supabase SQL editor.** A guarded block raised an exception if any row held a non-null `persona`, and dropped the column in the same transaction; its verification query returned exactly `temperament` and `vibe`.
- **Confirmed independently at 22:12:01 UTC:** of `persona`, `vibe_status`, `temperament` and `vibe`, `profiles` now has only `temperament` and `vibe`; 3 rows; temperament `grounded` ×1 and `oldSoul` ×2; 0 rows hold `reflective` or `healing`.
- **Not by the method recorded above.** The repo file was not run. Its value updates (1b) had no rows to change, but its fuller `temperament` column comment was not applied. The drop is not in `supabase_migrations.schema_migrations`, because the SQL editor does not record one; the only related entry is `20260914030033 rename_profiles_vibe_status_to_temperament`.
- **The migration file now says so** in a header above its original text: both of its structural steps are live, and its step 2 will no-op.
- Settles *What this record does not decide*, first bullet.

### Ruling 5 — Vibe is Aura

> "Vibe is aura and mood is mood"

### Ruling 6 — Vibe is Layer 1, Aura (identity)

> "Vibe is your aura who you are you personality energy character presence your aura is what tell the room your presence either you shine or you dont aura exposes who you are. Vibe is what that aura says about you"

- Recorded in full, with the reversal of the Class D findings it causes, in `TruLura_PO_Decision_Aura_Architecture.md`, *Rulings — Vibe is Aura, Layer 1*.
- **This record now contradicts itself, and is not resolved here.** Ruling 1 (2026-09-13) describes vibe as "expressive, changes often" and draws the line against temperament as "dispositional, stable". Layer 1 is persistent identity. Whether the vibe/temperament distinction still holds, and on what basis, is for the Product Owner.

### The rename scope — every site reading or writing `profiles.vibe` or `User.moodTags`, as of 2026-09-14

Measured against the working tree, uncommitted changes included. Nothing was changed.

**Database**

- `public.profiles.vibe` — text, nullable, no column comment.
- `public.profiles_public` exposes `vibe` to every signed-in user.
- No function, policy, index or constraint references it.
- Migrations that name it: `20260907_separate_vibe_from_mood.sql`, `20260908_null_the_clobbered_vibe.sql`, `20260910_rename_vibe_status_to_temperament.sql` (column comment on `temperament`), `20260914_profiles_scope_reads.sql` (the view).

**Writes to `profiles.vibe`**

- `lib/services/user_service.dart` → `_persistVibe(userId, moodTags)` writes `'vibe'` (lines 143-153); called from `saveUser` when `dirty.contains('moodTags')` (lines 635-640).
- `lib/features/onboarding/onboarding_vibe_screen.dart:45` sets `moodTags` via `copyWith`, which reaches `_persistVibe` through `saveUser`.

**Reads of `profiles.vibe`**

- `lib/models/user.dart` → `User.vibeFromJson` reads `'vibe'`, falling back to the cache keys `moodTags` / `mood_tags` (lines 138-145); used by `User.fromJson` (line 163).
- `lib/services/user_service.dart` → `readOwnVibe` selects `vibe` (lines 560-572); `'moodTags': User.vibeFromJson(row)` (line 351); `User.vibeFromJson(profile)` (lines 504-506).
- `lib/providers/app_provider.dart` → `_syncCurrentUserFromSupabase` hydrates it and stores it back under the key `normalizedProfile['moodTags']` (lines 270-280).

**The model field `User.moodTags`**

- `lib/models/user.dart`: declaration (15), constructor (66), `toJson` key `'moodTags'` — also the local cache key (103), `fromJson` (145, 163), `copyWith` (266, 300, 351).

**Readers of `moodTags`, including every `moods:` that carries it**

- `lib/providers/app_provider.dart:115` — `moods:` into `TruEmotionalPresenceState.derive` (`lib/models/emotional_presence_state.dart:53-60`). The same call passes **temperament** as `vibe:` (line 114).
- `lib/screens/profile/profile_screen.dart` — `mood:` (397-398), `moodSignature` (528-529), `hasVibes` (1070), `final moods = u!.moodTags` (1091) into `_weatherForVibes(moods, vibe)` (1111, 1162) and `_VibeClusterField(moods:)` (1117; field at 1969, 1973).
- `lib/widgets/trulura_profile_hero_card.dart:34-36` — `mood`, into `identityAccent`.
- `lib/screens/home/home_feed_screen.dart` — `_moodAccentFor` through `MoodColors.glow`, a Mood palette (137); the empty-feed copy's `vibe` (567).
- `lib/screens/home/home_hub_screen.dart:482` — `hasMood`.
- `lib/screens/sync/sync_screen.dart:170` — `hasMood`.
- `lib/screens/ai/ai_companion_screen.dart:218-219` — rendered as "… mood signal".
- `lib/widgets/trulura_ai_suggestions_sheet.dart:46` — `mood`.
- `lib/widgets/trulura_event_carousel_row.dart:26` — `mood`.
- `lib/services/compatibility_service.dart:215` — part of a cache key.
- `lib/services/profile_completion_service.dart:155` — `_hasVibe`.
- `lib/services/sync_service/sync_service.dart:491` — spread into `target` tags.

**Tests**

- `test/vibe_hydration_test.dart` (lines 7-21), `test/profile_completion_status_test.dart` and `test/profile_completion_vibe_test.dart` (the `vibe` key), `test/sign_in_destination_test.dart` (`VibeRead`).

**Same words, not in scope — a rename must not sweep these up**

- **Temperament called `vibe`:** `app_provider.dart:114`; `profile_screen.dart:132, 263, 309, 395, 521, 1090`; `trulura_profile_hero_card.dart:37`; `feed_demo_content_service.dart:19`. These hold `TruTemperament.label`, a separate misnaming.
- **Post moods called `moods`:** `create_post_screen.dart:448` and `trulura_post_composer.dart:21, 49, 247` — the composer's mood choices for a post.
- **`AuraState.vibeTags`:** Mood-derived tags (`aura_state.dart:20-141`).
- **Other vibe-named storage:** `profiles.expression_vibe_tag` (the profile-setup free-text "Vibe tag", `User.expressionVibeTag`), `profiles.expression_vibe` and `glow_posts.vibe` (no code reads either), `user_settings.ask_vibe_at_startup` and `remember_last_vibe`.
- **Display labels:** `feed_card.dart` `vibeLabel`, and `vibe` in `feed_card_presentation.dart` / `compact_feed_card_presentation.dart`, which show a post's mood tag.
- `test/compact_feed_mood_harness_test.dart` `moodTags` — a local list of post mood tags.

### Still open: the overlap is now Aura/Mood

Four of the five Mood values (reflective, flirty, calm, healing) are also Vibe values. Under Ruling 5 that is an Aura/Mood overlap. Recorded with evidence in `TruLura_PO_Decision_Aura_Architecture.md`, *Still open: the vocabulary overlap moved*. Ruling 2 of 2026-09-13 applies; no rename is chosen.
