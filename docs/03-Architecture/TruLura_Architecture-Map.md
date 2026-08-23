TruLura Architecture
Repository Understanding
How to read this
App entry
Navigation
Authentication
Supabase
Providers
Services
Models
Repositories
Widgets
Screens
Current data flow
Current state flow
Current backend flow
Emotional core audit
Ecosystem cohesion audit
Data model inventory
Pending: blueprint tasks
Architecture Documentation · Read-only · No code modified
TruLura Architecture Map
A complete, evidence-traced map of what the Flutter application actually is today — every layer from boot to backend, how state really moves, and whether the product feels like one emotional ecosystem or a stack of independent screens.

Scope lib/ only (~140 Dart files), post safe-cleanup
Method full import/reference tracing, 3 parallel research passes
Excludes src/ (legacy React Native), archive/flutter_legacy/
00
How to read this
This document answers Task 1 (Repository Understanding) and Task 6 (Emotional Core Audit) in full, Task 5 (Navigation Audit) in full, and the codebase-inventory half of Task 3 (Data Model Audit). Tasks 2 (Feature-to-Code Matrix) and 4 (Backend Readiness) require comparing the codebase against a product blueprint that doesn't exist in this repository — those are held open at the end of this document pending the file/link you're sending separately.

140
Dart files in lib/
6
Supabase tables touched, total
5
Sibling providers, no shared root
4
Independent identity stores
0
Formal repository classes found
2
Tasks pending the blueprint
01
App Entry
lib/main.dart — everything below runs, in order, before the first frame is ever painted.

1
Bind the engine
WidgetsFlutterBinding.ensureInitialized()

2
Boot Supabase
await DatabaseService.instance.initialize() → internally calls SupabaseConfig.initialize() → Supabase.initialize(url:, anonKey:, debug: kDebugMode). DatabaseService.client throws a StateError if touched before this completes.

3
Hydrate the session
final appProvider = AppProvider(); await appProvider.initialize(); — loads local settings, joins profiles + matchmaking_profiles + user_states for the current Supabase auth user, and subscribes to onAuthStateChange for the rest of the app's life.

4
Run the app
runApp(ProviderScope(child: MyApp(appProvider: appProvider)))

5
Assemble the tree
Inside MyApp.build: AppRouter.createRouter(appProvider:) builds the GoRouter; the tree is wrapped in a hand-rolled MultiProvider registering 5 ChangeNotifiers; theme is picked via a switch on app.appearanceMode; MaterialApp.router renders.

Finding — a dependency that does nothing

ProviderScope in step 4 is imported directly from package:flutter_riverpod (a real pubspec dependency, flutter_riverpod: ^3.3.1), and this is genuine Riverpod code. But nothing downstream ever uses Riverpod — zero @riverpod annotations, zero ref.watch, zero Riverpod Provider definitions anywhere in lib/. All real state management runs through lib/compat/provider_compat.dart instead (see §12). This wrapper executes on every boot but does nothing — vestigial scaffolding from an earlier or abandoned state-management decision.

02
Navigation
One GoRouter, built in lib/core/navigation/app_router.dart, initialLocation: '/' (splash), refreshListenable: appProvider — every AppProvider.notifyListeners() re-runs the redirect logic below.

Auth-gating logic
Legacy aliases rewritten first: /chat→/messages, /post→/create_post, /ai→/ai_companion, /login→/auth/sign_in, /signup→/auth/sign_up.
isAuthed = appProvider.currentUser != null; public routes: splash, /soft-mode, anything under /auth or /onboarding.
At splash, once appProvider.initialized: unauthed → sign-in; authed + needsOnboarding → onboarding intent; else → home.
Unauthed on a non-public route → forced to sign-in. Authed on an auth-flow route → forced forward. Authed + incomplete onboarding + not already on one of the three minimal-entry onboarding routes → forced back to onboarding intent.
needsOnboarding (defined in AppProvider) = user lacks both a persisted intent and a persisted mood tag.
Route tree by area
Area Routes
Public / pre-auth / · /soft-mode · /auth/sign_in · /auth/sign_up · (/login, /signup alias-redirects)
Onboarding /onboarding/intent · /identity · /vibe · /interests · /profile_setup · /quiz/library · /quiz/micro · /quiz
Main shell (bottom-nav tabs) /home (hosts internal Aura/Sync/Explore tabs) · /messages (+ /messages/thread/:id) · /notifications · /profile
Global / full-screen pushes /settings (+8 sub-routes) · /vent · /accessibility · /live · /trustudio · /create_post · /ai_companion · /p (placeholder) · /matchroom/:matchId
Tab-embedded vs. top-level — an important distinction

