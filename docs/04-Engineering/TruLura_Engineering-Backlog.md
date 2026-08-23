Living Document · Re-published as work is identified · No code modified without approval
TruLura Engineering Backlog
Every piece of work identified during architecture review, tracked as one item each — problem, files, difficulty, dependencies, priority, sprint candidate, and how it traces back to the blueprint and the debt register. This list grows every session; nothing here has been built yet, and nothing is removed without a recorded reason.

Source TruLura Systems & Debt Review + Architecture Map + Engineering Governance
Status 18 open items; all "Open" — no item has moved to "In Progress" pending your approval
18
Open items
3
Critical
6
High
6
Medium
3
Low
Priority
Critical
High
Medium
Low
Difficulty
Small
Medium
Large
Sprint
Sprint 1–3 / Post Beta
Changelog
This revision adds a Sprint Candidate field and a Status field to every existing item (all currently Open), and adds two new items — ENG-017 (zero test coverage) and ENG-018 (uneven documentation) — surfaced by the standing Repository Health check. No item has been removed or reprioritized without this note.

Critical
3 items
ENG-001
Consolidate identity into one canonical store
Critical
Medium
Sprint 1
Open
Problem
User identity is cached independently in AppProvider, UserService, IdentityService, and IdentityProfileService. Only 4 write paths in the whole app (all onboarding) refresh AppProvider after a write — every other identity/trust/privacy edit leaves it stale.

Affected files
providers/app_provider.dart
services/user_service.dart
services/identity_service.dart
services/identity_profile_service.dart
~20 write-path call sites
Dependencies
None — can start immediately once approved

Suggested order
1st — foundational, most other state work builds on this

Related blueprint sections
Pending blueprint

Related product decisions
PD-01 — does the modernized blueprint keep per-mode identity profiles as a distinct concept, or fold them into one profile?

Related engineering gaps
Systems & Debt Review TD-01, TD-13, TD-15 · ADR-01 (Unified Session Object) · feeds directly into ENG-002

Sprint candidate — why
Sprint 1: foundational architecture. Not started — waiting on blueprint modernization, the navigation-shell decision, and Feature-to-Code Matrix confirmation, per your instruction not to begin this or the Unified Session Object yet.

ENG-002
Design and build real backend for Chat and Sync
Critical
Large
Sprint 2
Open
Problem
ChatService and SyncService persist only to per-device SharedPreferences. As built, two real users cannot message or match with each other — messages and matches don't leave the device that created them.

