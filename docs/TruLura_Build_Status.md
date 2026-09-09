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
| — | **Vent** (§9.8 adjacent) | Partial | `vent_feed` view contains Vent, `posts_feed` excludes it; containment verified by role both directions. Screen fixes in `a9db98f` / `55c0a94` are **not** UI-verified — the posts exist in `vent_feed` and had never rendered as of last check. |
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
13. Fourteen tracked files are zero bytes, including nine `README.md`
    placeholders, `docs/DOCUMENTATION-STANDARDS.md`,
    `docs/02-Product/TruLura_Product_Decision_Log.md`, and four
    `src/storage/*.js` stubs. The decision log in particular reads as
    authoritative from its name and contains nothing.

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
- The rest of the class swept in `fbb008c`: an unbounded OpenAI response body,
  raw block/report target ids, two `'Tapped mood: $x'` lines, seven auth
  catches, and `truLogStateError` — the aperture every screen funnels through.

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
server (`d50ce74`): a failure that is invisible to the person it failed for.

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
