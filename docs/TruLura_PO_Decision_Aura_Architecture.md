# TruLura Product Owner Decision Record — Aura Canonical Architecture

**Decision date:** 2026-08-23
**Decided by:** Darcell (Product Owner)
**Classification: Product Owner Decision, 2026 — NOT a Recovered Historical Decision.** The archive supports this architecture, does not contradict it, and could not authorize it on its own. This record exists specifically to prevent this distinction from blurring over time, per the standing provenance discipline this reconstruction has maintained throughout.

---

## Verification note (added at commit time, 2026-08-23)

The migration table and the AB-010 section below were revised before this file was committed. The version originally drafted asserted several claims as "verified via source inspection" — a class named `AuraFeedScreen`, a shell widget named `NavShell`, a file named `create_post_sheet.dart`, and a five-item bottom-nav enumeration — that do not exist in this repository. None of that verification had actually been performed against this codebase.

A direct check of the real source (`lib/screens/main_shell.dart`, `lib/core/navigation/app_router.dart`, `lib/widgets/trulura_bottom_nav.dart`, `lib/screens/home/home_feed_screen.dart`, `lib/screens/home/home_hub_screen.dart`) found a different structure: the actual screen class is `HomeFeedScreen`, nested as an internal tab inside `HomeHubScreen`, which is itself one of four `StatefulShellRoute` branches (not five) managed by `MainShell`. Sync and Explore are not separate bottom-nav destinations at all — they are tabs inside the single Home branch, invisible to the router. Post creation pushes `lib/screens/post/create_post_screen.dart` via `AppRoutes.createPost`, not a file called `create_post_sheet.dart`.

Because AB-010's original resolution was reasoned entirely from the incorrect names and the incorrect five-destination count, that resolution does not hold under the real structure. It is marked **reopened** below rather than resolved. The `AuraController` → `AuraStateController` rename and the "`AuraIdentity` does not exist yet" claim were also re-checked directly against source and do hold.

---

## The decision

**Aura is the user's living identity model.** It is not a mood, not a score, not a UI effect, and not the same object as Mood under a different name.

Three internal layers, one user-facing name:

**Layer 1 — Aura (Identity).** The persistent, slow-changing representation of who someone is: emotional profile, values, communication style, personality tendencies, long-term preferences, trust-related characteristics, growth history. This is the canonical object. Everything else reads from it or writes to it.

**Layer 2 — Aura State.** The current expression of that identity. Consumes Mood, journals, conversations, relationships, life events, Companion observations, and activity as inputs — it does not replace identity, it expresses it moment to moment.

**Layer 3 — Aura Presentation.** How the platform renders Aura: the Aura Ring, Aura Feed, compatibility visualizations, profile presentation, glow intensity, personalization surfaces. Presentation changes; identity doesn't.

**Mood is explicitly not Aura.** Mood is a voluntary, time-limited emotional declaration (user-set, ~6-hour default expiry) that feeds into Aura State as one input among several. It never replaces or substitutes for Aura itself.

Platform systems — compatibility, personalization, trust presentation, AI Companion, discovery, communities, feed ranking — consume Aura rather than reading individual behavioral signals directly.

---

## Why this is a decision, not a recovery — stated precisely

The archive independently confirms real, dated material supporting every piece of this except the organizing structure itself:

- **The identity reading is directly attested**: "Aura = the user's soul blueprint on the platform" (2025-08-31), "social fingerprint" (2025-05-13), "profile & identity" (2025-11-30), and later, "the living digital representation of the person" (2026-04-09).
- **The computed/behavioral reading is also directly attested, in the same year**: "a color-coded, animated energy signature based on their last 24–72 hours of behavior, interactions, and mood shifts" (2025-06-14), "becomes too volatile (rage, fear, grief spikes)," "real-time mood indicator."
- **Mood-as-input-to-Aura is directly attested, same date as the computed-signature language (2025-06-14)**: "Mood = emotion + intensity → animation trigger" — Mood named as feeding Aura, not as being Aura.
- **The relationship was independently tested via Canonical Identity Analysis** ([ARCHIVE], against the archive corpus): Mood and Aura verified as different objects, not a rename — distinguished deliberately, side by side, on multiple dated occasions, with clearly different storage models (Mood: 6-hour expiry, user-set, toggleable; Aura: aggregation over a window, later "compressed representation of emotional + behavioral + contextual signals"). A thing cannot be an input to itself; this rules out the "same object, renamed" reading directly.

**What the archive does not do**: it does not state, anywhere found, that these two 2025 readings (identity vs. computed-signal) should be organized as two layers of one architecture rather than treated as an unresolved internal inconsistency. That organizing move — and specifically, promoting the identity reading to the foundational layer despite the computed/volatile reading being the numerically dominant 2025 usage (roughly a dozen statements against three) — is authored here, now, not recovered from any single source.

---

## Internal naming convention (the linked second decision — recorded together deliberately, per the reasoning below)

**User-facing language does not change.** The app continues to say "Your Aura," "Your Aura has evolved," "Aura Compatibility," "Aura Feed." Users never need to think in layers.

