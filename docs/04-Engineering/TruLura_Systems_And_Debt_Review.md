TruLura Systems & Debt
Engineering Review
Standing mission
Unified ecosystem evaluation
Technical debt register
Refactor candidates
State management review
Backend readiness (code-level)
API inventory
Supabase inventory
Missing backend models
Pending: blueprint tasks
Companion doc: the Repository Architecture Map, Navigation Map, and full current-state Data Model Inventory live in the separately published TruLura Architecture Map artifact — this document builds on it rather than repeating it.
Engineering Review · Read-only · No code modified without approval
TruLura Systems & Debt Review
Where the fourteen core systems stand today, what's costing the team velocity, and what a Principal-level cleanup pass would target first — grounded entirely in code, not assumption.

Scope lib/ only
Method full import/reference tracing across prior audit passes + fresh targeted verification
Companion living Engineering Backlog, published separately
00
Standing mission
Operating going forward as: prepare the Flutter repository for implementation, without building features unless explicitly instructed, and without modifying code without explicit approval. The blueprint is being modernized separately and hasn't reached this repo yet — every finding below is derived from the codebase alone. Two matrices (Feature-to-Code, Blueprint-to-Code) and full Beta-priority ranking stay open until it arrives; see §10. Once the blueprint is shared, the next pass will identify exactly which modules documented here need updates as a direct consequence.

01
Unified Ecosystem Evaluation
The fourteen systems named in the mission, each classified by what's actually in the code — not what the name implies. This directly answers "do these function as one ecosystem or independent systems": mostly the latter, with real shared infrastructure underneath that's inconsistently adopted.

System Status Evidence
Identity Partially exists Real and rich (User model, AuthService, onboarding flow) but fragmented across 4 independent stores that don't sync (see §03 emotional-core findings, carried from the Architecture Map).
Session Exists Supabase auth session is the one genuinely single source of truth in the app — AuthService + onAuthStateChange + router redirect gating all agree on it consistently.
Profile Partially exists No dedicated state — ProfileCompletionService is a pure function fed different User instances by different screens, so completion% can visibly disagree screen-to-screen.
Mood Partially exists — duplicated Five independent mood-to-color systems coexist with no shared source of truth (MoodColors.glow, AuraController.colorForMood, a hand-duplicated copy in HomeHubScreen, the legacy TruLuraTheme adapter, and the actual shared kTruLuraPalettes).
Aura Exists The best-integrated system in the app — TruLuraLayeredBackground + emotionalPresenceState genuinely cascade through ~25 of 30 screens consistently.
Spark Missing No dedicated screen, service, provider, or model anywhere in lib/. The only trace is a "Sparks" notification-filter label in the (entirely demo-data) Notifications screen — orphaned terminology, likely carried over from the legacy React Native app, which does have a real SparkScreen.js.
Sync Partially exists Full matchmaking UI and a 555-line SyncService exist, but it's entirely local (SharedPreferences) with zero Supabase backing — doesn't sync across a user's own devices, let alone match real users server-side.
Vent Exists A real, isolated feed space (VentScreen, FeedDemoContentService + PostService), deliberately walled off by VisibilityService as a protected emotional space — worth a product decision on whether that isolation is permanent by design or an MVP constraint.
Companion Placeholder TruCompanionScreen is a real, well-designed surface visually, but its state is plain StatefulWidget fields with no service, provider, or persistence of any kind — a "reflection" is gone the moment you navigate away.
Notifications Placeholder 100% static demo data (\_NotificationDemo, a hardcoded const list) — no service, no provider, no Supabase table, not wired to any real event in the app.
Creator Platform Partially exists Real gating infrastructure (creatorModeEnabled/creatorOnboardingComplete/creatorApproved on AppProvider, a full TruExperienceMode.creator) unlocks a genuine 6-tab TruStudioScreen shell (Dashboard/Live Tools/Subscribers/Brand Deals/Content/Payouts) — but with zero Supabase tables for creators, subscribers, or payouts anywhere in the app, that content is necessarily placeholder once unlocked. Infrastructure built ahead of the feature.
Navigation Exists One coherent GoRouter tree with consistent auth-gating and a uniform custom transition system applied to every real route, no exceptions — see the Architecture Map §02 and the Ecosystem Cohesion Audit for the full trace.
Supabase Partially exists Real and correctly initialized, but thin — 6 tables total, no .rpc() calls anywhere, no repository layer, and entire feature areas (Chat, Sync, Notifications) never touch it at all despite reading as backend-driven features.
State Management Partially exists — inconsistent A working hand-rolled provider system, but 5 independent sibling ChangeNotifiers with no shared root, a vestigial unused Riverpod dependency wrapping the whole tree, and only 4 write paths in the entire app that reliably keep the main provider in sync after a mutation. Full detail in §05.
Verdict

