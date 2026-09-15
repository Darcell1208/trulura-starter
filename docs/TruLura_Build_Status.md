# TruLura — Build Status

*Status page, not a spec. The Blueprint is the spec. Written 2026-09-07 and
last updated **2026-09-08** from the live database and the repo, not from
memory. Every "verified" claim below names how it was checked.*

*A stale status page is worse than none, because agents read it as current and
reason from it. This page listed feature 5 as unstarted for most of 2026-09-08
while blocks and reports were landing; anything written here should be
re-checked against the live database before it is acted on.*

---

## Core features

The Blueprint's "Core Loop" (§2.6) is a data-flow, not a feature list. The rows
below track the Implementation Roadmap's **Core Beta backbone** (sections 1,
2/3, 4, 5, 9, 12) plus the delivery-order features actually being built.

One of the six delivery-order features is named but not started:
**6 — invite-only signup**. Feature **5 — block / report** landed on
2026-09-08 (crisis explicitly excluded, and `moderation_events` / `safety_flags`
remain service-role-only with no application code).

| # | Feature | State | Verified how |
|---|---|---|---|
| 1 | **Identity & Trust** (§1) | Built | `identity_core` table + `identity_core_repository.dart`; screen wired in `02151fa`. Not verified by role. |
| 2 | **Experience Modes** (§2/3) | Partial | `experience_mode_service.dart` exists; no dedicated table. Not verified. |
| 3 | **Discovery / Aura feed** (§4) | Built | Real posts via `posts_feed`. Anonymous rows return `user_id = null`; private posts return only to their author since `6cef368`; Vent excluded entirely since `8484ab0`. All verified by role, both directions. |
| 4 | **Profile** (§5) | Partial | `profiles` table + profile screens. Read access verified by role (authenticated sees others, anon sees none). |
| 5 | **Safety — block / report** (§9, §9.14) | Built, not enforced | Blocks and reports persist to `public.blocks` / `public.reports` (`1c7670a`). Schema verified by role, CHECK constraints confirmed to fire by attempting violating inserts in rolled-back transactions. **A block does not yet stop anything**: messaging RLS does not consult `blocks`. That is phase 3, deliberately held. Not exercised through the UI. |
| — | **Vent** (§9.8 adjacent) | Partial | `vent_feed` view contains Vent, `posts_feed` excludes it; containment verified by role both directions. **On `origin`, Vent Sanctuary threw during layout until the commit that adds this text:** `SliverFillRemaining(hasScrollBody: false)` asked a `ListView` for its intrinsic height (`RenderViewport does not support returning intrinsic dimensions`), reproduced 2026-09-14 in a clean checkout of `57276b8`; by code reading, a failed load also showed as an empty feed. **UI-verified 2026-09-14** in the browser as `d9fa2f57`: 3 cards, all that account's own, matching the API log (`vent_feed`, 3 rows) and a by-role replay. Vent membership is still stored in two fields — known issue 20. |
| 6 | **MoodSync** (§12) | Built + verified | `MoodSyncService` writes `user_states.mood_tag` (current) and appends to `mood_states` (history); `AuraStateController.updateMood` persists, `initialize()` hydrates. Per-user isolation verified by role. **Verified in the UI**: mood set, app closed and reopened, mood survived; confirmed server-side (`mood_tag='flirty'`, 1 history row). |
| — | **Messaging** | Built + verified | Only feature verified at every layer: by role in SQL, and a two-window browser test where a message crossed sessions without a refresh. |

**Verification depth is uneven.** Messaging and MoodSync are the only features
exercised through the UI. Everything else is "the code exists and compiles",
or in the case of block/report/Vent, "the database layer is verified by role
and the Dart is unexercised." Those are different claims and the difference
matters.

---

## Database

45 tables in `public`, **all with RLS enabled**, all with at least one policy.

**Messaging** (the only fully-verified slice):

| Table | Policies | Realtime | Replica identity |
|---|---|---|---|
| `conversations` | `conversations_select_member` (SELECT) | yes | `d` |
| `conversation_members` | `conversation_members_select_member` (SELECT) | yes | `d` |
| `messages` | `messages_select_member` (SELECT), `messages_insert_sender_member` (INSERT) | yes | `f` |

No UPDATE or DELETE policy on any of the three — edit and delete are denied by
default, deliberately. Conversation and membership creation is reachable **only**
through `public.start_direct_conversation(uuid)` (SECURITY DEFINER); the client
INSERT policies were dropped, see Known issues.

**Tested by role** (`set local role` + JWT claims, in rolled-back transactions):

- Two members each see the conversation, both membership rows, and all messages.
- A non-member sees **0** messages, 0 conversations, 0 member rows — including a
  targeted read of the exact conversation UUID, and through `conversation_list`.
- Non-member insert blocked (42501); forging another user's `sender_id` blocked;
  blank message rejected (23514); `anon` denied entirely.
- `authenticated` can read other users' `profiles` rows; `anon` sees none.
- Anonymous `posts` rows return `user_id = null` through `posts_feed`.

**MoodSync**: `user_states` (current, one row per user, live) and
`mood_states` (history, `user_id NOT NULL`, `created_at timestamptz`). Verified
by role that each user reads only their own history — a targeted query for
another user's rows returns 0, cross-user writes are blocked (42501), and anon
sees nothing.

**Realtime publication** `supabase_realtime` contains 7 public tables:
`conversations`, `conversation_members`, `messages`, `device_users`,
`glow_sessions`, `sparks`, `vents`. (`moods` and `mood_events` were dropped
with the tables themselves in `20260907_moodsync_foundation`.)

---

## Open Product Owner decisions

Full register: [`02-Product/TruLura_Product-Decisions.md.md`](02-Product/TruLura_Product-Decisions.md.md).
Top blockers, unchanged:

| ID | Blocks | Question |
|---|---|---|
| **PD-14** | §10, §20 — *Critical* | Two contradictory primary-navigation structures (3 tabs vs 4 items). Blocks the app shell. |
| **PD-12** | §9, §14, §15 — *High* | Crisis-detection mechanism undefined. Needs Trust & Safety, not an engineering guess. |
| **PD-01 / PD-15** | §1, §2, §9, §16 — *Critical* | Trust/verification tier naming is a four-way conflict. Blocks permission logic. |
| PD-07 | §7/8 — *High* | Exact revenue splits and payout mechanics. Explicitly left open by the v2.1 approval. |
| PD-18 | §17 — *High* | TruLuxe qualification algorithm; anti-discrimination review needed. Also left open by v2.1. |
| PD-19 | §1.2, §7/8 | Payment processor and identity-verification vendor not selected. |
| PD-20 | §22 | Data retention policy undefined. |

---

## Known issues

**Security / data**

