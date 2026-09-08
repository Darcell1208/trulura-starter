# TruLura — Build Status

*Status page, not a spec. The Blueprint is the spec. Written 2026-09-07 from the
live database and the repo, not from memory. Every "verified" claim below names
how it was checked.*

---

## Core features

The Blueprint's "Core Loop" (§2.6) is a data-flow, not a feature list. The rows
below track the Implementation Roadmap's **Core Beta backbone** (sections 1,
2/3, 4, 5, 9, 12) plus the delivery-order features actually being built.

Two of the six delivery-order features are named but not started:
**5 — block / report / crisis** and **6 — invite-only signup**. Neither has any
code or schema yet beyond the `blocks`, `reports`, `moderation_events` and
`safety_flags` tables, which exist with RLS but no application code.

| # | Feature | State | Verified how |
|---|---|---|---|
| 1 | **Identity & Trust** (§1) | Built | `identity_core` table + `identity_core_repository.dart`; screen wired in `02151fa`. Not verified by role. |
| 2 | **Experience Modes** (§2/3) | Partial | `experience_mode_service.dart` exists; no dedicated table. Not verified. |
| 3 | **Discovery / Aura feed** (§4) | Built | Real posts via `posts_feed` view (security_barrier). Anonymous rows return `user_id = null`. Verified by role. |
| 4 | **Profile** (§5) | Partial | `profiles` table + profile screens. Read access verified by role (authenticated sees others, anon sees none). |
| 5 | **Safety** (§9) | Partial | 4 safety services, all client-side. `moderation_events` / `safety_flags` are service-role only. No server enforcement. |
| 6 | **MoodSync** (§12) | Built + verified | `MoodSyncService` writes `user_states.mood_tag` (current) and appends to `mood_states` (history); `AuraStateController.updateMood` persists, `initialize()` hydrates. Per-user isolation verified by role. **Verified in the UI**: mood set, app closed and reopened, mood survived; confirmed server-side (`mood_tag='flirty'`, 1 history row). |
| — | **Messaging** | Built + verified | Only feature verified at every layer: by role in SQL, and a two-window browser test where a message crossed sessions without a refresh. |

**Verification depth is uneven.** Messaging and MoodSync are the only features
exercised through the UI. Everything else is "the code exists and compiles."

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
14. `profiles.vibe` for `d9fa2f57` holds `'flirty'`, a Mood value, not a Vibe.
    The `separate_vibe_from_mood` migration copied `mood_tag` into `vibe` on
    the premise that everything in `mood_tag` was a Vibe — true when written,
    false when applied, because a successful MoodSync test overwrote
    `'Reflective'` in between. The original is recoverable from this session's
    logs but has not been restored pending confirmation.
12. No automated tests cover any of the above. Every verification recorded here
    was run by hand.
13. Fourteen tracked files are zero bytes, including nine `README.md`
    placeholders, `docs/DOCUMENTATION-STANDARDS.md`,
    `docs/02-Product/TruLura_Product_Decision_Log.md`, and four
    `src/storage/*.js` stubs. The decision log in particular reads as
    authoritative from its name and contains nothing.
