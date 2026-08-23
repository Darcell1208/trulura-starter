TruLura Governance
Standing Engineering Mode
Mandate & scope
Architecture Decision Records
Product Decisions register
Engineering Standards
Repository Impact Notes
Beta Engineering Dashboard
Code Review Mode
Standing Governance · Read-only · No code modified, no product behavior changed, without approval
TruLura Engineering Governance
Architecture Decision Records, the Product Decisions log, engineering standards, and the Beta burn-down — the layer that turns findings into tracked decisions instead of one-off recommendations.

Mode Principal Software Architect & Engineering Reviewer, standing
Companions Architecture Map · Systems & Debt Review · Engineering Backlog
5
ADRs, all Proposed
9
Product decisions logged
0
Decisions approved yet
8
Engineering standards
18
Backlog items tracked
00
Mandate & scope
Operating as Principal Software Architect and Engineering Reviewer for the TruLura Flutter repository. The mandate is preparation and alignment, not redesign: keep the repository ready to support the blueprint as it's modernized separately, surface every recommendation with Problem / Evidence / Recommendation / Risk / Migration Strategy / Estimated Effort, and check every recommendation against the Incremental Architecture Rule before writing it up — a large rewrite is never proposed if a staged migration is possible (see the compliance table in the Systems & Debt Review, §02). No code is modified and no product behavior changes without explicit approval; this document and its companions are records and recommendations, nothing more.

Flagging a numbering gap

The mission referenced "the navigation decision (PD-14)" as a resolution gate. No Product Decisions register existed before this document — numbering starts fresh at PD-01 below. The one pending navigation-architecture decision identified in the repository is logged here as PD-07. If PD-14 refers to a decision tracked outside this session (e.g. in your own planning system), let me know its content and I'll reconcile the numbering rather than guess at it.

01
Architecture Decision Records
Records of significant architectural recommendations that emerged from the review — not implementations. Every one below is Proposed, meaning it reflects this review's recommended direction and is explicitly waiting on your approval, per your instruction not to begin ENG-001 or the Unified Session Object yet.

ADR-01
Unified Session Object
Proposed
Decision
Whether to replace the 5 independent sibling ChangeNotifier providers with one composed session object that owns identity, emotional, profile, companion, and sync sub-state.

Context
Identity is fragmented across 4 stores (TD-01); mood exists twice and can visibly disagree (TD-02); the 5-provider topology has no composition root (TD-13). These aren't independent bugs — they're symptoms of the same missing piece.