**Internally, the layers get distinct names**, specifically to prevent recreating the exact failure this reconstruction spent significant effort untangling with TruElite — one word serving as multiple technical objects, with no lock ever mentioning the others:

| Concept | Internal name |
|---|---|
| Layer 1 — Identity | `AuraIdentity` |
| Layer 2 — State | `AuraState`, managed by `AuraStateController` |
| Layer 3 — Presentation | Named for what each object actually renders (see migration table below), not left as a bare `Aura*` prefix |

---

## Migration: shipped code, verified against actual source (not inferred from names alone)

| Shipped today | Verified layer | Verified via | Status |
|---|---|---|---|
| `AuraController` | Layer 2 (State) | Confirmed: registered as `ChangeNotifierProvider` in `main.dart`'s `MultiProvider` tree, alongside `AppState`, `TruLuraModeController`, `ExperienceModeController` — a `ChangeNotifier` manages state, not rendering | **Done.** Renamed to `AuraStateController` across all call sites (`lib/providers/aura_state.dart`, `lib/main.dart`, and six consuming widgets/screens); zero references to the old name remain. |
| `HomeFeedScreen` (`lib/screens/home/home_feed_screen.dart`) | Layer 3 (Presentation) | Confirmed: `class HomeFeedScreen extends StatefulWidget`, holding only UI state (tab controller, pulse animation). It is not a router-level destination — it is the "Aura" tab nested inside `HomeHubScreen`, which itself is one of four `StatefulShellRoute` branches owned by `MainShell` | **Not started.** If renamed, target name and scope need to account for the existing, unrelated `HomeHubScreen` class one level up — not decided in this record. |
| `AuraField` | Not a standalone component | Checked: no "list of noted-missing components" exists anywhere in this repo. What does exist is a private, already-implemented `_HeroAuraFieldPainter` class in `lib/widgets/trulura_profile_hero_card.dart` | **No migration needed as a rename** — there is nothing shipped under this name to rename. Whether a future public `AuraField` component is still wanted is undecided. |

**This table reflects verified source inspection, not name-based inference.** An earlier draft of this same table was built from names that do not exist in this repository and has been superseded by this version.

---

## AB-010 (bottom navigation item count) — reopened, not resolved

An earlier draft of this record claimed AB-010 was resolved: that the Feb 2026 specification's six-item count and the shipped build's five-item count were reconciled by treating the center Post button as a modal action rather than a navigation destination, counted against five named screens (`AuraFeedScreen`, `SyncScreen`, `ExploreScreen`, `MessagesScreen`, `ProfileScreen`).

That reasoning does not survive contact with the real source. Verified directly against `lib/screens/main_shell.dart`, `lib/core/navigation/app_router.dart`, and `lib/widgets/trulura_bottom_nav.dart`:

- The router defines **four** `StatefulShellBranch` destinations: `home` (→ `HomeHubScreen`), `messages` (→ `ChatListScreen`), `notifications` (→ `NotificationsScreen`), `profile` (→ `ProfileScreen`).
- Sync and Explore are **not** nav destinations. They are tabs inside `HomeHubScreen`'s own internal `TabController`, alongside Aura — invisible to the router entirely.
- The bottom nav widget renders four tappable `_NavItem`s (labeled "Worlds," "Connect," "Pulse," "Identity") plus a center `PostOrbButton` wired to `onPost`, which pushes `AppRoutes.createPost` (`lib/screens/post/create_post_screen.dart`) as a separate route — this part of the original reasoning (Post is an action, not an indexed destination) does hold structurally.

So the real shape is four indexed destinations plus one non-indexed action — a different count than either the spec's six or the previous draft's five, arrived at for different reasons than previously stated. Reconciling this against what the Feb 2026 specification's six items actually enumerated requires re-reading that specification, not a code search. **AB-010 is reopened pending that review.**

---

## Resolved as a direct consequence of this decision

- None currently. AB-010 was the only item previously claimed resolved by this record, and it has been reopened above.

---

## What this decision does not resolve

- **Layer 3's object names**, including whether/how `HomeFeedScreen` should be renamed, are not specified here — any presentation-layer rename should be named for what it renders specifically (an `AuraRing`, an `AuraDisplay`, etc.), not migrated in bulk under one convention, and should account for its relationship to the existing `HomeHubScreen`.
- **AB-010** is reopened (see above) and needs the original Feb 2026 specification re-read against the real four-branch-plus-action structure before it can be closed.
- **PD-07** (revenue architecture) and **PD-18** (TruLuxe approval/legal review) remain fully open and are unaffected by this decision.
- This decision does not retroactively resolve whether every historical document using "Aura" in the computed-signal sense was describing what is now Layer 1 or Layer 2 — each such reference should still be read in its own context, not assumed to mean "Layer 2" merely because that reading now dominates the historical count.

---

*This record is the first formal Product Owner authoring decision produced by this reconstruction, following the same discipline applied to every recovered historical claim: Claim Type, Provenance Level, and — for the parts that are genuinely new — explicit labeling as Design Decision rather than Recovered Fact. It should be read alongside the Master Consolidated Reference's own entries on Aura, Mood, and AB-010, which this record supersedes on those specific points.*
