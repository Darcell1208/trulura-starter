# TruLura Product Owner Decision Record — Vibe, Temperament & Mood

**Decision date:** 2026-09-10
**Decided by:** Darcell (Product Owner)
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