HomeHubScreen is the single route target for the Home branch. It owns its own TabController switching between Aura (HomeFeedScreen), Sync (SyncScreen), and Explore (ExploreScreen) — these are not separate GoRoutes or shell branches, just an internal tab switch inside one route (URL kept in sync via a ?tab= query param). That's structurally different from Messages/Notifications/Profile, which are true shell branches with independent navigation stacks and back-button semantics.

Every real route renders through a shared \_page() helper wrapping a CustomTransitionPage with blur/fade/scale/translate, tuned by softModeEnabled and emotionalPresenceState.silenceSpacing, plus per-route pull/dim flags for routes named sync/matchroom/vent. Confirmed applied uniformly — every non-alias route goes through it, no exceptions found.

Confirmed removed lib/nav.dart (the duplicate router archived in the Safe Cleanup pass) no longer exists in lib/; the only remaining trace is a stale doc-comment mention in lib/core/constants/constants.dart, not an import.

03
Authentication
Live The real system
lib/services/auth_service/auth_service.dart — AuthService.instance, a singleton wrapping supabase_flutter's client.auth directly: sign up, sign in, resend confirmation, sign out, password reset. Every real auth screen (sign_in_screen.dart, sign_up_screen.dart, splash_screen.dart, settings_screen.dart) calls this directly.

Present, unused The abstraction nobody wired in
lib/auth/auth_manager.dart + supabase_auth_manager.dart — a full multi-provider auth contract (email/anonymous/Apple/Google/JWT/phone/Facebook/Microsoft/GitHub mixins) with one real Supabase-backed implementation. Its constructor is called zero times anywhere in lib/.

The router doesn't talk to AuthService directly either — its redirect callback reads appProvider.currentUser, which AppProvider keeps in sync via its own onAuthStateChange subscription. So the actual chain is: screen → AuthService → Supabase session change → AppProvider resync → router redirect re-evaluates. Three layers, one real path.

04
Supabase
Init chain: main.dart → DatabaseService.instance.initialize() → SupabaseConfig.initialize() → Supabase.initialize(...). SupabaseConfig hardcodes a fallback project URL/anon key with override via String.fromEnvironment.

Two live client-access paths (same underlying client)
DatabaseService.instance.client — used by most services (UserService, PostService).
SupabaseConfig.client / .auth — called directly from app_provider.dart and home_feed_screen.dart.
Both resolve to the same Supabase.instance.client singleton — a stylistic/historical split, not two backends. A third accessor, lib/core/supabase_client.dart, is defined but never imported anywhere.

Complete Supabase table inventory
Every .from('...') call anywhere in lib/, in full — six tables, four files. Zero .rpc() calls exist anywhere.

Table Touched by
profiles UserService, AppProvider
matchmaking_profiles UserService, AppProvider
user_states UserService, AppProvider
posts PostService, home_feed_screen.dart
post_reactions PostService
user_settings CompatibilityService, AppSettingsService
Finding — chat and matchmaking aren't backed by a database at all

ChatService (221 lines) and SyncService (555 lines) — the services behind Messages and Sync/matchmaking — never call Supabase. Both are entirely local, persisting to SharedPreferences, and ChatService ships with hardcoded seed data (3 demo chats). Anyone reading the screen names would assume these are real backend features; today they're local-only demo scaffolding. This matters directly for Task 4 (Backend Readiness) once the blueprint arrives.

05
Providers
All 5 are ChangeNotifiers registered in main.dart's MultiProvider, consumed via provider_compat.dart. No shared root — they are independent siblings (see §15 for why that matters).