Not one ecosystem yet — closer to several well-built subsystems (Aura, Navigation, Session) sitting next to several thin or disconnected ones (Spark, Notifications, Companion, Creator Platform), held together by one genuinely shared piece of infrastructure (AppProvider + emotionalPresenceState) that most of the disconnected systems don't fully plug into. The pattern repeats system after system: real, thoughtful UI and gating logic, built ahead of the backend and shared-state work needed to make it actually cohere.

02
Technical Debt Register
Every item below follows Problem / Evidence / Recommendation / Risk / Migration Strategy / Estimated Effort, per the mission brief. These are descriptions and recommendations only — nothing here has been implemented.

Incremental Architecture Rule — compliance check
Per the standing rule: never recommend a large rewrite if an incremental migration is possible. Every item below was checked against this before being written up — none require a rewrite.

Item Incremental? Path (or reason if not)
TD-01 Identity consolidation Yes New store introduced behind the existing AppProvider API first; write paths migrated one screen at a time
TD-02 Mood unification Yes Write-through fix first (small), full type merge later (larger, still additive)
TD-03 Mood-color systems Yes One call site at a time, screenshot-diffed, legacy adapter retired last
TD-04 Repository layer Yes One repository per existing table, services swapped in individually, no behavior change per step
TD-05 Chat/Sync backend Yes Repository swap behind existing service interfaces — screens shouldn't need to change; schema design is the only non-incremental prerequisite (a one-time decision, not a rewrite)
TD-06 Notifications backend Yes New build additive to the existing UI shell (filter chips, grouping stay); only the data source swaps
TD-07 Onboarding background Yes Background layer swap only, logic and layout untouched
TD-08 Persistent chrome Yes Opportunistic, screen by screen, no dependency between screens
TD-09 AuthManager decision Yes Either path (finish or deprecate) is additive/subtractive at the margin, not a rewrite
TD-10 Dead services decision Yes Same — decision-only, no code change implied either direction
TD-11 Supabase accessor Yes Find-and-replace across 2 files
TD-12 Companion persistence Yes Additive — new service/provider, existing screen wired to it, no redesign
TD-13 Session provider topology Yes New composed object introduced alongside the 5 existing providers; reads migrated screen by screen; old providers removed last, only once nothing references them
TD-14 Unused Riverpod Yes Delete the wrapper, verify via flutter analyze — trivially incremental
TD-15 Duplicate boot fetch Yes Single-file change
TD-16 OpenAI helper duplication Yes Extract-method refactor within one file
TD-17 Zero test coverage Yes Additive by nature — tests are added, nothing is removed or rewritten to add them
TD-18 Documentation gaps Yes Additive, file by file, as each is touched
TD-01
Identity has four independent, unsynced stores
Critical
Problem
The same user's identity data is cached separately in AppProvider, UserService's SharedPreferences cache, IdentityService's prefs, and IdentityProfileService's per-mode cache — with no formal relationship between them.

Evidence
Only 4 write paths in the whole app (all onboarding screens) call AppProvider.refreshCurrentUserFromSupabase() after a write; every other identity/trust/privacy edit updates UserService/IdentityService directly and leaves AppProvider.currentUser stale until the next auth event or restart.

Recommendation
Consolidate into one canonical identity object owned by a single session provider; retire the redundant caches in favor of one read-through cache layer.

Risk
High if left alone — users will see stale identity/trust state across screens as more write paths are added; low risk to fix since the correct merge logic already exists in AppProvider.\_syncCurrentUserFromSupabase.

