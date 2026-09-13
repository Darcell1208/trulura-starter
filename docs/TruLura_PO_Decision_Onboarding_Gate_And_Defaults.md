# TruLura Product Owner Decision Record — Onboarding Gate & Defaults Counted as Answers

**Decision date:** 2026-09-12
**Decided by:** Darcell (Product Owner)
**Classification: Product Owner Decision, 2026 — NOT a Recovered Historical Decision.**
The Blueprint places gates on features and restricted modes, and describes
intent selection as something that happens during onboarding. It does not say
that any profile field gates entry to the app, and it does not address whether
a default may stand in for a user's answer. Both positions below are authored
here. The search that supports that negative finding is recorded under
Decision 1. Companion to `TruLura_PO_Decision_Vibe_And_Temperament.md`, whose
open question about signup this record narrows but does not settle.

---

## Decision 1 — Nothing gates entry to the app except being signed in

> "Gate on nothing. The router already requires being signed in; that's the
> gate. Reasoning: every field-based gate keeps the lockout failure mode
> available, one flow change away. An empty aura is a scoring problem, not a
> lockout."

### What it replaced

`AppProvider.needsOnboarding` required an intent **and** a vibe. The router
(`app_router.dart`) and `splash_screen.dart` redirected every route to
`/onboarding/intent` until both existed. Its "has a vibe" check also accepted
`user_states.mood_tag` — a Mood standing in for Vibe, the collision the Vibe
record forbids.

### Why

The case that exposed it: the proposal on the table was to stop asking intent
at signup. With the gate in place, that change would not have deferred the
question. It would have locked every new user out of the app entirely,
including out of the profile walkthrough that is the other place intent is
collected. The gate made a copy change into an access change.

That is true of any field-based gate, not just intent. Whatever field a gate
requires, it stays one flow edit away from the same lockout. A profile that is
missing answers yields a weaker aura, a thinner feed and a lower completion
score. Those are scoring problems, handled where scoring happens, not access
problems.

### What it rests on

Read from `docs/02-Product/TruLura_Blueprint.md.md`:

- **§1.2 Verification Layers System:** "Verification is optional at onboarding
  but required for key features." The gate is attached to features, not entry.
- **§2.1 Experience Modes & Participation System**, *When it activates*: "On
  onboarding (initial intent selection)". Intent selection is named as a
  trigger that activates a mode, not as a condition for entry.
- **§2.1.2 Identity Integration**, *When it activates*: "Before entering
  restricted modes (Romantic, Luxe, Monetization)". The Blueprint's gates are
  on restricted modes.
- **§3.1 Mode Architecture & Context Control Layer:** "Direct user selection
  during onboarding or manual switching", and "The system does not force
  transitions unless required for safety or compliance."

**Negative finding.** The Blueprint file was searched for
`before (they|users|a user|accessing|entering)|must (complete|finish)|required (before|to (enter|access|use))|locked out|block(ed)? (from|access)`
(case-insensitive). There were four matches:
- line 870, restricted modes, quoted above
- line 9256, "Required before deeper interaction stages (media, meetups, etc.)"
- two unrelated uses about detecting problems early

None requires a profile field before entering the app.

### Cost accepted deliberately

- Users can reach the app with no vibe, intent or interests. The aura, feed and
  Sync start with fewer signals.
- The completion score now has to represent missing answers honestly, which is
  what Decision 2 is for.
- `SyncService` lets a user with no intent pass every purpose filter
  (`sync_service.dart`, candidate filter). That behaviour predates this
  decision, but more users will now be in that state.

### What removing the gate also removed

The gate was the only thing that routed a new account through the entry
questions. With it gone, signup, sign-in and splash all go to Home. A new
account is not asked for a vibe, intent or interests unless a Home prompt
leads them there.

Routing signup into the questions as an ordinary next screen is a separate
change, held for review. Whether signup must keep asking rests on the Vibe
record's wording, and that wording is being checked against the Product
Owner's own words before the routing is committed.

**Guardrail:** do not reintroduce a field check in the router redirect. The
comment there points to this record.

---

## Decision 2 — A default must never count as an answer

> "They're one class, not two: a default counted as an answer. A cached value
> standing in for a saved one, and 'Social' written by default earning intent's
> 10 points. Same shape as _hasVibe counting a temperament."

### The class

A value the user did not give is treated as though they gave it. It then scores,
displays or routes as their answer. The source varies:

- another concept's storage
- a local cache
- a hardcoded default written to the database

The effect is always the same, and it is worse than a null. A null is visibly
missing; a default looks like data.

This generalises the Vibe record's rule — "if the right column is empty, the
correct answer is empty". That record forbids reading another concept's
storage. This one forbids treating **any** value the user did not supply as
their answer.

### Instances found and fixed

1. **Another concept's storage.** `ProfileCompletionService._hasVibe` scored a
   non-default temperament as Vibe. Fixed in `b343abe`.
2. **A cache standing in for a saved value.** `AppProvider`'s hydrate and
   `UserService.getCurrentUser` fell back to the local cache whenever the
   fetched value was empty. The affected fields were intents, interests, social
   preference and the three expression fields, plus bio and photo in
   `UserService`. A save that never reached the server kept scoring as saved.
   The rule now: a fetched value is authoritative, including when it is empty,
   and the cache is used only when nothing was fetched (the request failed, or
   there is no `profiles` row).
3. **A default written to the database.** Two save paths wrote `intent =
   'Social'` when no intent existed: `UserService._persistMatchmakingProfile`
   on insert, and `UserService.saveInterests` on every interests save. The
   value read back as the user's choice and earned intent's 10 completion
   points. Neither path writes an intent the user did not choose anymore.

### Cost accepted deliberately

A save that fails now shows up as missing on the next load, instead of being
masked by the cache. That is intended: visibly missing beats silently wrong.

### Known remaining instances — listed, not decided

- **Existing data.** `matchmaking_profiles` holds one row with `intent =
  'Social'` (measured 2026-09-13 02:33 UTC). Nothing records whether it was
  chosen or defaulted, so it is left as is rather than guessed at.
- **Hydrate defaults in `AppProvider`.** `age` 18, `activeIdentityMode`
  'social', temperament falling back to 'oldSoul', and `trustScore` 70. None is
  scored today, but each has the same shape, and scoring any of them would
  reintroduce the bug.
- **Display defaults.** `trulura_profile_hero_card.dart` shows 'Social' when
  intent is empty.

### Not instances, and why

- **Location, pronouns and languages** keep their cache fallback. `profiles`
  has no column for them, so the cache is their only store, not a stand-in for
  a saved value.
- **Username** falls back to auth `user_metadata`. That is a server-saved store
  of the same concept, not a cache.

---

## Still open

- **Whether signup stops asking intent and interests.** This record removes the
  gate that made that question dangerous; it does not answer it. §2.1 names
  "initial intent selection" during onboarding as a mode activation trigger, so
  that decision will have to address it.
- **Scorer labels and thresholds** (the status label, the unreachable tier, and
  "Identity" meaning Vibe), and the scope of what the completion score counts.
  Raised on 2026-09-12 and not decided here.
