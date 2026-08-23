# TruLura Repository Architecture

*Every statement below is grounded in either the Flutter repository itself or an existing document (cited by path). Where information does not exist in either, this document says "Not Yet Defined" rather than inventing it. Full layer-by-layer detail (App Entry, Navigation, Auth, Supabase, Providers, Services, Models, Repositories, Widgets, Screens, Data/State/Backend Flow) lives in `TruLura_Architecture-Map.md` in this folder — this document does not repeat that content, it synthesizes it against the Blueprint to answer one question: where does the repository already align with the Product Knowledge System, where does it diverge, and what should be built next.*

## Stack

Flutter + Supabase + a hand-rolled `provider_compat.dart` state layer (see Architecture Map §01, §12). Blueprint Section 23 (Infrastructure) deliberately names no required stack (Engineering Constitution, §"Infrastructure Is Deliberately Stack-Agnostic") — this choice is compatible with the Blueprint, not a divergence from it.

## Where the Repository Already Aligns

| Blueprint system | Alignment |
|---|---|
| Session (Supabase Auth) | Strong — the one genuinely single source of truth in the app; `AuthService` + `onAuthStateChange` + router redirect all agree consistently (Architecture Map §03, §04) |
| Vent Space (§14) | Confirmed Core Beta, and exists in code as an isolated feed space with real visibility isolation (`VisibilityService`), matching the Blueprint's isolation intent |
| Experience Modes (§2/3) | Confirmed Core Beta, and exists in code with real gating logic (`ExperienceModeController`, 8 modes) |
| Discovery/Aura base (§4) | Confirmed Core Beta (base), exists with a real ranking algorithm (`FeedDistributionEngine`) — worth reviewing against Blueprint EG-04 (ranking formula gap) as a candidate answer, not just a gap to fill blind |
| Interface/UI (§20) | The interface philosophy (adaptive, minimally intrusive, mode-reactive) is substantially built (`TruLuraLayeredBackground`, `kTruLuraPalettes`, `emotionalPresenceState`) — genuinely well-executed where adopted, per the Ecosystem Cohesion Audit folded into the Architecture Map |

## Where the Repository Diverges — Including Two Constitutional Violations

Most divergence is ordinary technical debt (see `TruLura_Technical-Debt.md` in this folder). Two are more serious: they contradict a stated principle in `docs/01-Constitution`, not just an implementation preference.

- **Identity is not singular in code, though the Product Constitution requires it to be.** "Each user has one master identity" (Blueprint §1.1; Product Constitution, "Identity Is Singular and Contextual, Not Fragmented"). In the repository, identity is cached independently in four places (`AppProvider`, `UserService`, `IdentityService`, `IdentityProfileService`) with no single source of truth, and only 4 of many write paths keep them in sync (Architecture Map §14, Emotional Core Audit; Systems & Debt Review TD-01). This is the clearest case in the repository of a Guiding Principle being violated by accretion, not by design intent.
- **MoodSync is not one system in code, though Guiding Principle 5 requires it to be.** "MoodSync is the one emotional source of truth" — every system that needs emotional context should consume MoodSync's signals, none should maintain a parallel model (Guiding Principles §5, citing Blueprint §11.2.3/§12.11.1). In the repository, `emotionalPresenceState` (on `AppProvider`) and `AuraController.state` are two independent, unsynced mood representations that can visibly disagree on the same screen (Systems & Debt Review TD-02; Blueprint-to-Code Matrix, finding 3).

## What's Missing Entirely (No Code Found)

Per the Blueprint-to-Code Matrix's full 26-section pass: Monetization & Creator Economy backend (§7/8), the AI Decision Engine beyond two narrow OpenAI calls (§11), Orchestration/Social Ecosystem (§19), a Notifications backend (§10.13), Companion persistence (§15, pending PD-11), a Governance/admin surface (§24 — the Blueprint itself expects this as a likely separate app), and Gamification (§18, Beta status genuinely unclear pending PD-16). TruTravel (§16) and TruLuxe (§17) are correctly absent — both are explicit Phase 2.

## Prioritized Implementation Plan

Grounded in the Beta Readiness Checklist's own blocking analysis (`docs/02-Product/TruLura_Beta-Readiness-Checklist.md.md`) and the Engineering Backlog's Sprint Candidates (`docs/04-Engineering/TruLura_Engineering-Backlog.md`). This is a sequencing plan, not authorization to begin — no code changes have been made.

**Phase 0 — Not engineering's to unblock.** Five items block Core Beta regardless of any code readiness, and none are pure engineering problems (Beta Readiness Checklist, final summary): PD-14 (navigation contradiction), PD-12 (crisis detection, needs Trust & Safety), PD-01/PD-15 (four-way trust tier naming), PD-19 (payment/verification vendor selection), PD-20 (data retention policy). Engineering work that depends on these should not proceed past the point where it would have to guess the answer.

**Phase 1 — Foundational, no Product blocker, not yet started.** ENG-001 (identity consolidation), ENG-003 (MoodSync unification — directly resolves the constitutional violation above), ENG-005 (repository layer), ENG-010 (remove duplicate boot fetch), ENG-015 (standardize Supabase accessor), ENG-017 (begin test coverage on the areas about to be refactored). ENG-004 (the composed session object / Unified Session Object, ADR-001) is explicitly held until PD-14 resolves, per standing instruction — it is the architectural centerpiece of this phase but is not to be started yet.

**Phase 2 — Beta feature builds, each blocked on a specific resolution.** ENG-002 (Chat/Sync backend — Sync/Spark base is confirmed Core Beta; blocked on schema design and, for Chat specifically, on EQ-01 in `TruLura_Engineering-Governance.md` §02, since the Blueprint doesn't clearly name a Chat system). ENG-013's early-monetization slice (Creator Platform — confirmed Core Beta in part; blocked on PD-01 and the EG-11 progression-criteria remainder). ENG-006 (Notifications — Medium priority per the Blueprint's own EG-18, not urgent relative to Phase 0/1).

**Phase 3 / Post Beta.** ENG-008 (AuthManager decision), ENG-009 (Companion persistence, pending PD-11), ENG-012 (persistent chrome extent, pending PD-14/ADR-003), ENG-014 (remove unused Riverpod), ENG-016 (OpenAI helper dedup), ENG-018 (documentation). TruTravel, TruLuxe, Gamification, and Orchestration/Social Ecosystem have no code today and no Phase 1/2 dependency forcing them earlier.

## Not Yet Defined

- Exact data schemas for any not-yet-built backend model (Chat/Message, Match, Notification, Creator profile/subscriber/payout) — these depend on Product Decisions and Engineering Gaps not yet resolved (see `TruLura_Repository-Impact.md` in `04-Engineering`).
- Whether the repository's current 4-tab bottom nav + internal Aura/Sync/Explore tabs should be restructured — depends entirely on PD-14 (see ADR-003).
- Whether TruLura's admin/moderation surface (§24 Governance) will live in this repository at all, or as intended, a separate application.

## Cross-References

`TruLura_Architecture-Map.md` (full layer detail) · `TruLura_Blueprint-to-Code-Matrix.md` (per-section evidence) · `TruLura_Feature-to-Code-Matrix.md` (living feature-level tracker) · `TruLura_Technical-Debt.md` (architectural debt) · `docs/04-Engineering/TruLura_Engineering-Backlog.md` (item-level tracking) · `docs/04-Engineering/TruLura_Repository-Impact.md` (module-level Blueprint impact) · `docs/01-Constitution/` (the principles this document checks the repository against).