Migration strategy
Introduce the consolidated store behind the existing AppProvider API first (no call-site changes), then migrate write paths one screen at a time to call the new refresh method, verified against the existing screen list.

Estimated effort
Medium — the merge logic exists; the work is call-site auditing (~20 write paths) plus tests to confirm no drift remains.

TD-02
Mood/emotional state exists twice, and the two disagree
Critical
Problem
emotionalPresenceState (derived on AppProvider) and AuraController.state.mood are two unrelated representations of "current mood" that never sync.

Evidence
TruCompanionScreen displays both in the same header — they can visibly contradict each other. A mood-chip tap on Home changes 4 widgets but has zero effect on the value that drives feed pacing/glow intensity app-wide.

Recommendation
Fold AuraController's mood/energy/intent into the same derivation that produces emotionalPresenceState, so there is exactly one "current mood" value.

Risk
Medium — visible user-facing inconsistency today; fixing it touches every widget that currently reads AuraController directly (6 files).

Migration strategy
Have AuraController.updateMood() write through to the field that feeds emotionalPresenceState as a first, low-risk step; fully merge the two types in a later pass.

Estimated effort
Small for the write-through fix; Medium for the full merge.

TD-03
Five competing mood-to-color systems
High
Problem
MoodColors.glow, AuraController.colorForMood, a hand-duplicated private copy in HomeHubScreen.\_gradientForMood, the legacy TruLuraTheme adapter, and the actual shared kTruLuraPalettes all map mood/mode to color independently.

Evidence
home_hub_screen.dart imports AuraController elsewhere in the same file while also maintaining its own private re-implementation of its color logic — a direct sign the shared lookup wasn't discovered or trusted by whoever wrote the duplicate.

Recommendation
Standardize on kTruLuraPalettes/TruLuraModeTone as the single mapping; delete the other four once every call site is migrated.

Risk
Low technical risk, but a visual-QA pass is needed since the four systems currently produce different colors for the same mood.

Migration strategy
Migrate one call site at a time, screenshot-diffing before/after; retire trulura_theme.dart last since onboarding is its only remaining consumer (see TD-07).

Estimated effort
Small per call site; Medium in total across ~6 files.

TD-04
No formal repository layer
High
Problem
Services mix business logic and raw Supabase query construction in the same methods — no interface separates "what data looks like" from "how it's fetched."

Evidence
Zero classes or files matching _Repository_ anywhere in lib/. UserService and PostService build .from(table) queries inline next to domain normalization logic; AppProvider embeds a ~150-line hand-written row-to-User mapper directly inside a ChangeNotifier.

Recommendation
Introduce a thin repository interface per model (e.g. UserRepository, PostRepository) that owns query construction; services call the interface and keep only business logic.

Risk
Low to introduce incrementally; the risk is entirely in scope creep if attempted all at once.

Migration strategy
Start with the 6 tables already in use (§08) — one repository each, services call through them, no behavior change. Expand the pattern to any new backend model going forward (see §09) rather than retrofitting everything at once.

Estimated effort
Medium — mechanical but touches most services.

TD-05
Chat and Sync read as backend features but have no backend
Critical
Problem
ChatService and SyncService persist entirely to per-device SharedPreferences; neither touches Supabase. Messages and matches don't survive a reinstall or sync across a user's own devices, and two different accounts on the same device would collide.

Evidence
ChatService ships hardcoded seed data (3 demo chats) in \_initSampleData(); zero .from('messages')/.from('matches')-style calls found anywhere in either service.

Recommendation
Design and stand up real Supabase tables for messages/matches before Beta if these are meant to be functional multi-user features — see §06 for the code-level backend-readiness detail.

Risk
Critical for Beta if either feature is expected to work between two real users — as built today, neither can.

Migration strategy
Schema design first (needs product input on match/message semantics), then a repository swap behind the existing service interfaces — screens shouldn't need to change.

Estimated effort
Large — new schema, new repository layer, and realtime delivery for chat specifically.

TD-06
Notifications screen is entirely fabricated
High
Problem
NotificationsScreen renders a hardcoded const List<\_NotificationDemo> — there is no notification model, service, provider, or table anywhere in the app.

