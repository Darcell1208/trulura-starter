# TruLura UI Inventory

*Every screen, modal, drawer, overlay, onboarding step, settings page, wizard, and dashboard found in the current Flutter repository (`lib/`), cross-referenced to the Blueprint section it most closely implements. This is a repository audit, not a Blueprint reading exercise — it lists what exists in code today, and notes where no Blueprint section clearly corresponds. Archived/dead screens (`archive/flutter_legacy/`, per the Safe Cleanup pass) are excluded from the live count and listed separately at the end for completeness.*

## Screens

| Screen | File | Blueprint cross-reference |
|---|---|---|
| Splash | `screens/splash_screen.dart` | Not Yet Defined — no Blueprint section addresses a boot/splash screen |
| Soft Mode Gate | `screens/pre_auth/soft_mode_gate_screen.dart` | Section 10.10.3 (Emotional UI Adaptation, Low Energy Mode) — closest match, not exact |
| Sign In | `features/auth/sign_in_screen.dart` | Section 1 (Identity & Trust) |
| Sign Up | `features/auth/sign_up_screen.dart` | Section 1 (Identity & Trust) |
| Onboarding: Intent | `features/onboarding/onboarding_intent_screen.dart` | Section 25 (UX Journey), Section 1.1.1 (identity intent) |
| Onboarding: Identity Setup | `features/onboarding/onboarding_identity_setup_screen.dart` | Section 1.1 (Identity Core) |
| Onboarding: Vibe | `features/onboarding/onboarding_vibe_screen.dart` | Section 1.1.5 (Atmosphere Identity) |
| Onboarding: Interests | `features/onboarding/onboarding_interests_screen.dart` | Section 1.1.2 (Emotional Identity Infrastructure) |
| Onboarding: Profile Setup | `features/onboarding/profile_setup_screen.dart` | Section 5 (Profile System) |
| Main Shell (bottom-nav host) | `screens/main_shell.dart` | Section 10.9 (Navigation Architecture) — see `TruLura_Blueprint-to-Code-Matrix.md` §02 for the PD-14 comparison |
| Home Hub (tab container: Aura/Sync/Explore) | `screens/home/home_hub_screen.dart` | Section 10.11.1 (Multi-Feed Switching) |
| Home Feed ("Aura" tab) | `screens/home/home_feed_screen.dart` | Section 4 (Discovery/Aura) |
| Sync ("Sync" tab) | `screens/sync/sync_screen.dart` | Section 6 (Matchmaking/Spark) — naming conflict per PD-08 |
| Explore ("Explore" tab) | `screens/explore/explore_screen.dart` | Section 4 (Discovery), Section 19.11+ (Community/Social Ecosystem) |
| Matchroom | `screens/sync/matchroom_screen.dart` | Section 6 (post-match experience) |
| Chat List | `screens/chat/chat_list_screen.dart` | No owning Blueprint section — see Domain Model, "Messaging" entry |
| Chat Thread | `screens/chat/chat_thread_screen.dart` | No owning Blueprint section (Section 6's Communication Permission Logic is the closest sub-feature) |
| Profile | `screens/profile/profile_screen.dart` | Section 5 (Profile System) |
| Notifications | `screens/notifications/notifications_screen.dart` | Section 10.13 (Notification System) |
| Vent Space | `screens/vent/vent_screen.dart` | Section 14 (Vent Space) |
| Create Post | `screens/post/create_post_screen.dart` | Section 4 (Discovery/Feed, content input) |
| TruCompanion | `screens/ai/ai_companion_screen.dart` (class `TruCompanionScreen`, file/class name mismatch) | Section 15 (AI Companion) |
| TruStudio | `screens/trustudio/trustudio_screen.dart` | Section 13 (Creator Platform/TruStudio) |
| Live Hub | `screens/live/live_hub_screen.dart` | Not Yet Defined — no Blueprint section names a Live/streaming system distinctly; "Events / Live Hub" appears once as a side-menu label (§10.9.2) with no further specification found |
| Placeholder ("coming soon") | `screens/placeholder/placeholder_screen.dart` | N/A — generic stand-in used for multiple unbuilt destinations |
| Micro Quiz | `screens/quiz/micro_quiz_screen.dart` | Not Yet Defined — no quiz-specific Blueprint section found in the ranges reviewed for this document |
| Quiz Library | `screens/quiz/quiz_library_screen.dart` | Not Yet Defined |
| Quiz (full) | `screens/quiz/quiz_screen.dart` | Not Yet Defined |
| Accessibility | `screens/accessibility/accessibility_screen.dart` | Section 20.19 (Accessibility modes) |

## Settings Pages

| Screen | File | Blueprint cross-reference |
|---|---|---|
| Settings root | `screens/settings/settings_screen.dart` | N/A — navigation hub |
| Experience Modes | `screens/settings/experience_modes_screen.dart` | Section 2/3 (Experience Modes) |
| Privacy Settings | `screens/settings/privacy_settings_screen.dart` | Section 1.1.1 (visibility/identity elevation), Section 22 (Security/Privacy) |
| Identity Core | `screens/settings/identity_core_screen.dart` | Section 1.1 (Identity Core) |
| Safety Verification | `screens/settings/safety_verification_screen.dart` | Section 1.2 (Verification Layers) |
| Safety Center | `screens/settings/safety_center_screen.dart` | Section 9 (Safety, Trust, Privacy & Compliance) |
| Blocked Users | `screens/settings/blocked_users_screen.dart` | Section 9 (Moderation) |
| Report | `screens/settings/report_screen.dart` | Section 9 (Moderation), Section 24 (Governance enforcement) |
| Feed Personalization | `screens/settings/feed_personalization_screen.dart` | Section 4 (Discovery/Feed) |
| Help & Support | `screens/settings/help_support_screen.dart` | N/A |
| About TruLura | `screens/settings/about_trulura_screen.dart` | N/A |

## Modals & Bottom Sheets

*All confirmed via `showModalBottomSheet` call sites — every one found in `lib/`. No `showDialog`/`AlertDialog` usage was found anywhere in the repository; every modal surface uses a bottom sheet.*

| Modal | Defined in | Opened from | Blueprint cross-reference |
|---|---|---|---|
| Profile Preview Sheet (reusable) | `widgets/trulura_profile_preview_sheet.dart` | Sync, Explore, Sync's own local preview | Section 5 (Profile) |
| AI Reply Suggestions Sheet | `widgets/trulura_ai_suggestions_sheet.dart` | Feed Card | Section 11 (AI Intelligence) |
| "Why am I seeing this" info sheet | `widgets/feed_card.dart` | Feed Card | Section 4 (Discovery/Feed ranking transparency) |
| Reactions picker sheet | `widgets/feed_card.dart` | Feed Card | Section 4 |
| Post options sheet | `widgets/feed_card.dart` | Feed Card | Section 4 |
| Sync filters sheet | `screens/sync/sync_screen.dart` | Sync screen | Section 6 |
| Curated preview sheet | `screens/sync/sync_screen.dart` | Sync screen | Section 6 |
| Compatibility sheet | `screens/sync/sync_screen.dart` | Sync screen | Section 6 (Attraction Mapping, via Section 5.1's Compatibility Layer) |
| Profile preview (local variant) | `screens/sync/sync_screen.dart` | Sync screen | Section 5 |
| Dismiss-prompt confirmation sheet | `screens/home/home_hub_screen.dart` | Home Hub | Not Yet Defined |
| Profile preview | `screens/explore/explore_screen.dart` | Explore screen | Section 5 |
| Confirm-send sheet | `screens/chat/chat_thread_screen.dart` | Chat Thread | Not Yet Defined |
| Match/profile context sheet | `screens/chat/chat_thread_screen.dart` | Chat Thread | Section 5 / Section 6 |
| Attachments sheet | `screens/chat/chat_thread_screen.dart` | Chat Thread | Not Yet Defined |
| Bubble reactions sheet | `screens/chat/chat_thread_screen.dart` | Chat Thread | Not Yet Defined |
| Ephemeral message TTL picker | `screens/chat/chat_thread_screen.dart` | Chat Thread | Section 22 (Security/Privacy, message retention) |
| AuraShield details sheet | `screens/chat/chat_thread_screen.dart` | Chat Thread | Section 9 (Safety, behavioral trust — AuraShield) |
| Crisis support sheet | `screens/chat/chat_thread_screen.dart` | Chat Thread | Section 9/14/15 crisis-detection language — **blocked on PD-12**, see Domain Model |
| Persona lock info sheet | `screens/settings/identity_core_screen.dart` | Identity Core | Section 1.1.4 (Multi-State Identity) |
| Edit handle/bio sheet | `screens/settings/identity_core_screen.dart` | Identity Core | Section 5.1 (Profile — About Me, Basics) |
| Mode terms/consent confirmation sheet | `screens/settings/experience_modes_screen.dart` | Experience Modes | Section 2/3 |
| Mode transition confirmation sheet | `screens/settings/experience_modes_screen.dart` | Experience Modes | Section 1.1.1 (state transition eligibility checks) |
| Mode info sheet | `screens/settings/experience_modes_screen.dart` | Experience Modes | Section 2/3 |

## Drawer

| Drawer | File | Opened from | Blueprint cross-reference |
|---|---|---|---|
| Side Drawer (secondary navigation) | `widgets/trulura_side_drawer.dart` | `MainShell` (`openDrawer()`), `TruCompanionScreen` | Section 10.9.2 (Secondary Navigation / Side Menu) |

## Wizards

No multi-step wizard flow was found outside onboarding. Onboarding itself (`features/onboarding/*`) is the closest match to a wizard — a fixed 5-screen sequence (Intent → Identity Setup → Vibe → Interests → Profile Setup), each a standalone screen rather than steps of one wizard widget.

## Dashboards

| Dashboard | File | Blueprint cross-reference |
|---|---|---|
| TruStudio (Creator Dashboard) | `screens/trustudio/trustudio_screen.dart` | Section 13.3 (TruStudio Creator Dashboard System) — 6 tabs: Dashboard, Live Tools, Subscribers, Brand Deals, Content, Payouts |

No other dashboard-pattern screen (admin, moderation, or analytics dashboard) exists in the repository — consistent with the Domain Model's finding that Governance (§24) is likely a separate application, and that Analytics has no Blueprint section at all.

## Overlays (Non-Modal)

| Overlay | File | Note |
|---|---|---|
| Environmental Shift Overlay | `screens/main_shell.dart` (`_EnvironmentalShiftOverlay`) | Cross-fades ambient tint on tab switches — an animation overlay, not a modal or dialog |
| Layered Background system | `widgets/trulura_layered_background.dart` | Ambient rendering layer beneath content, present on ~25 of ~30 screens per the Architecture Map |

## Archived / Dead (Excluded From Live Counts, Listed for Completeness)

Per the Safe Cleanup pass (`archive/flutter_legacy/`), these are no longer part of the live app and are not counted above: `router/nav.dart` (duplicate router), `onboarding_v1/` (5 duplicate onboarding screens), `auth_v1/` (duplicate login/signup screens).

## Not Yet Defined

Whether Chat, Notifications, Quiz, and Live Hub are meant to have dedicated Blueprint sections at all, versus being sub-features of sections already covering them, is unresolved — see the Domain Model's "Messaging" and "Analytics" entries for the same pattern applied to those specific cases. This document does not assign them a Blueprint owner where none was found in the sections reviewed so far.

## Cross-References

`docs/03-Architecture/TruLura_Architecture-Map.md` §10 (Screens) · `docs/03-Architecture/TruLura_Domain_Model.md` (Cluster 5, Messaging/Notifications) · `docs/03-Architecture/TruLura_Blueprint-to-Code-Matrix.md` (per-section code status) · `docs/02-Product/TruLura_Blueprint.md.md`.