Alternatives considered
Keep the 5 siblings, patch every write path to refresh AppProvider — treats the symptom (TD-15/TD-01's stale-state problem) without fixing the topology; new features would keep reproducing the same fragmentation.
Fully adopt Riverpod (the dormant dependency already in pubspec.yaml) as the new state layer — a larger, non-incremental change happening at the same time as a structural rewrite; rejected under the Incremental Architecture Rule (see ADR-04).
One composed session object, introduced incrementally — matches the one composition pattern already in the codebase (ExperienceModeController already takes AppProvider as a dependency), smallest structural change that addresses the root cause.
Chosen direction
The third option — recommended, not yet approved.

Reasoning
Fixes the structural cause rather than each symptom individually; builds on an existing, proven composition pattern in the codebase rather than introducing a new one.

Consequences
Every screen currently reading 2+ providers eventually migrates its reads; the 5 existing providers are retired only once nothing references them. Unlocks consistent identity/mood/companion/sync state as a direct side effect.

Migration notes
See TD-13's migration strategy in the Systems & Debt Review. Explicitly not started — waiting on blueprint modernization, PD-07 (navigation shell direction) being resolved, and Feature-to-Code Matrix confirmation, per your instruction.

ADR-02
Repository Pattern
Proposed
Decision
Whether to introduce a formal repository layer between services and Supabase.

Context
Zero classes matching _Repository_ exist anywhere in lib/; services mix business logic and raw query construction in the same methods (TD-04).

Alternatives considered
Leave as-is — the inconsistency compounds every time a new backend model is added (Notifications, Chat, Sync, Creator Platform all pending).
Adopt a full ORM/codegen layer — likely overkill for 6 tables and adds a new dependency the incremental rule doesn't obviously justify yet.
Thin, manually-written repository interfaces per model — minimal surface change, no new dependency.
Chosen direction
Thin manual repositories — recommended, not yet approved.

Reasoning
Smallest change that separates "what data looks like" from "how it's fetched," which is the actual gap; fits the team's current patterns without new tooling.

Consequences
Services become thinner; every new backend model (TD-05, TD-06, Creator Platform) lands on the improved pattern from day one instead of extending the old one.

Migration notes
TD-04's migration strategy — one repository per existing table, no behavior change per step.

ADR-03
Navigation Shell
Proposed / Undecided
Decision
Whether MainShell's persistent chrome (app bar, bottom nav, ambient background transition) should extend beyond its current 4 tab branches to cover some or all of the other ~25 routes.

Context
26 of ~30 screens currently rebuild their own Scaffold independently (TD-08). Some of that may be intentional — settings, vent, and matchroom plausibly read as deliberate full-screen "modal" flows that should break out of tab chrome, not an oversight.

Alternatives considered
Leave as-is, formally documenting which routes are intentionally "modal" vs. accidentally inconsistent.
Extend MainShell to wrap every route — largest option, likely unnecessary for true modal flows.
Standardize the already-existing TruluraScreenShell as shared app-bar/back-button chrome for non-tab routes, without literally nesting them inside the bottom-nav shell.
Chosen direction
Not yet decided — this is the one ADR in this set with no recommended direction, since the right answer depends on product intent (is settings/vent/matchroom meant to feel like a break from the tab flow, or not?), which sits outside what code alone can answer.

Reasoning
Flagged as undecided rather than guessed, per the standing rule to ground findings in evidence, not speculation.

Consequences
This decision gates ENG-012 directly, and gates ADR-01/ENG-004 indirectly, per your explicit instruction that the navigation decision must resolve before Unified Session Object work begins.

Migration notes
See PD-07 below — logged as the corresponding open product decision.

ADR-04
State Management Approach
Proposed
Decision
Whether to continue building on the hand-rolled provider_compat.dart mechanism, or migrate to the dormant flutter_riverpod dependency, or another library entirely.

Context
main.dart wraps the app in a real, working Riverpod ProviderScope, but zero Riverpod providers or consumers exist anywhere (TD-14). The actual state mechanism everywhere else is provider_compat.dart, which works correctly.

Alternatives considered
Fully adopt Riverpod now, migrating the composed session object (ADR-01) straight onto it — compounds two large changes (new topology + new library) at once.
Adopt Bloc/Cubit — a larger library switch with no evidence it solves a problem provider_compat.dart doesn't already solve; rejected under the Incremental Architecture Rule.
Keep provider_compat.dart, remove the unused Riverpod dependency as separate cleanup (TD-14), build ADR-01's session object on the existing mechanism.
Chosen direction
The third option — recommended, not yet approved.

Reasoning
provider_compat.dart already works and is used in 57+ files; switching the underlying library at the same moment as restructuring the provider topology would violate the Incremental Architecture Rule by compounding two large changes into one.

Consequences
Riverpod dependency removed (TD-14); if a future need for Riverpod-specific features (codegen, testing ergonomics) emerges, that becomes its own separate ADR rather than being bundled here.

Migration notes
TD-14's migration strategy — delete the wrapper, confirm via flutter analyze.

ADR-05
Backend Strategy
Proposed
Decision
Which feature areas get real Supabase backing before Beta, and in what order.

Context
Chat, Sync, Notifications, Companion, and Creator Platform all currently lack real backend support (Backend Readiness §05 in the Systems & Debt Review) despite reading as backend-driven features.

Alternatives considered
Build every missing backend before Beta — thorough but slow, and not evidence-justified until the blueprint confirms what's actually required at launch.
Adopt a separate third-party service for real-time chat specifically — a new dependency; Supabase already supports realtime channels (currently unused in lib/, per the Supabase Inventory), so this isn't yet justified.
Continue building on Supabase (the established backend), sequence the missing pieces by blueprint-confirmed Beta priority once available, and mark Chat/Sync provisionally Critical now because they're core to two named blueprint systems.
Chosen direction
The third option — recommended, with final sequencing explicitly pending the blueprint (Task 4, Backend Readiness prioritization).

Reasoning
No evidence yet justifies introducing a second backend platform; Supabase already covers everything currently needed, including realtime capability not yet exercised.

Consequences
ENG-002, ENG-006, ENG-013 all build on this direction; their relative order is the open question, not the platform choice.

Migration notes
Schema design work can start now per feature (TD-05); implementation sequencing waits on the blueprint.

02
Product Decisions Register
Every open product-level question surfaced by the engineering review, numbered for reference from the Backlog and ADRs above. None of these are engineering's to resolve — logged here so they're visible and traceable rather than buried in prose.

ID Question Raised by Status
PD-01 Does the modernized blueprint keep per-mode identity profiles as a distinct concept, or fold them into one profile? ENG-001 Open
PD-02 Must Sync/Chat be functional between real users for Beta, or can they ship local-first for a soft launch? ENG-002 Open
PD-03 Does the blueprint add any new cross-cutting state the session object (ADR-01) needs to account for before it's built? ENG-004 Open
PD-04 Is real-time notification delivery required for Beta, or is a polling/badge-count model sufficient? ENG-006 Open
PD-05 Is multi-provider sign-in (Apple/Google/etc.) on the roadmap at all? ENG-008 / ADR pending Open
PD-06 Should companion history sync across devices (Supabase) or stay local-first for now? ENG-009 Open
PD-07 The navigation-shell decision — should persistent chrome extend beyond the 4 tab branches, or is the current break-out pattern for settings/vent/matchroom intentional? ENG-012, ADR-03 Blocking ADR-01/ENG-004 per your instruction
PD-08 Does Creator Platform ship in Beta at all, or do the existing gating flags stay off for launch? ENG-013 Open
PD-09 What should happen in the UI when AI suggestions are unavailable (proxy unconfigured or failing)? ENG-016 Open
03
Engineering Standards
Conventions the repository should hold to going forward, each one a direct lesson from a specific finding rather than a generic best practice.

Standard Motivated by
New backend data access goes through a repository, never directly through a service. ADR-02 / TD-04
New cross-cutting state joins the composed session object once ADR-01 lands — no new sibling ChangeNotifier providers. ADR-01 / TD-13
Every write path that mutates identity or session-relevant state updates the canonical store synchronously — no writes that leave shared state stale. TD-01 / TD-15
Every new screen consumes the shared theme/mode state (kTruLuraPalettes / emotionalPresenceState) rather than hardcoding colors or re-deriving mood-to-color logic locally. TD-03
Every new external API integration uses a shared request helper with a timeout and a defined fallback UI state — no bare, unguarded calls. TD-16
No feature ships reading as backend-driven unless it actually is. Local-first is fine — it must be visibly labeled and tracked as such. TD-05 / TD-06
Every new module lands with at least one test covering its core logic. TD-17
Every new public class or service gets a short doc comment stating its role. TD-18
04
Repository Impact Notes
Awaiting the first blueprint update

This section activates the first time the blueprint introduces a new canonical decision. Per the standing Blueprint Synchronization rule, each entry here will identify: affected Flutter modules, affected Supabase tables, affected providers, affected services, affected models, and a migration strategy — then the Feature-to-Code Matrix, Blueprint-to-Code Matrix, and Engineering Backlog get updated in lockstep. No blueprint change has landed yet, so there is nothing to record — this section is a placeholder, ready to receive entries, not evidence of anything decided.

05
Beta Engineering Dashboard
A live count against the Engineering Backlog. Update trigger: any time the backlog changes.

3
Critical blockers
6
High-priority blockers
6
Medium blockers
0
Completed blockers
18
Remaining blockers
Sprint distribution
Sprint 1
8
Sprint 2
3
Sprint 3
2
Post Beta
5
Estimated sprint impact
Sprint 1 (8 items — ENG-001, 003, 004, 005, 007, 010, 015, 017) is entirely foundational-architecture and correctness work; none of it changes user-visible product behavior. It is also entirely not started, gated on the blueprint, PD-07 (the navigation decision), and Feature-to-Code Matrix confirmation, per your explicit instruction.
Sprint 2 (3 items — ENG-002, 006, 009) is where Beta feature scope actually gets built or de-scoped; ENG-002 (Chat/Sync backend) is the single highest-impact item in this wave since it's gating two named blueprint systems.
Sprint 3 (2 items — ENG-011, 012) is UX polish; low risk to slip without affecting Beta functionality.
Post Beta (5 items — ENG-008, 013, 014, 016, 018) is decisions and cleanup with no Beta-blocking dependency identified.
Bottom line

Nothing in this dashboard is a green light — it's a burn-down of what's known, not a schedule commitment. Sprint 1's 8 items are the load-bearing wave everything else depends on, and all 8 are explicitly paused pending your approval and the three gating conditions named above.

06
Code Review Mode
Standing behavior for when future implementation work lands: review for correctness, architecture, maintainability, consistency, scalability, accessibility, performance, and alignment with the blueprint — recommendations before merge, not automatic changes. Nothing has been implemented yet, so this section has nothing to review; it activates the first time a backlog item moves to "In Progress" and lands a change.

Standing governance layer for the TruLura repository — every ADR here is Proposed, not Accepted; every Product Decision is Open, not resolved by engineering. No code has been modified and no product behavior has changed to produce this document, and none will without your explicit approval.