Provider File Holds Reads
AppProvider providers/app_provider.dart Current User?, ~30 settings fields (soft mode, creator mode/approval, feed personalization sliders, appearance, use-mode, etc.), derives needsOnboarding/emotionalPresenceState/glowScale. Owns the Supabase auth subscription. 47 files / 99 uses
AppState providers/app_state.dart Quiz completion flags + results, selectedVibe, isAnonymous, Home hub's active top tab. 7 files / 21 uses
AuraController providers/aura_state.dart Mood/energy/intent for avatar & hero-card visuals. Session-only, no persistence. 6 files / 7 uses
TruLuraModeController providers/trulura_mode_controller.dart Current TruLuraMode → palette (background/glow/card/border/text). Deliberately decoupled from AppProvider. 6 files / 7 uses
ExperienceModeController providers/experience_mode_controller.dart 8 TruExperienceModes, lock/permission logic, mutual-exclusion rules. Takes AppProvider as a constructor dependency and writes back into it. 5 files / 9 uses
06
Services
30 files. Every one below is local-first (SharedPreferences) unless explicitly marked Supabase — most docstrings literally describe a future backend migration that hasn't happened yet.

Auth & bootstrap
auth_service/auth_service.dart Supabase · database_service/database_service.dart Supabase bootstrap singleton

Identity / profile / user data
user_service.dart Supabase — main CRUD for profiles/matchmaking/mood, SharedPreferences fallback cache · identity_service.dart Local · identity_profile_service.dart Local · profile_completion_service.dart Pure computation, no storage · app_settings_service.dart Local, backs most of AppProvider

Social graph / posts / feed
post_service.dart Supabase · connection_service.dart Local placeholder for future follow/spark/block tables · visibility_service.dart Pure policy engine · feed_behavior_service.dart Local · feed_demo_content_service.dart Content synthesis, no storage · feed_distribution_engine.dart Ranking algorithm · emotional_governance_service.dart Pacing computation

Chat / messaging local-only, no backend
chat_service.dart — local CRUD, hardcoded seed data · messaging_service/messaging_service.dart — one-line barrel re-exporting it · chat_thread_prefs_service.dart Local · communication_safety_service.dart In-memory filtering/rate-limiting

Quiz / compatibility
quiz_engine.dart — content structure definitions · quiz_registry_service.dart — static in-memory registry · quiz_result_store_service.dart Local · deep_quiz_archive_service.dart Local · compatibility_service.dart Local + Supabase (writes user_settings)

Safety / trust / compliance all local-first by explicit design — numeric scores never surfaced in UI
safety_center_service.dart · safety_meter_service.dart · safety_monitoring_service.dart (on-device regex heuristics) · trust_score_service.dart · trust_signal_service.dart · aura_shield_service.dart · background_verification_service.dart (placeholder for 3rd-party integration) · reporting_service.dart · compliance_service.dart · experience_mode_service.dart

07
Models
Model Core shape
models/user.dart User — profile fields + a full identity/trust subsystem (active mode, anonymous overlay, vibe label, verification level, trust score, risk level) + privacy fields
models/post.dart Post + TruPostContentType enum, mode-compatibility list, sensitivity intensity field
models/message.dart Message — chatId/senderId/content/timestamp/isRead/expiresAt
models/chat.dart Chat — participants, last message, status
models/feed_item.dart TruFeedPostType enum + classifier from a Post
models/emotional_presence_state.dart TruEmotionalPresenceState — ~13 doubles (motion/glow/intensity/warmth/etc.) driving app-wide feel
models/conversation/conversation.dart Intentional shim — documented forward-compat re-export of chat.dart during a naming migration, not dead code
models/experience/experience_mode.dart TruExperienceMode enum (8 modes) + participation/permission types
models/identity/identity_profile.dart TruIdentityProfile — per-mode display identity
models/profile/compatibility_report.dart TruAttractionMap, TruCompatibilityDimension
models/profile/quiz_result.dart TruQuizResult — trait scores, discovery signals, ledger state
models/quiz/quiz_registry_models.dart Shared quiz enum vocabulary
models/sync_candidate/sync_candidate.dart TruMatchPurpose, TruSyncBoundaries
Confirmed removed the three duplicate re-export shims (models/user/, models/post/, models/message/) from the Safe Cleanup pass no longer exist.