Affected files
services/chat*service.dart
services/sync_service/sync_service.dart
screens/chat/*
screens/sync/\_
new: supabase/migrations/\*
Dependencies
Schema design needs product input on match/message semantics before engineering work starts

Suggested order
Start schema design now; implementation blocks on it

Related blueprint sections
Pending blueprint — directly determines Sync/Vent/Chat scope

Related product decisions
PD-02 — must Sync/Chat be functional between real users for Beta, or can they ship local-first for a soft launch?

Related engineering gaps
Systems & Debt Review TD-05 · ADR-05 (Backend Strategy) · blocks real multi-user testing of two blueprint systems

Sprint candidate — why
Sprint 2: a Beta feature build, not foundational architecture — it depends on a product schema decision (PD-02) rather than on ENG-001. Classified Critical because, unresolved, it silently caps two named blueprint systems at "looks real, isn't."

ENG-003
Unify the two competing mood/emotional-state systems
Critical
Medium
Sprint 1
Open
Problem
emotionalPresenceState and AuraController.state.mood are unrelated and can visibly disagree in the same screen (confirmed on the TruCompanion header). A mood-chip tap changes 4 widgets but not the value driving feed pacing app-wide.

Affected files
providers/app_provider.dart
providers/aura_state.dart
screens/ai/ai_companion_screen.dart
screens/home/home_hub_screen.dart
Dependencies
Benefits from ENG-001 landing first (same session-object direction) but can be done standalone as a smaller write-through fix

Suggested order
2nd, alongside or right after ENG-001

Related blueprint sections
Pending blueprint

Related product decisions
None required — user-visible bug fix regardless of blueprint direction

Related engineering gaps
Systems & Debt Review TD-02 · TD-03 (mood-color duplication) is a direct follow-on · ADR-01

Sprint candidate — why
Sprint 1: foundational architecture, same wave as ENG-001 since both reshape what "current user state" means.

High
6 items
ENG-004
Introduce a composed session provider (AppUserSession)
High
Large
Sprint 1
Open
Problem
5 independent sibling ChangeNotifiers with no composition root make identity/mood fragmentation (ENG-001, ENG-003) structurally likely to recur with every new feature.

Affected files
main.dart
providers/\*.dart (all 5)
every screen reading 2+ providers
Dependencies
ENG-001 and ENG-003 should land first as smaller proofs of the target shape before this larger restructure

Suggested order
After ENG-001/003, before ENG-009 and ENG-013 (Companion/Creator state) so new features land on the new pattern

Related blueprint sections
Pending blueprint

Related product decisions
PD-03 — does the modernized blueprint add any new cross-cutting state (e.g. a new top-level mode) that the session object needs to account for before it's built?

Related engineering gaps
Systems & Debt Review TD-13 · State Management Review §04 · ADR-01 (Unified Session Object) — Proposed, not approved

Sprint candidate — why
Sprint 1: foundational architecture — this is the Unified Session Object itself. Explicitly not started per your instruction: waiting on blueprint modernization, the navigation-shell decision, and Feature-to-Code Matrix confirmation before implementation begins.

ENG-005
Introduce a repository layer for existing Supabase tables
High
Medium
Sprint 1
Open
Problem
No formal repository layer exists — services mix business logic and raw Supabase query construction, making backend swaps or new-model work land on an inconsistent base.

Affected files
services/user_service.dart
services/post_service.dart
providers/app_provider.dart
new: repositories/\*.dart
Dependencies
None technically, but most valuable if done before ENG-002 and ENG-006 so new backend work uses the improved pattern

Suggested order
Before any new backend model work (ENG-002, ENG-006, ENG-013)

Related blueprint sections
Pending blueprint

Related product decisions
None

Related engineering gaps
Systems & Debt Review TD-04 · ADR-02 (Repository Pattern)

Sprint candidate — why
Sprint 1: foundational architecture — a prerequisite pattern for every subsequent backend item, so it belongs in the same wave as ENG-001/003/004.

ENG-006
Build a real Notifications system
High
Large
Sprint 2
Open
Problem
NotificationsScreen renders entirely hardcoded demo data — no model, service, provider, or table exists.

Affected files
screens/notifications/notifications_screen.dart
new: models/notification.dart
new: services/notification_service.dart
new: supabase/migrations/\*
Dependencies
ENG-005 (repository layer) should exist first; needs a decision on delivery mechanism (poll vs. realtime)

Suggested order
After ENG-005; scope depends heavily on blueprint priority

Related blueprint sections
Pending blueprint

Related product decisions
PD-04 — is real-time delivery required for Beta, or is a polling/badge-count model sufficient?

Related engineering gaps
Systems & Debt Review TD-06, missing-backend-models §08

Sprint candidate — why
Sprint 2: Beta feature build, tentative — could slip to Post Beta if the blueprint doesn't require real-time notifications at launch (see PD-04).

ENG-007
Collapse the five mood-to-color systems into one
High
Medium
Sprint 1
Open
Problem
MoodColors.glow, AuraController.colorForMood, a hand-duplicated copy inside HomeHubScreen, and the legacy TruLuraTheme adapter all coexist alongside the actual shared kTruLuraPalettes system.

Affected files
theme/mood_colors.dart
providers/aura_state.dart
screens/home/home_hub_screen.dart
theme/trulura_theme.dart
widgets/feed_card.dart
widgets/trulura_event_carousel_row.dart
Dependencies
Best sequenced after ENG-003 (mood unification) since mood becomes part of the same source of truth

Suggested order
Right after ENG-003

Related blueprint sections
Pending blueprint

Related product decisions
Visual QA sign-off needed since the four systems currently produce different colors for the same mood

Related engineering gaps
Systems & Debt Review TD-03

Sprint candidate — why
Sprint 1: foundational architecture, riding directly on ENG-003's completion in the same wave.

ENG-008
Decide the fate of the unused AuthManager abstraction
High
Small (to decide)
Post Beta
Open
Problem
AuthManager/SupabaseAuthManager implement a complete multi-provider auth contract (Apple/Google/JWT/etc.) that's never instantiated — dead code masquerading as active infrastructure to anyone reading the file tree.

Affected files
auth/auth_manager.dart
auth/supabase_auth_manager.dart
Dependencies
None — pure product/architecture decision, currently protected from changes without explicit approval

Suggested order
Decision can happen anytime; not blocking other work

Related blueprint sections
Depends on whether social/Apple/Google sign-in is in the modernized blueprint

Related product decisions
PD-05 — is multi-provider sign-in on the roadmap at all?

Related engineering gaps
Systems & Debt Review TD-09

Sprint candidate — why
Post Beta: flagged High priority as a decision (it shouldn't sit ambiguous indefinitely), but the underlying code work — finish or deprecate — isn't Beta-blocking either way.

ENG-009
Give TruCompanion persistent state
High
Medium
Sprint 2
Open
Problem
Companion reflections and session state live only in StatefulWidget fields — everything is lost on navigation away or hot restart, for what reads as a core retention feature.

Affected files
screens/ai/ai_companion_screen.dart
new: services/companion_service.dart
new: providers/companion_state.dart
Dependencies
Should follow ENG-004 (session provider) so it lands on the new state pattern rather than adding a 6th sibling provider

Suggested order
After ENG-004

Related blueprint sections
Pending blueprint — directly determines Companion's intended depth

Related product decisions
PD-06 — should companion history sync across devices (Supabase) or stay local-first (SharedPreferences) for now?

Related engineering gaps
Systems & Debt Review TD-12

Sprint candidate — why
Sprint 2: a Beta feature build gated on ENG-004 landing first, not itself foundational architecture.

Medium
6 items
ENG-010
Remove the boot-time duplicate user fetch
Medium
Small
Sprint 1
Open
Problem
SplashScreen.\_checkAuth() independently re-fetches and overwrites the user that AppProvider.initialize() already fetched and merged more richly moments earlier, using different merge logic.

Affected files
screens/splash_screen.dart
Dependencies
None — can land independently and immediately, reduces the surface area for ENG-001

Suggested order
Anytime, ideally before or alongside ENG-001

Related blueprint sections
None

Related product decisions
None

Related engineering gaps
Systems & Debt Review TD-15

Sprint candidate — why
Sprint 1: small, standalone, and directly de-risks ENG-001 — worth doing in the same wave even though it isn't itself "foundational."

ENG-011
Migrate onboarding onto the shared background system
Medium
Small
Sprint 3
Open
Problem
All 5 onboarding screens use a static, non-reactive gradient scaffold that ignores soft mode, emotional presence, and the shared mode/tone system — the first thing every user sees is disconnected from the rest of the app's feel.

Affected files
features/onboarding/onboarding_scaffold.dart
theme/trulura_theme.dart
Dependencies
None

Suggested order
Independent — can happen any time, high visibility for low effort

Related blueprint sections
Pending blueprint

Related product decisions
None

Related engineering gaps
Systems & Debt Review TD-07 · Ecosystem Cohesion Audit

Sprint candidate — why
Sprint 3: UX polish — visible and worthwhile, but not something Beta functionally depends on.

ENG-012
Extend persistent chrome beyond the 4 shell tabs
Medium
Large (total)
Sprint 3
Open
Problem
26 of ~30 screens rebuild their own Scaffold and app bar from scratch instead of using the already-existing, underused TruluraScreenShell.

Affected files
widgets/trulura_screen_shell.dart
~26 screens under screens/\*
Dependencies
None — recommended as opportunistic work done alongside other changes to each screen rather than a dedicated sweep

Suggested order
Low urgency — fold into other screen-touching work as it comes up

Related blueprint sections
Related to PD-07 (navigation shell direction — see ADR-03)

Related product decisions
PD-07 — should the modernized navigation shell wrap all screens, or is the current tab-only chrome intentional for full-screen "modal" flows (settings, vent, matchroom)?

Related engineering gaps
Systems & Debt Review TD-08 · Ecosystem Cohesion Audit · ADR-03 (Navigation Shell)

Sprint candidate — why
Sprint 3: UX polish, and explicitly blocked on PD-07/ADR-03 being resolved before a consistent direction can even be defined.

ENG-013
Design a real Creator Platform backend
Medium
Large
Post Beta
Open
Problem
TruStudioScreen is a fully-built 6-tab shell (Dashboard/Live Tools/Subscribers/Brand Deals/Content/Payouts) gated by real AppProvider flags, but zero Supabase tables exist for creators, subscribers, or payouts — the gating infrastructure was built well ahead of the feature it gates.

Affected files
screens/trustudio/trustudio_screen.dart
providers/app_provider.dart
new: models/creator_profile.dart
new: supabase/migrations/\*
Dependencies
ENG-005 (repository layer) recommended first; heavily dependent on blueprint scope for Creator Platform

Suggested order
Priority TBD entirely by blueprint — likely later-phase given no backend exists at all today

Related blueprint sections
Pending blueprint

Related product decisions
PD-08 — does Creator Platform ship in Beta at all, or do the gating flags stay off for launch?

Related engineering gaps
Unified Ecosystem Evaluation — Creator Platform

Sprint candidate — why
Post Beta by default given zero existing backend, pending PD-08 — could move to Sprint 2 if the blueprint says otherwise.

ENG-017
Establish a test suite — currently zero coverage
Medium
Large
Sprint 1
Open
Problem
The test/ directory contains zero files. flutter_test is a listed dev dependency but nothing uses it — every service, provider, and screen in the app is completely unverified by automated tests.

Affected files
new: test/\*\*
— highest value starting with
providers/app_provider.dart
,
services/user_service.dart
, the router's redirect logic
Dependencies
None to start; most valuable if tests are added for the exact areas ENG-001/003/004/005 are about to change

Suggested order
Start alongside ENG-001 — write characterization tests for identity/mood merge logic before refactoring it, not after

Related blueprint sections
None

Related product decisions
None

Related engineering gaps
Repository Health check (new, this revision) — no prior TD entry existed for this before now

Sprint candidate — why
Sprint 1: foundational — a safety net is worth more before the Sprint 1 refactors (ENG-001/003/004/005) than after them.

ENG-018
Close documentation gaps in the least-documented ~52% of the codebase
Medium
Medium
Post Beta
Open
Problem
Only 78 of 163 Dart files in lib/ carry any /// doc comment — documentation coverage is real but uneven, concentrated in newer/local-first services and thin elsewhere.

Affected files
~85 undocumented files, concentrated in widgets/ and screens/
Dependencies
None — best done opportunistically as files are touched for other reasons

Suggested order
Low urgency; fold into other work rather than a dedicated sweep

Related blueprint sections
None

Related product decisions
None

Related engineering gaps
Repository Health check (new, this revision)

Sprint candidate — why
Post Beta: pure maintainability polish, zero functional or Beta risk.

Low
3 items
ENG-014
Remove the unused Riverpod dependency
Low
Small
Post Beta
Open
Problem
main.dart wraps the app in a real ProviderScope from flutter_riverpod, but zero Riverpod providers or consumers exist anywhere else — confusing scaffolding for anyone reading the codebase fresh.

Affected files
main.dart
pubspec.yaml
Dependencies
None

Suggested order
Anytime — trivial, zero-risk cleanup

Related blueprint sections
None

Related product decisions
None

Related engineering gaps
Systems & Debt Review TD-14

Sprint candidate — why
Post Beta: zero urgency, zero risk, purely cosmetic.

ENG-015
Standardize on one Supabase client accessor
Low
Small
Sprint 1
Open
Problem
Two access paths to the same Supabase client coexist (DatabaseService.instance.client vs. SupabaseConfig.client/.auth called directly), plus a third, fully-unused accessor.

Affected files
providers/app_provider.dart
screens/home/home_feed_screen.dart
core/supabase_client.dart (retire once migrated)
Dependencies
None

Suggested order
Trivial — pairs naturally with ENG-005's repository work

Related blueprint sections
None

Related product decisions
None

Related engineering gaps
Systems & Debt Review TD-11

Sprint candidate — why
Sprint 1: trivial, but bundled with ENG-005 since both touch the same access pattern.

ENG-016
Deduplicate the OpenAI request helper
Low
Small
Post Beta
Open
Problem
suggestReplies and suggestMatchConciergeTips each hand-build near-identical HTTP request/error-handling logic, with no timeout and no user-facing fallback when the proxy isn't configured.

Affected files
openai/openai_config.dart
Dependencies
None

Suggested order
Anytime — single-file refactor

Related blueprint sections
None

Related product decisions
PD-09 — what should happen in the UI when AI suggestions are unavailable? Currently undefined.

Related engineering gaps
Systems & Debt Review TD-16

Sprint candidate — why
Post Beta: low-traffic code path, cosmetic duplication, not user-facing on its own.

Awaiting the blueprint
not yet numbered
—
Blueprint-derived items (Feature-to-Code & Blueprint-to-Code gaps)
TBD
Pending
Problem
Once the blueprint is shared, comparing it against everything documented in the Architecture Map and Systems & Debt Review will surface additional backlog items — missing systems, scope mismatches, and Beta-blocking gaps not visible from code alone.

Next step
This list will be extended with new ENG-0xx items, every existing item will get a confirmed (not inferred) blueprint cross-reference, and Sprint Candidates will be re-checked against real Beta scope as soon as the blueprint file/link arrives.

This backlog is designed to be re-published to the same link as work is identified in future sessions — items are added, never silently removed, and priority/difficulty/sprint are re-assessed as dependencies land, always with a recorded reason in the changelog above. No code has been modified to produce this list, and none will be without explicit approval.