1. `20260904_messaging_core.sql` is **destructive to replay** — it recreates two
   INSERT policies that `20260907_close_self_join_hole.sql` dropped, silently
   reopening an escalation where knowing a conversation UUID lets any
   authenticated user join it. Both file headers now warn. Do not re-run.
2. `identity_core`'s three policies and `profiles_update_own` are scoped
   `to public` rather than `to authenticated`. Harmless today (anon holds no
   grants, `auth.uid()` is null) but the wrong default.
3. ~~`post_reactions` overlapping SELECT policies~~ — **fixed**
   (`20260907_close_post_reactions_anon_read`). `post_reactions_read_all` was
   `to {anon, authenticated} using (true)`, so anon could read `user_id` and
   `post_id` for every reaction, on posts anon cannot itself read. Policy
   dropped and anon's grants revoked; anon now fails at the privilege layer.
4. `conversations` and `conversation_members` are `replica identity d`, so
   DELETE events won't carry enough for RLS to evaluate. Inert until something
   deletes — fix alongside any future delete policy.
17. **Privacy controls can carry over to the next account signed in on a
    device.** This is a correctness bug in privacy controls, not a display
    leak (failure class A: device-global where account-scoped was required).
    Logged 2026-09-13 and ranked into Security / data the same day. Read from
    the code, not observed.
    - **What goes wrong:** an account can inherit the previous account's
      `profileVisibility` and `allowScreenshots`, and also `messageAutoDelete`,
      `showVerificationBadge` and `showTrustIndicator`. These are settings a
      person relies on to limit who sees them and what can be captured. An
      account can end up running on someone else's choice without ever having
      made one.
    - **Why:** `UserService` keeps a single `SharedPreferences` key,
      `current_user`, for the whole device, and `_getCachedCurrentUser`
      (`user_service.dart:656-666`) never checks whose record it is.
      `_fromAuthUser` builds the signed-in user on top of that cache, and both
      `UserService.getCurrentUser` and `AppProvider`'s hydrate take the privacy
      toggles from it **even when the profiles row is fetched**.
    - **When it is cleared:** only by the Settings sign-out button
      (`settings_screen.dart:244-245` → `UserService.logout`,
      `user_service.dart:650`). It is **not** cleared when:
      - the session expires,
      - `AuthService.signOut` throws (it rethrows, so `logout` never runs),
      - sign-out goes through `SupabaseAuthManager.signOut`.
    - **It persists.** Each load re-caches the inherited values under the new
      account, and the next `saveUser` can write some of them (username,
      temperament, identity mode) to the new account's server row.
    - **Other fields inherited the same way:**
      - **Even with a fetched row:** age, location, pronouns, languages,
        verification level, trust score, risk level, and `createdAt`.
      - **When the row's value is empty:** name, username, temperament and
        identity mode.
      - **When Supabase is not ready:** the entire cached user.
    - **Status:** not fixed. Scoping the cache to the account is its own change.
      The row-only username guard that shipped with #16's option 1 (commit
      `bcc397b`, 2026-09-14) covers one field on one path and must not be read
      as addressing this.
- ~~**Any signed-in user could read every `profiles` row**
  (`profiles_select_authenticated` was `USING (true)`).~~ — **fixed
  2026-09-14.**
  - **Fix:** live migration `20260914132439 profiles_scope_reads`, client
    commit `8da2bf8`. The table is own-row only; other people are read through
    `profiles_public` (a ten-column allowlist, authenticated only).
  - **Still true:** no filter by a profile's privacy setting, because no
    column holds one; email-derived names stay visible until IC-4.
  - **Record:** `TruLura_PO_Decision_Onboarding_Gate_And_Defaults.md`.
- ~~**Any signed-in user could read every `comments` row, which would identify
  anonymous Vent authors**
  (`comments_select_authenticated` was `USING (true)`).~~ — **fixed
  2026-09-14,** while the table was empty.
  - **Fix:** live migration `20260914133748 comments_select_own_only`. Own
    rows only, and `anon` holds no privileges.
  - **Still owed before comments ship:** the read view that nulls authors on
    anonymous posts —
    `TruLura_PO_Decision_Vent_Identity_And_Blocking.md` §2b.

**Realtime**

5. `posts` and `post_reactions` are **not** in `supabase_realtime`, so the two
   `postgres_changes` subscriptions in `HomeFeedScreen` have never fired. The
   feed works only via initial load and pull-to-refresh.

**Messaging UI**

6. Browser URL stays at `#/messages` while a thread renders — refreshing an open
   thread returns to the inbox, and thread links aren't shareable. Suspected
   `StatefulShellRoute.indexedStack` branch-location handling; not diagnosed.
7. The skeleton-flash fix on incoming messages is unconfirmed — not observed
   either way during the two-window test.
8. New Message is reachable only from the chat-list FAB. No "message this
   person" from a profile or from Sync.
9. Chat-list pin and archive are in-memory only; they reset on reload.
10. `ChatService.ensureChatWithUser` still catches every error and returns
    `null` — a silent failure on the Sync path. The New Message screen
    deliberately uses `startDirectConversation`, which throws instead.

**Coverage**

11. MoodSync persists but has no UI surface of its own: `moodPattern()` (the
    §5.6.3 pattern over time) has no caller yet, and no screen shows mood
    history. `intensity` is never written — `recordMood` accepts it, nothing
    passes it — and its `0..100` CHECK is a sanity bound, not the product
    scale, which the Blueprint never defines.
14. ~~`profiles.vibe` for `d9fa2f57` holds `'flirty'`~~ — **closed, decided,
    do not reopen** (`5e55eb1`). The value was nulled rather than restored, at
    the Product Owner's explicit direction: *"I picked it quickly during
    onboarding and don't actually remember — restoring a guessed value isn't
    better than an empty one."* `'Reflective'` is recorded in the header of
    `20260907_separate_vibe_from_mood.sql`, so it is not decaying, but a former
    value is not a true one and writing it back would be indistinguishable from
    a real choice. This was raised again on 2026-09-08 from this page and
    declined. Leave it NULL.
12. No automated tests cover any of the above. Every verification recorded here
    was run by hand.
13. Four tracked files are zero bytes *(re-measured 2026-09-14; fourteen when
    first logged)*: the `src/storage/*.js` stubs in the legacy Expo app,
    including `ventStore.js`, which reads as Vent storage and is not.
    - **No longer empty, 2026-09-14:**
      - `docs/DOCUMENTATION-STANDARDS.md`, written in `dd9c450`.
      - The eight folder READMEs, `docs/01-Constitution` to `docs/08-Business`,
        and `docs/02-Product/TruLura_Product_Decision_Log.md`. Each now has a
        header: committed empty on 2026-08-23 (`f45fbf9`), never held content,
        and where the real content lives. They were given headers rather than
        deleted because other documents cite them.
    - **Settled 2026-09-14 by Product Owner ruling:** decisions that have
      been made live in `docs/TruLura_PO_Decision_*.md`; open product questions
      live in the Product Decisions Register,
      `docs/02-Product/TruLura_Product-Decisions.md.md`, until ruled. The
      Documentation Constitution and Guiding Principles #10 were corrected to
      say so, and the Constitution's claim that three READMEs state the rule
      "independently" was removed.

