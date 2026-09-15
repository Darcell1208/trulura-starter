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

Read from `docs/02-Product/TruLura_Blueprint.md`:

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

A change routing signup into the questions as an ordinary next screen was
drafted, held, and not committed. Two findings on 2026-09-13 explain why:

- **The wording it relied on is the Product Owner's, but about vibe.** The
  ruling of 2026-09-10 (user message in session `f82cfc6c`, 03:57 UTC) reads:
  "This is what signup asks for and it should keep asking." That ruling covers
  **vibe**; the draft routed to the intent screen.
- **Code placed after signup never runs on this project.** Email confirmation
  is required: `mailer_autoconfirm: false`, read from the live auth settings
  endpoint at 2026-09-13 03:43 UTC. A new account gets no session at signup and
  is sent to sign-in, so the first real entry point is sign-in.

Chosen instead, and implemented: option (b). The draft that routed signup to
the intent screen was reverted before it was ever committed.

On sign-in, `UserService.readOwnVibe` reads `profiles.vibe` and returns one of
three states:

| State | Destination |
|---|---|
| read, empty | `/onboarding/vibe`, with Home as the return address so Skip shows |
| read, set | Home |
| unknown — the query failed, or no row came back | Home, unasked |

A failed read must not look like an empty vibe, which is why "unknown" is its
own state. Nothing is stored: "once" is the condition itself. A user who skips
is asked again at their next sign-in, and the behaviour follows the account,
not the device.

**Verification status.**
- **Unit-tested:** the destination for all three states
  (`test/sign_in_destination_test.dart`).
- **Not observed:** the positive route has not been seen in the running app.
  Every live account has a vibe, and a new signup depends on SMTP.
- **To observe:** the failure route, by blocking `*/rest/v1/profiles*` in
  browser DevTools during sign-in.
- **Not tested at all:** `readOwnVibe` itself, which needs a live client.

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
- **Scorer thresholds and scope.** Settled on 2026-09-13: the status label now
  derives from the section checks, the dead branches are deleted (`60c1bc6`),
  and the vibe section is labelled "Vibe" (`95d0015`). Still open: whether
  discovery-ready should be looser so a middle tier exists, and the scope of
  what the completion score counts.
- **Class C — collect Vibe on the signup form and carry it into the profile
  row through auth metadata.** Recorded, not implemented. *(The Class A–E
  classification comes from the Product Owner's open-decisions tracker and is
  not defined in this repository; a search of `docs/` for "Class [A-E]"
  returned nothing on 2026-09-13.)*

  **The proposal.** The signup form passes the chosen vibe in `signUp` user
  metadata, alongside the `name` it already sends. The `on_auth_user_created`
  trigger (`public.handle_new_user`, read from the live database on
  2026-09-13) already inserts the `profiles` row from the new `auth.users` row,
  so it can write `profiles.vibe` from `raw_user_meta_data` in the same
  transaction. Nothing is held on the client.

  **Why it is a candidate.** It is the literal reading of "signup asks". It is
  also the only option under which a user's first Home already has an aura.

  **What deciding it needs.**
  - User metadata is client-controlled, so the trigger has to accept only the
    seven Vibe values and write NULL otherwise.
  - When this was written, the trigger set `username` and `display_name` to
    the part of the email before the @. That is a default counted as an
    answer, and it is tracked separately below. Since 2026-09-14
    (`20260914132443`) the trigger writes a NULL `username`; `display_name` is
    still email-derived.