Evidence
lib/screens/notifications/notifications_screen.dart, lines 61+ — every item is a compile-time constant with fixed text like "Darcell received a Glow."

Recommendation
Treat as a from-scratch build: a notifications table, a generator (server-side or triggered), a real-time or polling delivery mechanism, and a provider — this is one of the larger true gaps in the app.

Risk
Low technical risk to leave as-is short-term since it's clearly inert; high product risk if Beta users are expected to receive real notifications.

Migration strategy
New build, not a migration — keep the current UI shell (filter chips, grouping) and swap the data source once a real backend exists.

Estimated effort
Large.

TD-07
Onboarding doesn't use the shared theme/background system
Medium
Problem
All 5 onboarding screens route through TruLuraOnboardingScaffold, which paints a static TruluraTheme.cosmicGradient and hardcoded white text — the first thing every user sees ignores soft mode, emotional presence, and mode/tone entirely.

Evidence
lib/theme/trulura_theme.dart's own doc comment calls itself a legacy compatibility layer; onboarding_scaffold.dart never reads AppProvider or any mode controller.

Recommendation
Migrate the onboarding scaffold onto TruLuraLayeredBackground, matching the rest of the app.

Risk
Low technical risk; onboarding is a well-isolated flow with few screens.

Migration strategy
Swap the scaffold's background layer only, keep all onboarding logic and layout untouched, visually verify each of the 5 screens.

Estimated effort
Small.

TD-08
Persistent chrome covers 4 of ~29 routes
Medium
Problem
MainShell's persistent app bar and bottom nav only wrap the 4 shell-branch tabs; every other screen (settings, vent, quiz, sync, matchroom, onboarding — ~25 screens) rebuilds its own Scaffold and app bar from scratch.