**Account scoping**

15. **Home prompt dismissals are device-scoped where account-scoped was
    needed** (failure class A). Logged 2026-09-13.
    - **Where:** `AppSettingsService.getDismissedHomePromptStatuses` /
      `setDismissedHomePromptStatuses` store the "Set your vibe", "Choose your
      intent" and profile prompt dismissals in `SharedPreferences`.
    - **How it is keyed:** per user id, falling back to a device-global key
      when the per-user key is absent (`app_settings_service.dart`, around
      lines 635-642).
    - **What breaks:**
      - A `permanent` dismissal hides that prompt for good on that device only.
      - The same account on a new device sees it again.
      - Through the global fallback, another account on the same device can
        inherit a dismissal.
    - **Why it matters now:** the Home "Set your vibe" prompt is the only
      non-signup route to asking for a vibe. Not fixed.
16. ~~**A username collision at signup is reported as retryable, and the user
    cannot fix it.**~~ — **fixed 2026-09-14.** Logged 2026-09-13.
    - **The cause:** `handle_new_user` writes the email's local part to
      `profiles.username`, which is `UNIQUE`. A second email with the same
      local part fails inside the trigger, and the whole signup rolls back.
    - **What reaches the client:** GoTrue returns 500 ("Database error saving
      new user"). gotrue-dart raises any response of 500 or above as
      `AuthRetryableFetchException`, and `sign_up_screen` shows its raw
      response body.
    - **Why the label is wrong:**
      - Not retryable: the same email fails every time.
      - Not self-fixable: signup takes no username.
    - **Evidence:** the constraint violation was confirmed by a rolled-back
      database probe. The client path was read from the code, not observed.
    - **Status — FIXED 2026-09-14,** option 1 with all three parts, at the
      Product Owner's direction.
      - **Database:** live migration
        `20260914132443 handle_new_user_null_username`
        (`supabase/migrations/20260914_handle_new_user_null_username.sql`).
      - **Client, parts 2 and 3:** commit `bcc397b`.
      - **Verified after applying,** against the live function: two signups
        sharing a local part both succeed, with NULL usernames (probe rolled
        back). The collision was reproduced first (`23505` on
        `profiles_username_key`).
      - **Still true:** `display_name` stays email-derived (IC-4), and clients
        built before `bcc397b` still write `''` for an empty username until
        they are rebuilt.
    - **Status as recorded 2026-09-13:** not fixed. The fix (option 1) is
      proposed and held on the `display_name` naming decision. It ships as one
      change with three parts:
      1. The trigger writes a NULL username.
      2. `user_service.dart:186` writes NULL, not `''`, for an empty username.
      3. A row-only guard at `user_service.dart:453-456`: when the profiles
         row was fetched, the username comes from the row only.

      Part 3 **prevents option 1 from unmasking #17. It does not fix #17.**
**Naming / storage integrity**

18. **`public.users` is a second identity table for one concept.** This is a
    naming and storage-integrity violation. Logged 2026-09-13.
    - **The live table is `profiles`.** Its rows are created by
      `on_auth_user_created → handle_new_user`, and the app reads it
      throughout.
    - **`public.users` (measured 18:23 UTC):**
      - Exists, with **0 rows**.
      - Columns: id, email, phone, is_anonymous, created_at, updated_at.
      - RLS on, with own-row read and update policies.
    - **Its only writer is dead.** `handle_auth_user_upsert` is attached to no
      trigger. It would upsert `public.users`, then insert a second, all-NULL
      shape of `profiles` row, into a `current_vibe` column that `profiles`
      does not have. Attached as written, it would fail every signup. Its NULL
      username write does confirm that NULL was an intended state.
    - **Nothing reads `public.users`:**
      - The database search was validated against this function as a known
        positive.
      - The code search, across Flutter, Expo and migrations, was validated on
        `from('profiles')`.
      - No view matched, but no known positive view existed to validate that
        pattern.
    - **Resolution:** IC-1 below. It is not fixed piecemeal.

20. **Vent membership is stored twice on `posts`, and the two fields
    disagree.** Logged 2026-09-14. **Not fixed:** the Product Owner rules on
    which field is authoritative. Class: one concept in two storage locations,
    which the 2026-09-14 decision record calls a duplicate implementation.
    - **The two fields:**
      - `category`: text, NOT NULL, default `'ForYou'`, CHECK in `ForYou`,
        `Vent`, `Mood`.
      - `experience_mode`: text, nullable, no default, no CHECK.
    - **They disagree on 5 of 12 rows** (measured 2026-09-14, 22:12 UTC). All
      five are private and anonymous:

      | id | owner | category | experience_mode | In Vent Sanctuary? |
      |---|---|---|---|---|
      | `8878ec08` | d9fa2f57 | Vent | social | yes, for its owner |
      | `86dc30a6` | d9fa2f57 | Vent | social | yes, for its owner |
      | `cb79e7cf` | 350201ed | Vent | social | yes, for its owner |
      | `0179941c` | 350201ed | Vent | social | yes, for its owner |
      | `7c20080f` | 350201ed | ForYou | vent | no (see 22 under *Added 2026-09-09*) |

    - **One writer sets both, from different sources.** The only Flutter write
      path is `CreatePostScreen._createPost` → `PostService.savePost` → insert
      into `posts`.
      - `category` is `'Vent'` when the composer's post-type selector is Vent,
        otherwise `'ForYou'` (`create_post_screen.dart:214`). The selector
        defaults to Vent when the active mode is Vent (`:113-117`), and the
        user can change it.
      - `experience_mode` is the app-wide active experience mode,
        `ctx.activeMode.name`, whenever it is set
        (`create_post_screen.dart:222`, `post_service.dart:110-111`).
      - So the two diverge whenever the post type and the app mode differ:
        Vent chosen while the mode was social (the four rows, written before
        `a9db98f` made entering the Sanctuary set Vent mode), or another type
        chosen while Vent mode was still on (`7c20080f`).
      - On a `PGRST204` naming either column, `savePost` retries without it
        (`post_service.dart:553-566`). If `category` were the one dropped, the
        database default would write `'ForYou'`.
      - No database function, trigger or policy writes or filters on either
        field, and the legacy Expo app does not write `posts`.
    - **Readers: the server decides Vent by `category`, the client by
      `experience_mode`.**
      - `category`: `vent_feed` (`= 'vent'`) and `posts_feed` (`<> 'vent'`).
        This is the containment boundary.
      - `experience_mode`: both views return it; it is mapped to
        `Post.experienceMode` and read through `Post.inferredExperienceMode()`,
        which returns the stored value when present and otherwise guesses from
        anonymity, privacy and mood. That inferred value drives client-side
        Vent handling:
        - `VisibilityService`: in a protected emotional space, only posts
          inferred as `vent` pass (`visibility_service.dart:37, 80`).
        - Home feed's Vent kind, selected whenever the active mode is Vent
          (`home_feed_screen.dart:158-160`), keeps posts inferred as `vent` or
          anonymous (`:879-883`).
        - `FeedDistributionEngine` ranks `vent` down in For You and up in Vent
          (`feed_distribution_engine.dart:158, 175`).
        - `EmotionalGovernanceService.assessPost` treats `vent` as support
          content (`emotional_governance_service.dart:80`).
      - **Consequence:** Home only ever receives `posts_feed` rows, which
        exclude category Vent. So its Vent kind can only match posts whose
        category is not Vent but whose mode, stored or guessed, is, such as
        `7c20080f`, and never the posts Vent Sanctuary shows. Whether such a
        post is then displayed also depends on `VisibilityService`, which denies
        private posts; that path was not traced end to end.
    - Measured against the working tree. `home_feed_screen.dart` and
      `post_service.dart` have uncommitted changes; the other files named here
      are as committed.

---

## Irreversible cleanup, deferred

Every destructive step lives here and only here, so none of them gets folded
into an ordinary cleanup list.

- **Each is its own step.** Its checks are re-run at the moment it executes,
  not trusted from the measurements recorded below.
- **None runs until the order of irreversible steps is agreed.**
- **IC-4 also waits on a decision.** The row clear in IC-4 is blocked on the
  Product Owner naming `display_name`. #16's option 1, the trigger change, was
  held on the same decision until 2026-09-14, when it shipped for `username`
  only (`20260914132443`).

- **IC-1 — retire `handle_auth_user_upsert` and drop `public.users`, as one
  step.** Resolves #18.
  - **State at 18:23 UTC:** the table had 0 rows and the function was
    attached to no trigger.
  - **The table has email and phone columns.**
  - **At execution:** re-check the row count, triggers and references first.
- **IC-2 — delete the Expo code tree.** Ruled safe by the Product Owner on
  2026-09-13.
  - **Evidence (measured 17:13 UTC):** `moods` does not exist in any schema,
    and `glow_sessions`, `sparks` and `vents` exist with 0 rows each.
  - **Why it is listed here:** git history keeps the code, but the step
    removes a whole client, so it stays with the other destructive steps.
  - **Scope:** the code only. The tables are IC-3.
- **IC-3 — drop `glow_sessions`, `sparks` and `vents`.** Each had 0 rows at
  17:13 UTC.
  - **At execution:** check dependencies first — foreign keys, views,
    policies, realtime publication.
  - **Before anything Vent-named is dropped:** confirm which of `vents`,
    `vent_posts` and `posts` is the canonical Vent storage.
    - **Answered 2026-09-14, settled by observation (22:12 UTC):** `posts` is
      the Vent storage. The Flutter app reads Vent through the `vent_feed`
      view, which keeps rows where `lower(btrim(category)) = 'vent'`;
      `posts_feed` excludes the same rows. `vents` and `vent_posts` hold 0 rows
      each, and nothing in `lib/` reads or writes either.
    - **Not yet safe to call them dead:** the legacy Expo app, still tracked
      under `src/` with `expo/AppEntry` as its entry point, reads `vents`
      (`src/screens/CreatorScreen.js`, `src/screens/ExploreScreen.js`,
      `src/hooks/useRealtimeCounts.js`) and reads and inserts `vent_posts`
      (`src/screens/VentScreen.js`). Retire or confirm that app before dropping
      either table.
    - **Why `vent_feed` can look empty:** its predicate includes
      `user_id = auth.uid()`, and every Vent post is private. From the SQL
      editor, with no signed-in user, it returns 0 rows. By role, `d9fa2f57`
      sees 3 and `350201ed` sees 5.
    - **A second Vent field exists on the same rows** and disagrees with
      `category` on five of them: see known issue 20.
- **IC-4 — clear the email-derived `username` and `display_name` on the two
  existing rows.** This is a data write.
  - **Blocked** on the `display_name` naming decision.
  - **Pre-change values** for all three rows are in the gitignored
    `private/profiles_name_snapshot_2026-09-13.json`.
  - **Also decided at this step:** the auth metadata username fallback at
    `app_provider.dart:236-238`.

---

## Added 2026-09-08

### Fixed, but the shape is worth remembering

**15. Privacy leaks are downstream of RLS, not in it.** Three surfaced in one
day and none was a policy mistake:

- `posts_feed` was defined without `security_invoker`, so the view ran with its
  owner's rights and bypassed `posts_read_visible` entirely. Every signed-in
  user could read every private post, Vent included. Fixed `6cef368`, verified
  by role from the other account.
- Profile diagnostics printed account id, username and full bio on every load;
  `PostService` printed the whole insert row, so a private anonymous Vent post's
  text reached the browser console at creation. Fixed `ace9144`, `55c0a94`.
- Much of the class swept in `fbb008c`: an unbounded OpenAI response body,
  raw block/report target ids, two `'Tapped mood: $x'` lines, seven auth
  catches, and `truLogStateError` — the aperture every screen funnels through.
  **That sweep's "class closed" claim was false**, and stood on this page for a
  day. See the canary section below for how the pattern under-reported by a
  factor of twenty.
- The part `fbb008c` did not reach was `FormatException`. `safeError` passed
  every non-Postgrest/non-Auth error through `toString()` untouched, and
  `FormatException.toString()` embeds a window of `source` — the string that
  failed to parse. For every cache in this app that string *is* the user's own
  data, so a corrupted posts cache printed private Vent text, a corrupted
  message store printed chat content, and a corrupted profile cache printed the
  bio. Nobody writes a logging line for that; it arrives through `catch (e)` on
  a `jsonDecode`. Proven by decoding a truncated store, not assumed — the
  message text and sender id came out verbatim.

  Closed in two halves, because narrowing the aperture alone would not have
  done it: `safeError` now renders `FormatException` as type, position and
  message with `source` dropped, **and** the 31 `catch` sites whose `try` block
  decodes JSON were routed through `safeError`, which they previously bypassed
  entirely by printing `$e` directly. 169 bare `$e` log sites remain elsewhere;
  they are not known to embed user data, and are the obvious next sweep.

The generalisation is the useful part: **the RLS is sound, so look downstream of
it.** Policies get reviewed; views, caches, log lines and realtime payloads do
not, and they sit outside the layer that enforces anything. `safeError` and
`redactedId` in `lib/core/diagnostics/log_redaction.dart` are where those
decisions now live. Note `redactedId` is an unsalted 32-bit hash — it defeats a
reader holding the log, not one holding the user table, and the file says so.

**16. Nine device-global `SharedPreferences` keys held account state.**
`SharedPreferences` is per-installation, not per-account, so a second person
signing in on the same device inherited the first person's data. Worst was
`compliance_prefs_v1`: account B inherited A's terms acceptance and was never
prompted, opening adult-intent and creator surfaces to someone who had agreed to
nothing. All nine are now per-uid (`4ff6dae`, `c78a37a`, `7ecb53e`, `48025ab`,
`0a075d0`), plus the account-resolution races in `e51d122`.

Three different treatments, and the reasoning is the reusable part:

| Treatment | Keys | Why |
|---|---|---|
| **Orphan** (discard, park the old value under a dead key) | consent, safety prefs, identity prefs | The old record has no attribution. A guessed consent record is worse than none, and all of it is re-selectable in seconds. |
| **Claim** (first account takes it, global key removed) | follows, sparks | No server table exists, so discarding silently unfollows everyone with nothing to reconstruct from. Bounded, not solved — see below. |
| **Filter by attribution** (each account takes its own rows, global key kept) | chats, messages | This data is self-attributing: `Chat.participantIds` and `Message.senderId` name their owner, so nothing is guessed. |

**The claim caveat, which is easy to misread as solved:** on a device where two
accounts have signed in, local data with no attribution goes to whoever launches
first. Claiming bounds the damage to once rather than repeating; it cannot
identify the rightful owner, because nothing on disk can. Anything that must be
attributed correctly gets orphaned instead.

**Still watch for it:** the `*_global` fallback layer in
`app_settings_service.dart` (32 keys) and the null-user buckets in
`experience_mode_service` / `feed_behavior_service` were deliberately left
alone. They are a narrower race, not the same bug.

### Open

**17. Swallowed write failures — the biggest remaining class.** Services catch a
write failure, log it, and return as if it succeeded, so the UI reports success
for something that never persisted. Known instances: profile saves, quiz
completion, conversation reads, `ChatService.ensureChatWithUser` (already issue
10 above), and the `IdentityService` mode/label setters, which also mirror into
the cached user and swallow that too.

Partly addressed where it was in the way — `setPrefs`/`acceptTerms`/
`acceptModeConsent`, the nine Safety Center setters, `toggleFollow`/`sendSpark`
and `BlockService`/`ReportingService` writes all return `bool` now — but **the
call sites still discard the result**, so the information exists and nothing
acts on it. That is the pass: make the UI react, not just the services report.

Worth naming the shape, because it is the same one as the report button that
said "Reported. Thanks for protecting the space." while writing nothing to the
server (`d50ce74`): **a promise the app cannot keep.** The UI reports success,
the row is not there, and nothing anywhere records the gap. Identical to blocks
and reports before 2026-09-08 — the person believes they are protected and they
are not.

*Start with the inventory, not the three known sites.* `saveMessage` and
`ensureChatWithUser` were found by reading messaging code specifically, so the
list above is what happened to be read, not what exists. The mechanical search
is the same one that turned the logging leaks from three incidents into a
class: **a catch whose body is a log call followed by a return that is not a
rethrow**, plus the `Future<void>` variant that logs and falls off the end.
Three known cases and a complete list are different things, and the count is
itself the finding — a handful of bugs or the default the codebase reaches for.

*Inventory run 2026-09-08. It is the default, not a handful.* The mechanical
search finds **179 swallow sites across roughly 30 files** — 97 of the
catch/log/return shape and 82 of the `Future<void>` log-and-fall-off variant.
Heaviest: `app_settings_service.dart` (67), `user_service.dart` (16),
`post_service.dart` (12), `chat_service.dart` (9), `sync_service.dart` (10).
Most are reads returning an empty default, which is defensive in the right
direction; the count matters because it means "catch, log, carry on" is the
reflex the codebase reaches for, so the fix is a convention plus the specific
write paths, not a bug list.

*The inventory also found a second class nobody had named, and it is worse.*
Not a swallowed failure — **a confirmation with no write behind it at all**:

| Site | Says | Actually does |
|---|---|---|
| `explore_screen.dart:364` `_sendConnect` | "Connection request sent" | Adds to a local set. No service call. |
| `explore_screen.dart:344` `_toggleFollow` | "Followed \<name\>" | Mutates an in-memory set. Never calls `ConnectionService.toggleFollow`, so it does not even reach that account's own prefs — while the profile sheet's Follow button does. Two follow paths, one real. |
| `trulura_profile_preview_sheet.dart:146` Glow | "Glow sent." | Snackbar, then pop. No call. The Spark button beside it does call `sendSpark`. |
| `sync_screen.dart:2417` Save | "Energy saved" | Snackbar, then pop. No write. |
| `chat_list_screen.dart:445` swipe | "Archived" | In-memory only (issue 9), and nothing tells the user it will not survive reload. |

These cannot be found by searching for swallowed errors, because there is no
error and no attempt. They are the same shape as the feed Report button in
`d50ce74` and as `_persistMood` writing the wrong column: **the UI is the only
thing that thinks something happened.**

*Verified honest, for contrast:* `create_post_screen.dart:188` shows "Posted ✨"
only after `savePost` returns, and `savePost` rethrows rather than swallowing —
so a failed post surfaces. `chat_thread_screen.dart:783` writes through
`SyncService` before confirming. Those are the pattern to copy.

*The sorting line, which is not "does it swallow".* Not every swallowed failure
should throw. `ReportingService.isBlocked` returning true on error is defensive
in the right direction. `ensureChatWithUser` returning null on the Sync path is
survivable, because the caller can retry and a chat there is a side effect of
accepting a connection. What matters is narrower: **is the user told something
succeeded when it did not?** Sort on that.

**18. `20260908_posts_feed_respect_privacy` puts post visibility in three
places.** `posts_read_visible` on `public.posts`, plus the WHERE clause in each
of `posts_feed` and `vent_feed`. Change one and all three must change, or reads
through a view and reads by any other path disagree silently — the
one-concept-two-writers shape `separate_vibe_from_mood` exists to undo.

*Named end state:* plain `security_invoker` views with no predicate of their
own, letting RLS be the single source. **Not reachable today**, and the reason
is specific: `20260904_revoke_posts_direct_select.sql` revoked `SELECT` on
`posts` from `authenticated`, so `security_invoker` would fail at the privilege
layer, and granting the table back would expose `user_id` on anonymous rows —
trading a private-content leak for a deanonymisation leak. It becomes reachable
if `posts` ever carries column-level grants covering every column the views
read.

**19. `0a075d0` scopes a code path that cannot execute.** The local chat store
(`chats` / `messages`) was made per-account by attribution, and the migration is
correct — but every read of it sits behind `if (_supabaseReady) return remote`,
and `main.dart` awaits `DatabaseService.initialize()` with no `catch`, so the
app cannot start with Supabase uninitialised. The store is unreachable in any
running app, the filtered migration never runs, and the data stays in the
device-global keys.

**This commit reads as done and is inert.** It is correct if that path is ever
revived; it changes nothing today. Left in place deliberately rather than
reverted, since the attribution reasoning is the part worth keeping.

**20. Two Vent surfaces, and the one in the Aura feed cannot show Vent.**
The Aura feed's Vent tab filters `_posts`, which comes from `getAllPosts()` →
`posts_feed` ([home_feed_screen.dart:853](../lib/screens/home/home_feed_screen.dart#L853)).
Since `8484ab0` `posts_feed` excludes Vent by construction, so that tab is
filtering a source with no Vent content in it. Its filter
(`inferredExperienceMode() == vent || isAnonymous`) can now only ever match
non-Vent posts that happen to be anonymous.

**This is a consequence of the containment fix, and it was not noticed when that
landed.** Before `8484ab0` the tab could show Vent posts — which was the leak.
Containment correctly emptied it; nothing updated the tab. What hides the
emptiness is placeholder copy inlined in the feed screen itself --
`'This space feels calmer tonight.'` at
[home_feed_screen.dart:1226](../lib/screens/home/home_feed_screen.dart#L1226)
and `'$activeCount people tuning into this vibe'` at
[:1411](../lib/screens/home/home_feed_screen.dart#L1411) -- so the tab looks
populated.

*(Corrected 2026-09-08: this section first attributed those cards to
`feed_demo_content_service.ventItems`. That was wrong -- `FeedDemoContentService`
has no callers anywhere in `lib/`. The copy is inline in the feed screen. The
attribution was asserted from having read the service, not from tracing the
strings.)* The "Open Vent Space" button on it routes to Vent
Sanctuary, the surface that actually reads `vent_feed`.

So: a tab pointing at nothing, dressed with placeholder content, with a button
to the real thing. Same shape as the two follow buttons in issue 17 — two paths,
one real — and the placeholder cards are the same class as a confirmation with
no write behind it: the UI asserting something nothing backs.

*Decision needed, not a bug fix:* either the tab reads `vent_feed` too (and
Vent content appears in the main feed, which is what containment deliberately
stopped), or the tab should not exist. It cannot stay as it is without the demo
cards, and it should not stay as it is with them.

---

## Reading the console: is the build current?

Twice on 2026-09-08 an observed failure turned out to be a browser serving a
build from before the fix. Hot reload does not reliably pick up changes on web.

**Both canaries below were re-verified against the tree on 2026-09-09 before
this section was trusted again.** A canary that lies is worse than none.

- `PostService: inserting into posts: {"user_id":...,"content_text":...}` — the
  full row. Redacted in `55c0a94`; confirmed still redacted. If you see post
  content on that line, the build predates that commit.
- `Failed to get user: Bad state: No element` — `getUserById` used
  `.cast<User?>().first` on a possibly-empty iterable. Replaced with a loop in
  `d50ce74`; confirmed no `.first` remains in `user_service.dart`. This is the
  stronger signal, being the earlier commit: seeing it means the build predates
  `d50ce74`, and therefore predates every Vent fix.

### NOW a canary: a profile line with id / username / bio

A previous revision of this page listed this line as explicitly **not** a
canary, because it was still an open leak on the tree. It has since been
redacted, so the reading has inverted. If you see

```
HomeHubScreen loaded profile: id=..., username=..., bio=..., needsOnboarding=...
```

**your build is stale.**
[home_hub_screen.dart:457](../lib/screens/home/home_hub_screen.dart#L457) now
prints presence flags and a length only:

```
HomeHubScreen loaded profile: hasUsername=true, bioChars=42, needsOnboarding=false
```

*Why the original sweep missed it, since that matters more than the line
itself.* Two separate instrument failures, one after the other:

1. The `fbb008c` sweep used a **line-oriented** regex, so a `debugPrint(` whose
   interpolation sits on a later line was never examined. A multiline re-sweep
   found three such calls; two were already clean, and this was the third.
2. The multiline re-sweep *itself* then under-reported, and by far the wider
   margin. Its pattern was `\b(bio|username|…|\$e\b|…)` — and the leading `\b`
   sits immediately before the `$` of `$e`. A word boundary needs a word
   character on one side, so after a space, which is how `: $e'` always
   appears, it can never match. The sweep silently reported only the lines that
   happened to contain some *other* keyword: **9 sites, when the real number
   was 198.** A plain `grep` disagreeing with it is what exposed the bug.

The lesson is bigger than either bug, and this is now the third instance of it
in this repo — the two above plus migrations written against invented policy
names, where `drop policy if exists` matched nothing and silently changed
nothing. **A negative search result is a claim about the instrument as much as
about the code.** Before writing "nothing else is open", run the pattern
against a line you already know should match; if it does not light up a known
positive, the zero means nothing. Prefer an over-broad pattern plus manual
triage, and cross-check with a second, differently-shaped tool.

That is the harm an overstated sweep does: it does not merely miss things, it
forecloses the search. This page carried "class closed" as settled fact, so
nobody had reason to look again.

If either real canary appears: stop `flutter run`, restart it, hard-reload the
browser (Ctrl+Shift+R), and confirm both are gone before drawing conclusions
about layout, empty states, or anything else.

---

## Placeholder & simulation inventory

> **How this was checked: it mostly wasn't.** This is a *read of the code* by a
> review pass, folded in on 2026-09-08. It is **not verified by role and not
> exercised in the UI**, which is a weaker standard than everything above it.
> Items marked **[verified]** were traced in the repo before being written down;
> everything else is a claim to confirm before acting on. Treat the unmarked
> rows as leads, not findings.

### The distinction that matters

**Placeholder** — nothing behind the presentation.
**Simulation** — local behaviour exists, but the promised multi-user or external
operation does not.

That split is more useful than done/not-done, and it maps onto the two classes
already in issue 17: a placeholder is a confirmation with no write behind it; a
simulation is the swallowed-write case one layer up, where something real
happens locally and nothing reaches anyone else.

### Three claims the app makes about reality that are not true

These are called out above the rest because each one asserts something to a
person that is false, rather than merely being unfinished.

1. **Identity verification is self-service.** **[verified]**
   [safety_verification_screen.dart:150-173](../lib/screens/settings/safety_verification_screen.dart#L150)
   has a button captioned "Advance level (stub)" that increments
   `verificationLevel` and saves it. `SafetyMeterService.meterForUser` reads
   that value to decide Strong / Standard / Basic, so self-advancing changes
   what the safety meter tells *other people* about you. This is also why
   `dmPermission`'s `verifiedOnly` option could not be enforced (`e51d122`).
2. **Sync manufactures mutual interest.** **[verified]**
   [sync_service.dart:112-116](../lib/services/sync_service/sync_service.dart#L112):
   `chance = 0.12 + (compatibility/100) * 0.58`, then
   `Random(_hash('$id|mutual')).nextDouble() < chance`. A true result sets
   `mutual` and `createdMatch` and opens a chat. The seed is the signal id, so
   it is deterministic — the same signal always returns the same verdict, which
   is why it looks stable rather than flickering under testing.
3. **Creator analytics are literals.** **[verified]**
   [trustudio_screen.dart:207,211](../lib/screens/trustudio/trustudio_screen.dart#L207)
   — `value: '12.4K'` for Views and `value: '328'` for Subs, as string
   constants.

### Dead code, not decisions

- `FeedDemoContentService` — **[verified] no callers anywhere in `lib/`.** It
  defines synthetic profile-expression posts, community echoes, AI nudges and
  Vent demo items, and nothing constructs it. Deletable; it is not a feature to
  decide about. (See the correction on issue 20: the placeholder cards visible
  on the Aura Vent tab are inline copy in `home_feed_screen.dart`, not this.)
- The `?ui=` demonstration states — **[verified] these are NOT dead.** Seven
  screens read `queryParameters['ui']` and branch on it, and 15 sites reference
  `TruUiState.empty` / `.action`. They are unused by default but fully wired and
  reachable by appending a query parameter to any of those routes. Do not
  delete them as scaffolding; decide whether a URL-reachable demo mode should
  ship.
- Unused old card components — **not verified.** Claimed by the review pass; no
  call-graph check has been run.

### Unverified inventory, by area

*Presentation only, nothing behind it:* TruJourney, global search, companion
search, "Open profile" from preview sheets, and the Aura / Sync / Explore mode
settings screens. Live rooms, live overlays and moderation, subscriber tiers,
brand deals, upload queue and scheduling, payouts, Nebula Hours, Festival Drop,
Replay Capsule, Community Quest. Notifications — the Pulse list is a fixed
demonstration set for glows, sparks, replies, follows, safety events and
events; filtering it works, which makes it read as live.

*Local behaviour, no multi-user reality:* follow/unfollow, connection requests,
profile Glow and Spark, comments and replies, sharing, reposts, group
membership. Spark delivery and acceptance, "save for later", matchroom
progression. Message reactions, pin/pause/archive, pause and end connection.
Healing Circles and the other Vent circles (keyword search over post text, not
membership). TruCompanion memory, the ten named reflection modes, "Aura
strength" (derived from an id hash), Emotional Weather, Aura Pulse.
Verification, background checks, Luxe invitation and membership, screenshot
permission, profile visibility, auto-delete, support contact.

*Accessibility:* Seizure Safe, Autism Friendly, ADHD Focus, Elder / Low Vision
and Recovery modes are descriptive previews. Soft Mode is real.

*Quizzes:* Friendship Energy Match, Social Style and Compatibility Layers are
implemented; the rest of the registry is a planned catalog without scoring.

*Real, and worth not confusing with the above:* auth, profile persistence,
profile discovery (since `d50ce74`), text posts, post reactions, text
conversations, quizzes, mood and settings behaviour, block/report storage, and
Vent's feed and containment.

### What this changes about verification

Placeholder content is pervasive enough that **"is this feature real" cannot be
answered by looking at the screen.** A populated-looking surface is not evidence
of a working system, and several placeholders are indistinguishable from the
real thing by design — the notification list filters, the discovery chips
highlight, the Vent tab shows cards.

That is not an abstract concern. It is why the Vent question cost a full
session: the Sanctuary looked like a broken feature, the Aura Vent tab looked
like a working one, and the truth was the reverse of both. Until this is
reduced, verification means reading the code or querying the database, and any
claim on this page that rests on a screenshot should be treated as unverified.

*This also argues against the demo content itself, which is a product decision
rather than a bug: placeholder cards make empty screens look alive during
development and make every feature unverifiable at a glance. Same bucket as
PD-14 and the Aura / For You distinction.*

---

## Added 2026-09-09

**21. Connection requests are half-built: the row lands, nothing renders it.**

`f139b5b` made Explore's Connect genuinely server-backed — it writes to
`public.spark_interactions`, and the recipient can read the row, verified by
role. `7ba3033` then de-duplicated that table and added the partial unique index
the service was assuming.

**Do not read "server-backed" as "the loop closes."** It does not, yet:

- Nothing renders an incoming request. Pulse (notifications) is a fixed
  demonstration list, so the recipient still sees no pending request.
  `ConnectionService.incomingConnectionRequests()` exists and returns the rows;
  it has no caller.
- There is no accept or decline. The table has no status column — a row means
  "asked", and there is no way to record an answer.
- Nothing joins the request to the sender's profile, so a rendered request would
  have no name on it. That join was impossible before `7ba3033`: four FKs to
  `profiles` where there should be two made the PostgREST embed ambiguous
  (PGRST201, the same failure that broke `messages` embeds earlier). It is now
  possible and still unwritten.

So the honest state is: **one direction of one relationship crosses between
accounts.** That is more than existed before, and it is not a working
connection system. The remaining pieces are a receiving surface, an
accept/decline lifecycle, and a status column to hold the answer.

*Follow, beside it, was removed rather than half-fixed* — it could only have
persisted to one device, and making that survive a reload would have made the
false impression more durable. Restore it when a follows table exists.

---

**22. `posts=1` is correct. There is only one public post.** *(Investigated
2026-09-09, by role.)*

`HomeFeedScreen._loadInitialPosts` logging `posts=1` with
`firstPostId=2a8cdfa7` twice was read as a feed bug. It is not one. The premise
— that more than one public post exists — is false.

All six rows in `public.posts`:

| id | author | privacy | category | anonymous |
|---|---|---|---|---|
| `7c20080f` | 350201ed | **private** | ForYou | yes |
| `0179941c` | 350201ed | private | Vent | yes |
| `cb79e7cf` | 350201ed | private | Vent | yes |
| `86dc30a6` | d9fa2f57 | private | Vent | yes |
| `8878ec08` | d9fa2f57 | private | Vent | yes |
| `2a8cdfa7` | d9fa2f57 | **public** | ForYou | no |

By role against `posts_feed`: `d9fa2f57` gets **1** row (`2a8cdfa7`), which is
exactly what the log said. `350201ed` gets **2** — the public one plus its own
private `7c20080f`. The view, the predicate and the screen are all behaving.

**The real bug is the first row, and it is a consequence of `a9db98f`.**
`7c20080f` is a `ForYou` post that came out private and anonymous. The composer
takes its privacy and anonymity defaults from the active experience mode, and
`a9db98f` made entering Vent Sanctuary *set* that mode to `vent` — but nothing
ever sets it back. Vent mode is sticky, so after one visit to the Sanctuary,
every subsequent post is private and anonymous no matter which surface it was
written from.

That also explains why the feed looks empty: five of six posts are private
because they were composed in a mode the user had left. Not investigated
further tonight; the fix is a decision about when Vent mode should end (on
leaving the route, on the next explicit mode choice, or scope it to the
composer instead of the app), which is the same question raised when the change
landed.

---

## Layout: fixed Rows at narrow widths — inventory, not a task list

Four overflows surfaced in one evening of ordinary use. Three were horizontal
Rows; the fourth (profile setup Step 2, 30px bottom) is a **vertical** Column
overflow, a different bug that no Row convention touches, and it is untouched.

**The convention already existed.** Of the four Rows in `lib/` whose children
are generated by a `for` or `.map`, three already sit inside
`SingleChildScrollView(scrollDirection: Axis.horizontal)` — `ai_companion:828`,
`notifications:191`, `world_layers:487`. Exactly one did not. That was
`trulura_side_drawer.dart:654`: five `_ModeSignal`s at 54px need 270px and the
drawer gives 157, which is the reported 112px almost exactly. `spaceAround` is
what made it unreadable — it distributes whatever the collection yields, so the
layout silently depended on `modes.length` with nothing at the call site showing
what that is. Now a `Wrap`; `Wrap` rather than horizontal scroll because this is
navigation, and scrolling would fit one line by hiding two modes off-screen with
no affordance.

### Read the caveat before treating the list below as work

The scan that produced it **over-reported by an order of magnitude on the class
it was checked against**: 14 candidate generated-children Rows reduced to 1 real
defect on inspection. Both reductions were the instrument, not the code — it
counted `if (x) ...[a, b]` conditional spreads as dynamic when their child count
is fixed and known, and it could not see a scrolling ancestor outside the Row
expression. An earlier revision of the same scan reported 52 and failed its own
known-positive check on two of the four observed overflows.

So this is an **upper bound from a signal with a demonstrated ~93% false
positive rate on its last class**, not a backlog. A static scan cannot tell a
Row that overflows from one whose content is simply always short. Observation is
cheap — four were found in an evening — and speculative edits against this list
would repeat the exact mistake the triage caught.

**Fix these when a device shows them overflowing. Do not batch-apply.**

### The list: Rows with 3+ fixed children, an unwrapped `Text`, and no flex

Twenty-six reachable. Twelve more are in files a concurrent session has
uncommitted work in and are excluded — 4 in `vent_screen.dart` (including the
Sanctuary header and the card action row, both *observed* overflowing), 4 in
`sync_screen.dart`, 2 in `trulura_screen_state.dart`, and one each in
`chat_list_screen.dart` and `home_feed_screen.dart`.

- `lib/screens/ai/ai_companion_screen.dart:254`
- `lib/screens/chat/chat_thread_screen.dart:1393`
- `lib/screens/chat/chat_thread_screen.dart:431`
- `lib/screens/live/live_hub_screen.dart:31`
- `lib/screens/placeholder/placeholder_screen.dart:472`
- `lib/screens/pre_auth/soft_mode_gate_screen.dart:61`
- `lib/screens/pre_auth/soft_mode_gate_screen.dart:78`
- `lib/screens/profile/profile_screen.dart:2130`
- `lib/screens/profile/profile_screen.dart:2378`
- `lib/screens/sync/matchroom_screen.dart:246`
- `lib/widgets/feed_card.dart:1713`
- `lib/widgets/feed_card.dart:2623`
- `lib/widgets/sync_hero_card.dart:629`
- `lib/widgets/sync_preview_panel.dart:425`
- `lib/widgets/tag_pill.dart:31`
- `lib/widgets/trulura_ai_suggestions_sheet.dart:144`
- `lib/widgets/trulura_boosted_post_card.dart:31`
- `lib/widgets/trulura_event_carousel_row.dart:58`
- `lib/widgets/trulura_post_composer.dart:277`
- `lib/widgets/trulura_profile_hero_card.dart:343`
- `lib/widgets/trulura_profile_hero_card.dart:394`
- `lib/widgets/trulura_profile_hero_card.dart:450`
- `lib/widgets/trulura_profile_hero_card.dart:485`
- `lib/widgets/trulura_secondary_buttons.dart:140`
- `lib/widgets/trulura_secondary_buttons.dart:50`
- `lib/widgets/trulura_world_layers.dart:377`

When one does overflow, the rule is **the text gets the `Flexible`, not the
controls** — text is the elastic element and the trailing icons are fixed.

### The Vent card overflow is the header row, not anything inside it — MEASURED

Read this before "fixing" a Vent card overflow. Three fixes were proposed and
argued through before anyone measured the box, and all three were structurally
incapable of working.

The RenderFlex error carries the answer:

```
constraints: BoxConstraints(0.0<=w<=34.1, 0.0<=h<=Infinity)
creator: Row ← Padding ← Column ← Expanded ← Row ← _FeedHeaderRow
```

**The content column is 34.1px wide.** `_FeedHeaderRow`'s fixed children eat
almost the entire card at narrow widths:

| child | width |
|---|---|
| avatar (`TruLuraHaloAvatar` radius 22) | ~44 |
| `SizedBox` | 12 |
| **`Expanded` → name row + "Anonymous share" row** | **34.1** |
| `_NoSplashIconButton` (info) — padding 10 + icon 20 | 40 |
| `_NoSplashIconButton` (more) | 40 |

~136px of chrome against ~170px of card. Everything below it is being asked to
render in what is left.

**Why the obvious fixes do not work.** `Flexible` on the name, `TextOverflow
.ellipsis`, and converting the row to a `Wrap` all operate *inside* that 34.1px
box. The word "Anonymous" alone is wider than the box, and **a `Wrap` cannot
break within a word** — so a `Wrap` reduces the overflow without eliminating
it. That is the trap: the number moves, it looks like progress, and the wrong
diagnosis survives another round.

**The fix belongs in `_FeedHeaderRow`**: shrink or drop the avatar and the two
40px icon buttons at narrow widths, so the `Expanded` gets a usable share.

Method note, because it generalises: this was found by printing the values
rather than reading the widget tree, after three wrong readings of the tree.
For any overflow, read the `constraints:` and `size:` lines in the error first
— they are free and usually decisive. An overflow reported *at* a widget is
often caused by a sibling several levels up taking the width.