- **Signup fails when two emails share a local part — a signup-failure bug, not
  a cosmetic default.**
  - **The cause:** `handle_new_user` writes the email's local part to
    `profiles.username`, which is `UNIQUE` (`profiles_username_key`).
    `on conflict (id) do nothing` guards duplicate ids, not duplicate
    usernames. So a second address with the same local part (`alex@` at two
    domains) violates the constraint inside the trigger, and the whole signup
    transaction rolls back. Confirmed 2026-09-13 with a rolled-back probe that
    raised `unique_violation`.
  - **What the client sees:** GoTrue answers 500 ("Database error saving new
    user"), which gotrue-dart raises as `AuthRetryableFetchException` carrying
    the raw response body. `sign_up_screen` shows that raw body in a SnackBar.
    Read from the code, not observed.
  - **So the failure is surfaced, not swallowed**, but it is uninformative, it
    is labelled "retryable" when a retry can never succeed, and the user cannot
    fix it, because signup does not ask for a username.
  - **Status — FIXED 2026-09-14.** Option 1 shipped with all three parts
    below, at the Product Owner's direction; the hold on the `display_name`
    naming decision was lifted for the username only.
    - **Database:** live migration `20260914132443 handle_new_user_null_username`
      (`supabase/migrations/20260914_handle_new_user_null_username.sql`).
    - **Client, parts 2 and 3:** commit `bcc397b`.
    - **Evidence:** reproduced before fixing (`23505` on
      `profiles_username_key`). Verified after applying, against the live
      function: two signups sharing a local part both succeed, with NULL
      usernames (probe rolled back).
    - **Still true:** `display_name` stays email-derived until the naming
      decision, and clients built before `bcc397b` still write `''` for an empty
      username until rebuilt.
  - **Status as recorded 2026-09-13:** fix proposed, not applied. Option 1 (a
    NULL username) is held on the `display_name` naming decision. When it
    lands, it ships as one change with three parts:
    1. The trigger writes a NULL username. `display_name` stays email-derived
       until the naming decision.
    2. `user_service.dart:186` writes NULL, not `''`, for an empty username.
       Otherwise the collision moves to the second account's first save, where
       `saveUser` swallows it.
    3. A row-only guard in `UserService.getCurrentUser`
       (`user_service.dart:453-456`): when the profiles row was fetched, the
       username comes from the row only.

    **Part 3 is an unmask-preventer, not a cache fix.**
    - **Why it is needed:** today a non-empty row username always wins, which
      hides the fact that an empty one falls back to the device-global
      `current_user` cache. Under option 1 the previous account's username
      would appear, and be saved back, for a new account on a shared device.
    - **What it does not do:** fix that cache. The cache leaks many other
      fields and is its own item (Build Status #17).

    **Not part of this fix:** `app_provider.dart:236-238` falls back to the auth
    metadata username. That does not affect accounts created under option 1,
    because signup writes no metadata username. It does matter for the separate
    step of clearing existing rows, and is decided there.
- **Email-derived names are visible to other users.**
  - **Where:** Sync, Explore, feed authors and chat all render other users'
    `display_name` and `username`. The guard in `User.publicDisplayNameFrom`
    cannot fire for other users, because their loaded profiles carry no email.
    `profiles_select_authenticated` is `USING (true)`. *(As recorded
    2026-09-13 — see the update below.)*
  - **Update 2026-09-14 — the open read is closed; the names are not.**
    - **What changed:** `profiles_select_authenticated` was dropped by live
      migration `20260914132439 profiles_scope_reads`
      (`supabase/migrations/20260914_profiles_scope_reads.sql`, client commit
      `8da2bf8`). A signed-in user now reads only their own row of
      `profiles`. Other people come through `public.profiles_public`, an
      owner-executed view with a ten-column allowlist, granted to
      `authenticated` only. Verified by role against the applied change.
    - **What did not change:** that allowlist includes `username` and
      `display_name`, so the email-derived names on `350201ed` and `d56a61aa`
      are still visible to every signed-in user until IC-4 clears them.
    - **Not filtered at all:** the view does not honour a profile's privacy
      setting, because no database column holds one.
  - **Snapshot:** before anything touches them, the current `username` and
    `display_name` of all three rows were saved to
    `private/profiles_name_snapshot_2026-09-13.json`. It is gitignored and
    never committed, because this repository is public.
  - **Which rows:** `d9fa2f57` has a hand-set username and display name;
    `350201ed` and `d56a61aa` have both email-derived.
  - **Clearing** any row is a data write, blocked on the naming decision.