Evidence
26 files under lib/screens/ independently construct Scaffold(, confirmed by direct grep.

Recommendation
Standardize on the already-existing but underused TruluraScreenShell widget for these screens' app-bar/back-button chrome rather than each hand-rolling its own.

Risk
Low — purely a consistency improvement, no functional change.

Migration strategy
Opportunistic — apply when a screen is touched for other reasons rather than a dedicated sweep, given the low urgency.

Estimated effort
Small per screen; Large in total across ~25 screens if done as one project.

TD-09
A fully-built auth abstraction layer is never used
Low
Problem
AuthManager/SupabaseAuthManager implement a complete multi-provider auth contract (email/anonymous/Apple/Google/JWT/phone/Facebook/Microsoft/GitHub) that nothing in the app instantiates.

Evidence
SupabaseAuthManager( constructor call: zero matches anywhere in lib/. Every real screen calls AuthService.instance directly instead.

Recommendation
Product decision needed: either finish wiring it in if multi-provider auth (Apple/Google sign-in) is on the near-term roadmap, or formally deprecate it. Left as-is per current instruction not to touch it.

Risk
Low — dead code, not a functional risk, just maintenance noise and a confusing false trail for new engineers.

Migration strategy
N/A until the product decision is made.

Estimated effort
Small to formally deprecate; Medium-Large to actually finish and wire it in.

TD-10
Two fully-built services with zero call sites
Low
Problem
TrustScoreService and QuizResultStoreService are complete, self-contained implementations that nothing imports or instantiates.

Evidence
Zero imports, zero constructor calls for either class anywhere in lib/ (confirmed independently in the Safe Cleanup audit pass).

Recommendation
Explicitly protected from changes per current instruction — flagged here only so the decision (finish integrating vs. formally deprecate) stays visible rather than silently rotting.

Risk
Low currently; rises over time as the surrounding code around them changes without them, increasing the odds they're subtly broken by the time anyone tries to wire them in.

Migration strategy
N/A until a product/architecture decision is made — no action taken.

Estimated effort
Unknown until reviewed — flagged for manual review only.

TD-11
Two inconsistent Supabase client access paths
Low
Problem
Most code uses DatabaseService.instance.client; app_provider.dart and home_feed_screen.dart call SupabaseConfig.client/.auth directly instead. Both resolve to the same singleton, so this is stylistic, not functionally broken.

Evidence
Direct import/usage grep across both files vs. the rest of lib/.

Recommendation
Standardize on DatabaseService.instance.client everywhere; retire the unused third accessor at lib/core/supabase_client.dart once the standardization is done (currently zero importers already).

Risk
Very low — purely cosmetic consistency.

Migration strategy
Two-file find-and-replace, no behavior change.

Estimated effort
Small.

TD-12
Companion state is fully ephemeral
Medium
Problem
TruCompanionScreen's reflection history and active-space state live only in plain StatefulWidget fields — no service, no provider, no persistence.

Evidence
\_holdingPresence, \_activeSpace, \_reflectionHistory declared directly on \_TruCompanionScreenState; no corresponding service file exists under lib/screens/ai/ or anywhere else.

Recommendation
Introduce a CompanionService + provider following the same local-first pattern used elsewhere (e.g. ChatService), persisting at minimum to SharedPreferences, ideally Supabase given companion history is arguably a core retention feature.

Risk
Medium — loses user trust if "reflections" visibly vanish on navigation, which is the current behavior.

Migration strategy
Additive — build the service and provider, wire the existing screen to read/write through it, no UI redesign needed.

Estimated effort
Medium.

TD-13
Five sibling providers, no shared root
High
Problem
AppProvider, AppState, AuraController, TruLuraModeController, and ExperienceModeController are independent ChangeNotifiers with no composition root; cross-provider dependencies are handled ad hoc (ExperienceModeController takes AppProvider as a constructor argument and writes back into it directly).

Evidence
main.dart's MultiProvider registers all 5 as flat siblings; full detail in §05.

Recommendation
See §05 for the full target-architecture proposal — a single composed session object replacing the 5 siblings.

Risk
High long-term — every new cross-cutting feature (Companion, Creator Platform) will need its own ad hoc composition unless this is addressed.

Migration strategy
Incremental — introduce the composed object alongside the existing providers first, migrate reads screen by screen, remove the old providers last.

Estimated effort
Large.

TD-14
An unused Riverpod dependency wraps the entire app
Low
Problem
main.dart wraps the app in a real Riverpod ProviderScope, but zero Riverpod providers or consumers exist anywhere else in lib/.

Evidence
Zero matches for @riverpod, ref.watch, or any Riverpod Provider definition across the whole codebase, despite flutter_riverpod: ^3.3.1 being a real pubspec dependency and the one import being genuine.

Recommendation
Remove the ProviderScope wrapper and the flutter_riverpod dependency, or make a deliberate decision to actually adopt it — right now it's confusing scaffolding that suggests a state-management approach the app doesn't use.

Risk
Very low to remove; purely a clarity improvement.

Migration strategy
Delete the wrapper, run flutter analyze and the app to confirm nothing depended on it (nothing should, per the evidence above).

Estimated effort
Small.

TD-15
Duplicate boot-time user fetch with different merge logic
Medium
Problem
AppProvider.initialize() fetches and richly merges the current user before runApp(); SplashScreen.\_checkAuth() independently re-fetches and overwrites it with simpler merge logic immediately after.

Evidence
Both paths call into the same three Supabase tables but through different code (AppProvider.\_syncCurrentUserFromSupabase vs. UserService.getCurrentUser + AppProvider.setCurrentUser raw overwrite) — trust/verification field handling differs between the two.

Recommendation
Remove SplashScreen's independent fetch; have it simply await/observe AppProvider's already-completed hydration instead.

Risk
Low to fix, and directly reduces the identity-drift risk described in TD-01.

Migration strategy
Single-file change to splash_screen.dart; verify cold-start timing still feels right without the second fetch.

Estimated effort
Small.

TD-16
Duplicated OpenAI request logic, no shared client
Low
Problem
TruOpenAI.suggestReplies and suggestMatchConciergeTips each hand-build the same HTTP POST/header/error-handling boilerplate independently, with no shared request helper, retry, or timeout handling.

Evidence
lib/openai/openai_config.dart — two ~50-line methods with near-identical http.post(...)/jsonDecode/error-handling blocks.

Recommendation
Extract a shared private \_chatCompletion(messages) helper; add a timeout and a defined user-facing fallback for when isConfigured is false (today it just throws).

Risk
Low — the feature is already gated behind a try/catch at call sites, so the duplication is a maintainability issue, not a live bug.

Migration strategy
Refactor within the single file, both call sites already share the same request/response shape.

Estimated effort
Small.

TD-17
Zero automated test coverage anywhere in the app
Medium
Problem
The test/ directory contains no files at all. flutter_test is a listed dev dependency but nothing uses it — every provider, service, and screen is entirely unverified by automated tests.

Evidence
find test -type f returns nothing; find test -name "\*.dart" returns zero results, confirmed directly this pass.

Recommendation
Start with characterization tests for the areas already slated for refactor — the identity merge logic in AppProvider/UserService and the router's redirect logic — before touching them, not after.

Risk
High cumulative risk — every refactor recommended in this register (TD-01 through TD-13) is currently unguarded by any regression net.

Migration strategy
Purely additive — tests are added incrementally, ideally one test file per module right before that module is refactored.

Estimated effort
Large in total to reach meaningful coverage; Small per individual test file added opportunistically.

TD-18
Uneven documentation coverage
Low
Problem
Only 78 of 163 Dart files in lib/ carry any /// doc comment — real documentation exists but is concentrated unevenly, better in newer local-first services than in widgets/screens.

Evidence
Direct repo-wide grep this pass: grep -rl "^///" lib --include="\*.dart" | wc -l → 78 of 163 total files.

Recommendation
No dedicated sweep — require a short doc comment on any file touched during the Sprint 1/2 refactors above, so coverage improves as a side effect of the work already planned.

Risk
Low — a maintainability cost, not a functional one.

Migration strategy
Additive, file by file, folded into other work.

Estimated effort
Medium in total; negligible per file.

03
Refactor Candidates
The subset of the register above worth sequencing as deliberate refactor projects, in recommended order. Descriptions only — none of this has been implemented.

Fix the boot-time double-fetch (TD-15) — smallest, safest, and removes a real drift source before building anything on top of the current identity flow.
Introduce the composed session object (TD-13, TD-01, TD-02) — the architectural centerpiece; everything else about state fragmentation is downstream of this decision. See §05 for the full proposal.
Collapse the five mood-color systems onto kTruLuraPalettes (TD-03) — best done right after the session object exists, since mood becomes part of it.
Introduce a repository layer for the 6 existing tables (TD-04) — do this before adding any new backend model (TD-05, TD-06, Creator Platform), so new work lands on the improved pattern instead of extending the old one.
Migrate onboarding onto the shared background system (TD-07) — small, high-visibility, no dependencies on the above.
Remove the unused Riverpod wrapper (TD-14) — trivial, do any time.
04
State Management Review
The app's real state mechanism is a hand-rolled InheritedNotifier-based replacement for the provider pub package (lib/compat/provider_compat.dart) — not the Riverpod dependency the app also carries (TD-14), and not the provider package itself. It works correctly for what it does: standard unidirectional flow, notifyListeners() triggers rebuilds via context.watch<T>().

The structural weakness isn't the mechanism, it's the topology: 5 independent sibling providers instead of one composition root (TD-13), which is what makes the identity/mood fragmentation (TD-01, TD-02) possible in the first place — there's no single place a screen can go to get a consistent, current view of "everything about this user right now." ExperienceModeController's pattern of taking AppProvider as a constructor dependency and writing back into it is the closest thing to composition in the codebase today, and it's a reasonable template for how the other providers could relate to a shared root — but as a one-off, ad hoc solution, not a general pattern other providers follow.

Recommended target state (elaborated fully in the Emotional Core Audit, carried into §03 above): one root AppUserSession composing identity/emotional/profile/companion/sync sub-state, with the current services demoted to pure data-access functions the session calls before updating itself and notifying once. This is a description of a target architecture only — not implemented.

05
Backend Readiness — Code-Level Cut
What's genuinely backend-supported today vs. what only looks like it is, independent of blueprint priority ranking (which needs product input — see §10).

Feature area Backend reality
Auth / Session Real Supabase Auth, fully wired
Profile / Identity Real — 3 tables (profiles, matchmaking_profiles, user_states), though see TD-01 for the client-side fragmentation on top of it
Posts / Feed Real — posts, post_reactions tables
Quiz / Compatibility Partial — writes to user_settings, but most of the quiz/compatibility engine itself is local computation
Chat / Messaging None — fully local, hardcoded seed data (TD-05)
Sync / Matchmaking None — fully local (TD-05)
Notifications None — fully fabricated demo data (TD-06)
Companion None — not even local persistence (TD-12)
Creator Platform None — gating flags exist, but no creator/subscriber/payout tables anywhere
Safety / Trust Partial, by design — local-first heuristics and scoring, explicitly documented as not yet server-verified (background checks are a placeholder pending a real third-party integration)
What this can't tell you yet

This is a structural map of what's connected, not a priority order — that requires the blueprint's product requirements to know which of these gaps actually block Beta versus which are fine to ship local-first. Full Critical/High/Medium/Low Beta-readiness ranking is held for Task 4, pending the blueprint (§10).

06
API Inventory
Every external API call in the app, in full — there are only two integration surfaces.

API Client Used by Notes
Supabase (REST + Auth) supabase_flutter SDK, via DatabaseService/SupabaseConfig ~8 files (§08) 6 tables, zero .rpc() calls, no realtime channel subscriptions found anywhere in lib/
OpenAI (via custom proxy) Raw http.post, no SDK — lib/openai/openai_config.dart trulura_ai_suggestions_sheet.dart (feed reply suggestions), matchroom_screen.dart (concierge tips) Model gpt-4o-mini, JSON-mode responses, gated behind OPENAI_PROXY_API_KEY/OPENAI_PROXY_ENDPOINT env vars — silently throws if unconfigured, no fallback UI observed at the API layer (TD-16)
07
Supabase Inventory
Table Written/read by
profiles UserService, AppProvider
matchmaking_profiles UserService, AppProvider
user_states UserService, AppProvider
posts PostService, home_feed_screen.dart
post_reactions PostService
user_settings CompatibilityService, AppSettingsService
Client init: SupabaseConfig.initialize() via DatabaseService.instance.initialize(), called once from main.dart before runApp().
Access paths: two, both resolving to the same singleton (TD-11).
Auth: AuthService wraps client.auth directly; AppProvider subscribes to onAuthStateChange for the app's lifetime.
Migrations: one file in the repo, supabase/migrations/20260411_phase_a_truth_foundation.sql, adding columns to profiles and user_settings — the only version-controlled schema history found. Whether the base tables themselves (and matchmaking_profiles, user_states, posts, post_reactions) were created via additional migrations not present in this repo, or directly in the Supabase dashboard, is unknown from the client code alone — flagged for manual review.
Realtime: no .stream()/channel-subscription usage found anywhere in lib/.
RLS / row-level security: not verifiable from client-side Dart code — flagged for manual review directly in the Supabase dashboard.
08
Missing Backend Models
Local Dart models that have no corresponding Supabase table — the concrete list behind several Technical Debt items above.

Concept Local model exists? Backend table exists?
Notification No — inline demo class only (\_NotificationDemo, private to the screen) No
Match / Sync candidate Yes — models/sync_candidate/sync_candidate.dart No
Chat / Message Yes — models/chat.dart, models/message.dart No
Companion reflection / session No No
Creator profile / subscriber / payout No No
These five gaps are the direct backend-side counterpart of TD-05, TD-06, TD-12, and the Creator Platform finding in §01 — listed here once as a data-model-specific view for quick reference.

09
Pending: Blueprint-Dependent Tasks
Still awaiting the blueprint file/link

Everything above is grounded in the code alone. Once the blueprint arrives, the next pass will produce: the full Feature-to-Code Matrix and Blueprint-to-Code Matrix (already-exists/partially-exists/placeholder/missing per blueprint system, not just per the 14 systems named in this session's mission); a fully prioritized Backend Readiness Report (Critical/High/Medium/Low against actual Beta requirements, building directly on §05); and, per your standing instruction, an explicit list of which Flutter modules documented in this review and the Architecture Map will need updates as a direct consequence of each blueprint change.

Read-only engineering review — no files were modified to produce this report, and none will be without your explicit approval. Every finding is grounded in a direct code trace. The living Engineering Backlog, seeded from every item in this register, is published as a companion document.