08
Repositories
No formal repository layer exists

Searching all of lib/ for any class or file matching _Repository_ returns zero results. The ~30 services perform double duty as business logic and data access — UserService and PostService mix domain normalization directly with raw .from(table) query construction in the same methods; AppProvider embeds a ~150-line hand-written Supabase-row-to-User normalization routine directly inside a ChangeNotifier. There's no interface boundary between "what data looks like" and "how it's fetched" — several service docstrings anticipate swapping backends later, but as written that would mean editing query code inline inside each service rather than substituting an implementation behind an interface.

09
Widgets
50 files in lib/widgets/, catalogued by purpose (dead/alive status already covered by the prior Safe Cleanup audit — this is a functional map, not a repeat of that classification).

Cluster Representative files
Layout / shell trulura_screen_shell, trulura_layered_background, trulura_glass_app_bar, trulura_side_drawer, trulura_bottom_nav, trulura_screen_state, trulura_world_layers
Feed / content cards feed_card, trulura_feed_components, trulura_feed_item_renderer, trulura_boosted_post_card, trulura_vent_card, trulura_event_carousel_row, trulura_skeleton_card, trulura_post_composer
Profile trulura_profile_hero_card, trulura_profile_tab_bar, trulura_profile_preview_sheet, trulura_explore_profile_card, trulura_companion_mode_card
Chat trulura_conversation_tile, trulura_message_bubble
Safety trulura_safety_meter_pill, trulura_status_badge
Buttons / chips / pills trulura_primary_button, trulura_secondary_buttons, tru_toggle, tag_pill, top_mode_pill, trulura_glow_pill, trulura_orb_chip, trulura_pill_chip, trulura_segmented_pill, trulura_reaction_button, trulura_compatibility_badge, trulura_search_field, mode_switch_row, post_orb_button
Background / ambient aura_background, breathing_glow, trulura_halo_avatar, trulura_safe_avatar, aura_avatar, trulura_brand_logo, trulura_cinematic_components, trulura_icon (custom glyph kit, no Material Icons), trulura_glass_card, trulura_empty_state_card
Sync-specific sync_hero_card, sync_preview_panel
AI / misc trulura_ai_suggestions_sheet — the only widget wired to an LLM feature (calls TruOpenAI)
10
Screens
Area Screens & what they do
Auth sign_in_screen.dart, sign_up_screen.dart — direct AuthService calls, structured error handling for confirmation/credential failures
Onboarding onboarding_scaffold (shared layout) → intent → vibe → interests → identity_setup → profile_setup (incl. photo picker)
Home / feed home_hub_screen.dart — tabbed container; home_feed_screen.dart — the Aura feed itself, ranks via FeedDistributionEngine, filters via VisibilityService, layers in Aura Shield/Safety/Compatibility/Profile-completion/Quiz signals
Explore / Sync explore_screen.dart — discovery grid; sync_screen.dart & matchroom_screen.dart — matchmaking UI, entirely local-service-backed (no Supabase)
Chat chat_list_screen.dart, chat_thread_screen.dart — safety-layered thread view (Communication Safety, Aura Shield, Safety Monitoring, thread prefs)
Profile profile_screen.dart — the user's own tabbed profile
Settings root menu, experience modes, privacy, identity core, safety verification, safety center, blocked users, report, feed personalization, help/support, about (10 screens)
Accessibility accessibility_screen.dart — motion/soft-mode toggles
Quiz quiz_library_screen.dart, micro_quiz_screen.dart, quiz_screen.dart
Misc feature screens vent_screen.dart, live_hub_screen.dart (placeholder-style), trustudio_screen.dart (creator-tools placeholder), ai_companion_screen.dart (class TruCompanionScreen — file/class name mismatch), create_post_screen.dart, notifications_screen.dart, placeholder_screen.dart (generic "coming soon," reused across several unbuilt destinations), soft_mode_gate_screen.dart
Boot splash_screen.dart — its own auth check independent of (but consistent with) the router's redirect logic; main_shell.dart — the shell body (app bar, drawer, bottom nav, mode-driven background transition)
11
Current Data Flow
Traced end to end for four representative paths, with exact file:line evidence.

