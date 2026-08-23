# TruLura Repository Impact Notes

*Per the Blueprint Synchronization rule: whenever the blueprint introduces a new canonical decision, this document records affected Flutter modules, Supabase tables, providers, services, models, and migration strategy. This is the first real population of this document — the Product Knowledge System has now landed, and the Blueprint-to-Code Matrix (`docs/03-Architecture/TruLura_Blueprint-to-Code-Matrix.md`) is the source for everything below. Entries are grouped by what's blocking implementation, not by Blueprint section order.*

## Blocked on a Product Decision — No Engineering Work Should Guess These

| Product Decision | What it will affect once resolved |
|---|---|
| **PD-14** (Navigation contradiction, §10 vs. §20) | `core/navigation/app_router.dart`, `screens/main_shell.dart`, `screens/home/home_hub_screen.dart` — the entire shell structure. See ADR-003. |
| **PD-12** (Crisis detection mechanism, §9/§14/§15) | `services/safety_monitoring_service.dart`, `services/aura_shield_service.dart`, and any future Vent/Companion safety layer — no module should implement crisis-detection logic until this resolves. |
| **PD-01 / PD-15** (Trust/verification tier naming, §1/§2/§9/§16) | `models/user.dart` (verification/trust fields), `services/trust_score_service.dart`, `services/trust_signal_service.dart`, `services/identity_service.dart` — the tier model these fields assume is not yet settled. |
| **PD-19** (Payment/verification vendor selection, §21) | `openai/openai_config.dart`-style new integration module (none exists yet for payments); `services/background_verification_service.dart` (currently an explicit placeholder). |
| **PD-20** (Data retention periods, §22) | Any service holding user-generated data long-term, most acutely `services/identity_profile_service.dart` and any future Companion-memory module (see PD-11 below). |
| **PD-11** (proposed: Companion baseline vs. memory split, §15) | `screens/ai/ai_companion_screen.dart` — determines whether ENG-009 (persistence) is Beta-scoped work or Phase 2. |
| **PD-08** (Sync vs. Spark naming, §6/§10) | `screens/sync/*`, `services/sync_service/sync_service.dart` — cosmetic if resolved either way, but should be resolved before public-facing copy is finalized. |

## Ready to Proceed — No Product Decision Blocking, Not Yet Started

| Item | Affected Flutter modules | Affected Supabase tables | Affected providers/services |
|---|---|---|---|
| ENG-001 (Identity consolidation) | `providers/app_provider.dart`, `services/user_service.dart`, `services/identity_service.dart`, `services/identity_profile_service.dart`, ~20 write-path call sites | `profiles`, `matchmaking_profiles`, `user_states` (no schema change required — this is a client-side consolidation) | All 4 current identity stores collapse toward one |
| ENG-003 (MoodSync unification) | `providers/app_provider.dart`, `providers/aura_state.dart`, `screens/ai/ai_companion_screen.dart`, `screens/home/home_hub_screen.dart` | None | `AppProvider.emotionalPresenceState`, `AuraController` |
| ENG-005 (Repository layer) | New `repositories/*.dart`; `services/user_service.dart`, `services/post_service.dart` become thinner | `profiles`, `matchmaking_profiles`, `user_states`, `posts`, `post_reactions`, `user_settings` (all 6 existing tables) | Every service currently doing raw `.from(table)` calls |
| ENG-015 (Supabase accessor standardization) | `providers/app_provider.dart`, `screens/home/home_feed_screen.dart`, `core/supabase_client.dart` (retired) | None | `DatabaseService`, `SupabaseConfig` |

## Ready to Proceed, but Requires New Backend (Schema Not Yet Defined)

| Item | New models needed | New tables needed | Migration strategy |
|---|---|---|---|
| ENG-002 (Chat/Sync backend) | `models/chat.dart`, `models/message.dart` already exist locally; `models/sync_candidate/sync_candidate.dart` already exists locally — none has a Supabase counterpart | **Not Yet Defined** — schema depends on Product input on match/message semantics (PD-06) | Repository swap behind existing `ChatService`/`SyncService` interfaces once schema exists — screens should not need to change |
| ENG-006 (Notifications backend) | No local model exists yet (`_NotificationDemo` is a private, inline class) | **Not Yet Defined** | New build, not a migration — existing UI shell (filter chips, grouping) is reused |
| ENG-013 (Creator Platform, early-monetization slice) | No local model exists yet | **Not Yet Defined** — blocked on PD-01 (tier naming) before scoping | Additive — `TruStudioScreen`'s existing gating flags and 6-tab shell stay, only the data layer is new |

## Not Yet Defined

Exact field-level schemas for any table listed as "Not Yet Defined" above. Whether Companion memory (if PD-11 confirms it as Core Beta) uses Supabase or remains local-first (`SharedPreferences`) — see PD-06 in `TruLura_Engineering-Governance.md` §02.

## Cross-References

`docs/03-Architecture/TruLura_Blueprint-to-Code-Matrix.md` (source for every row above) · `docs/02-Product/TruLura_Product-Decisions.md.md` · `docs/02-Product/TruLura_Engineering-Gap-Register.md.md` · `docs/04-Engineering/TruLura_Engineering-Backlog.md` · `docs/03-Architecture/ADR/` (ADR-001 through ADR-005).
