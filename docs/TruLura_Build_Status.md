# TruLura — Build Status

*Status page, not a spec. The Blueprint is the spec. Written 2026-09-07 from the
live database and the repo, not from memory. Every "verified" claim below names
how it was checked.*

---

## Core features

The Blueprint's "Core Loop" (§2.6) is a data-flow, not a feature list. The
nearest six-item list in the repo is the Implementation Roadmap's **Core Beta
backbone** — sections 1, 2/3, 4, 5, 9, 12 — used here. Note that messaging is
not on it, so if a different six is intended, this table needs correcting.

| # | Feature | State | Verified how |
|---|---|---|---|
| 1 | **Identity & Trust** (§1) | Built | `identity_core` table + `identity_core_repository.dart`; screen wired in `02151fa`. Not verified by role. |
| 2 | **Experience Modes** (§2/3) | Partial | `experience_mode_service.dart` exists; no dedicated table. Not verified. |
| 3 | **Discovery / Aura feed** (§4) | Built | Real posts via `posts_feed` view (security_barrier). Anonymous rows return `user_id = null`. Verified by role. |
| 4 | **Profile** (§5) | Partial | `profiles` table + profile screens. Read access verified by role (authenticated sees others, anon sees none). |
| 5 | **Safety** (§9) | Partial | 4 safety services, all client-side. `moderation_events` / `safety_flags` are service-role only. No server enforcement. |
| 6 | **MoodSync** (§12) | **Schema only** | `moods`, `mood_events`, `mood_states` exist with RLS. **No Dart code references any of them.** |
| — | **Messaging** | Built + verified | Only feature verified at every layer: by role in SQL, and a two-window browser test where a message crossed sessions without a refresh. |

**Verification depth is uneven.** Messaging is the only feature exercised
through the UI. Everything else is "the code exists and compiles."

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

**Realtime publication** `supabase_realtime` contains 9 public tables:
`conversations`, `conversation_members`, `messages`, `device_users`,
`glow_sessions`, `mood_events`, `moods`, `sparks`, `vents`.

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
3. `post_reactions` carries two overlapping SELECT policies —
   `post_reactions_read_all` and `post_reactions_select_authenticated`.
   Permissive policies OR together; the broader one wins. Worth auditing.
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

11. MoodSync (§12) has tables and RLS but no application code, despite being the
    highest-fan-out backend service in the roadmap.
12. No automated tests cover any of the above. Every verification recorded here
    was run by hand.