Boot-time profile hydration
1
AppProvider.initialize() reads SupabaseConfig.auth.currentUser.

2
Three parallel Supabase reads (Future.wait): profiles, matchmaking_profiles (intent/preferences), user_states (mood_tag).

3
All three rows plus auth metadata plus a UserService().getCurrentUser() cache fallback are merged into a normalized map, then built into a User and stored in AppProvider.\_currentUser.

4
Any widget calling context.watch<AppProvider>() rebuilds on change — e.g. the router's own auth gate, HomeHubScreen, TruCompanionScreen.

Feed load — local widget state, not a provider
PostService.getAllPosts() queries posts directly, with a local-cache fallback if Supabase isn't ready. HomeFeedScreen stores the result in a plain List<Post> \_posts field via setState — no provider holds it, so no other screen can see it without re-fetching.

Finding — the same user gets fetched and merged twice, with different logic

SplashScreen.\_checkAuth() independently calls UserService().getCurrentUser() and then app.setCurrentUser(user) — a second, separately-coded fetch-and-merge of the same three tables, whose result does a raw overwrite of AppProvider.\_currentUser, bypassing the richer normalization logic that ran during boot in step 3 above. Both paths write the same field via different merge rules — a real source of subtle data drift (e.g. trust/verification fields are handled differently between the two).

12
Current State Flow
lib/compat/provider_compat.dart is a hand-rolled replacement for the provider pub package, built on InheritedNotifier: ChangeNotifierProvider, MultiProvider, Consumer<T>, and context extensions .watch<T>()/.read<T>(). Standard unidirectional flow within any one provider: a mutator method changes a private field, calls notifyListeners(), the InheritedNotifier marks watchers dirty, they rebuild.

Finding — writes routinely bypass the provider they should update

Only 4 call sites in the entire app ever call AppProvider.refreshCurrentUserFromSupabase() after writing a change — all four are onboarding screens. Every other write path that touches identity, trust, or privacy (identity_service.dart, trust_score_service.dart, safety_verification_screen.dart, identity_core_screen.dart) calls UserService().saveUser() directly and never refreshes AppProvider — meaning any screen reading context.watch<AppProvider>().currentUser shows stale data after most identity edits, until the next Supabase auth event or app restart.

Concrete direct-mutation examples that bypass shared state entirely: SyncScreen.\_lowEnergy (a private field, separate from AppProvider.isLowEnergyContext), and tapping a mood chip on Home calls AuraController.updateMood() — a wholly separate, unpersisted mood representation that never touches AppProvider.currentUser.moodTags (the field emotionalPresenceState actually derives from).

13
Current Backend Flow
Full boot path: main.dart → DatabaseService.initialize() (awaited) → SupabaseConfig.initialize() (awaited) → AppProvider().initialize() (awaited — runs its own Supabase reads and subscribes to auth changes) → only then runApp(). So the first frame never renders before appProvider.initialized == true, and the router explicitly gates on that flag.

No dangerous race was found by design — but there is real redundant work: the user is fetched and merged once before runApp(), then SplashScreen (the actual initial route) does a second, independently-timed (3s timeout) re-fetch and overwrite on top, using simpler merge logic (see §11's callout). Two sources of truth momentarily exist for the same field during every cold start.

14
Emotional Core Audit
Where user identity, emotional state, profile state, companion state, and sync state actually live — and whether they share one source of truth.

State Where it actually lives Status
User identity Four independent stores: AppProvider._currentUser (in-memory); UserService's own SharedPreferences cache (current_user key) with its own independent merge logic; IdentityService's TruIdentityPrefs (identity_prefs_v1) duplicating fields also on User; IdentityProfileService's per-mode profile cache (identity_profiles_v1_<userId>) Fragmented
Emotional state Two unrelated systems: emotionalPresenceState (a pure derivation on AppProvider, from soft-mode/low-energy/mood-tags) vs. AuraController.state (a separate ChangeNotifier, mutated only by direct mood-chip taps, never persisted, never written back to AppProvider) Fragmented
Profile state No dedicated store — ProfileCompletionService.summarize(User?) is a stateless pure function, but different screens pass it different User instances (some from local UserService fetches, some from AppProvider), so completion % can visibly disagree screen-to-screen if the two copies have drifted Derived, inconsistently sourced
Companion state (TruCompanion) Fully local, ephemeral StatefulWidget fields on TruCompanionScreen — no service, no provider, no Supabase table. Lost on navigation away or hot restart. It only reads shared state (AppProvider + AuraController) for display context Not persisted
Sync state SyncService — persists everything (preferences, daily suggestions, active matches, signals, matchrooms) to per-user SharedPreferences keys, instantiated independently in three separate screens with no shared provider. No Supabase table backs sync/match state at all — entirely device-local, doesn't sync across devices for the same account Fragmented, device-local
Central finding — no, these systems do not share one source of truth

Where sharing does happen, it's real and works: ExperienceModeController explicitly composes AppProvider in its constructor and reads/writes it directly; EmotionalGovernanceService takes AppProvider as an input. But that's a subset of fields (settings/toggles/creator flags) — not identity, mood, profile, companion, or sync as a whole. The clearest concrete symptom: TruCompanionScreen displays both app.emotionalPresenceState.label and AuraController.state.mood side by side in the same header — and they can visibly contradict each other, because nothing keeps them in sync. A mood chip tap changes what four widgets show (Home, TruCompanion, Sync cards, avatar) but has zero effect on the emotionalPresenceState that governs feed pacing and glow intensity everywhere else.

What architecture would actually fix this
Description only — nothing below has been implemented. Replace the five independent sibling providers with one composed session object, e.g. AppUserSession, owned by a single root ChangeNotifier:

Composition over parallel siblings: sub-objects for IdentityState (the one canonical User, replacing all four current identity stores), EmotionalState (merging emotionalPresenceState's derivation and AuraController's mood/energy into one value, so there is only ever one "current mood"), ProfileCompletionState (derived, never cached separately), CompanionState (persisted, currently absent entirely), SyncState (promoted to session scope, ideally backed by Supabase instead of device-only storage).
Services become pure data-access functions: UserService, IdentityService, IdentityProfileService, CompatibilityService, SyncService stop maintaining their own caches and instead become stateless read/write functions that the one session provider calls before updating itself and notifying once.
Single write path with mandatory refresh: every mutation goes through a method on AppUserSession that persists via the right service and updates in-memory state before notifying — eliminating the "only 4 of many write paths remember to refresh the provider" problem documented in §12.
Screens stop keeping local copies: ProfileScreen, IdentityCoreScreen, and similar screens read the session provider instead of independently calling UserService().getCurrentUser() into local StatefulWidget fields.
15
Ecosystem Cohesion Audit
Does the app behave as one emotional ecosystem, or as independent screens? Sampled 13+ screens across 8 feature areas.

Verdict — partially, and the fracture sits exactly where new users land

Genuinely cohesive at the infrastructure layer: TruLuraLayeredBackground is used directly by 25 of ~30 top-level screens and reads live emotional-presence/mood/tone state; the custom blur/scale/dim page transition applies to every real route with no exceptions; AppProvider.emotionalPresenceState is a well-designed single source that cascades consistently through a dozen paint layers wherever it's wired in; MainShell (the 4 core tabs) is a strong, deliberate "one shell, reactive ambient overlay" execution. But the persistent shell only covers 4 of ~29 routes — every settings/vent/quiz/sync/onboarding/matchroom screen rebuilds its own Scaffold from scratch — and the entire onboarding flow, the first thing every user sees, runs on a separate static, non-reactive gradient scaffold that ignores every shared mood/mode provider entirely.

Five competing mood-to-color systems, with no single source of truth
MoodColors.glow(String mood) — flat hardcoded Colors.\* map, used in feed_card.dart, trulura_event_carousel_row.dart, home_feed_screen.dart
AuraController.colorForMood(Mood) — a different enum, different colors
HomeHubScreen.\_gradientForMood(Mood) — a local, private duplicate of the line above, hand-rewritten with different gradients, inside a screen that also imports AuraController elsewhere
TruLuraTheme/TruluraTheme (theme/trulura_theme.dart) — a third color adapter, its own doc comment calling itself a legacy compatibility layer, hardcoding white text and a static gradient, bypassing the shared palette system entirely
kTruLuraPalettes — the actual shared, mode-driven palette system, underused relative to the four above
Local state shadowing shared state
SyncScreen.\_lowEnergy and ProfileScreen.\_auraStrength (a hardcoded local field, unrelated to AuraController despite sitting one tab away from Home, which does use it) are both concrete cases of a screen inventing its own copy of a concept that already exists in shared state, with no sync back.

Recommendations (description only — not implemented)
Migrate onboarding off TruLuraOnboardingScaffold/TruluraTheme.cosmicGradient onto TruLuraLayeredBackground so the first screens a user sees are reactive like the rest of the app.
Collapse the five mood-color systems into one — retire MoodColors.glow and HomeHubScreen.\_gradientForMood, route everything through kTruLuraPalettes, and retire the trulura_theme.dart compatibility shim once onboarding no longer needs it.
Extend persistent chrome (or standardize a single reusable app-bar/back-button component — TruluraScreenShell already exists and is underused) beyond the 4 shell tabs.
Sync local "low energy"/"aura" screen state into the shared providers, or explicitly namespace them as domain-only so they don't read as accidental duplicates.
Unify the three parallel "mode" enums (TruLuraMode, TruExperienceMode, AuraState.Mood) conceptually, so switching one actually retints the others.
16
Data Model Inventory
The full current-state inventory requested in Task 3 — every model, provider, service, table, state object, and the relationships between them, as they exist today. The blueprint-comparison half of this task (missing/future/recommended models) is held for §17.

Category Count Where catalogued
Models 13 §07
Providers (state objects) 5 §05
Repositories 0 — none exist §08
Services 30 §06
Supabase tables 6 §04
Additional local-only state stores (SharedPreferences) 7+ §14 — UserService cache, IdentityService prefs, IdentityProfileService cache, SyncService (5 separate keys), ChatService, CompatibilityService quiz cache, AppSettingsService
Relationships worth flagging now (independent of the blueprint)
Duplicate models: none currently. The three re-export shims found in the earlier repository audit (models/user/, models/post/, models/message/) were removed in the Safe Cleanup pass. models/conversation/conversation.dart looks similar but is a documented, intentional migration shim — not a duplicate.
Unused services (confirmed, carried over from the prior audit, deliberately untouched per your explicit protection list): TrustScoreService and QuizResultStoreService — both fully built, zero call sites anywhere.
A relationship gap, not a missing model: User carries identity/trust/mood fields that are also independently duplicated in TruIdentityPrefs (IdentityService) and AuraController.state (mood only) — three representations of overlapping concepts with no formal relationship between them (see §14).
Services acting as repositories (no formal Repository layer — §08) means every "relationship" between a model and its backing table is implicit and scattered inside whichever service happens to query it, rather than declared once.
17
Pending: Blueprint-Dependent Tasks
Awaiting input

Task 2 (Feature-to-Code Matrix) and Task 4 (Backend Readiness) both require comparing what exists (documented above) against the intended product scope. You said you'd point me to the blueprint file/link — once that's shared, I'll build:

The Blueprint System / Exists / Partial / Missing / Notes matrix for Aura, Sync, Vent, and every other blueprint system, grounded in the concrete evidence already gathered above (e.g. Sync and Chat are now known to be 100% local-only with zero backend — that alone will materially shape the Sync/Messages rows).
The Beta backend-readiness gap list, grouped Critical/High/Medium/Low — the table inventory in §04, the "no repository layer" finding in §08, and the fragmented state findings in §14 are all direct inputs to that prioritization.
Also carried into Task 3 once the blueprint lands: missing models, future models, and recommended additions (duplicate/unused models are already answered above, independent of the blueprint).
Read-only architecture documentation — no files were modified to produce this report. Every finding above is grounded in a direct code trace, cited by file and, where useful, line number, so it can be verified independently before any decision is made from it.
