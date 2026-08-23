Blueprint ↔ Code
Synchronization Pass
Method & sources
Five findings that change the backlog
PD-14 — navigation, side by side
Full 26-section matrix
What this changes
Synchronization Pass · Read-only · No code modified
Blueprint-to-Code Matrix
Every one of the Blueprint's 26 sections, checked against what actually exists in the Flutter repository — the first pass since the Product Knowledge System landed in docs/02-Product.

Blueprint source TruLura_Blueprint.md.md (v2, 26 sections)
Registers used Product Decisions, Engineering Gaps, Dependency Graph, Roadmap, Beta Readiness
7
Exists
9
Partially exists
3
Placeholder
5
Missing
2
N/A (planning-only)
00
Method & sources
The five living registers (Product Decisions, Engineering Gap Register, Dependency Graph, Implementation Roadmap, Beta Readiness Checklist) and the Project Completion Summary were read in full — 410 lines combined, and they already distill the 20,254-line Blueprint's structure, priorities, and open questions in exactly the form needed for this cross-reference. The raw Blueprint itself was consulted with targeted searches rather than read linearly end to end, specifically to verify the two claims that mattered most for this pass: the exact wording of the two navigation structures in conflict (PD-14, quoted verbatim in §02) and whether "Sync" and "Spark" are used interchangeably in the Blueprint's own text (confirmed — see §01, finding 2). Every code-side claim traces back to the four repository-side documents already published (Architecture Map, Systems & Debt Review, Engineering Backlog, Engineering Governance) rather than being re-derived from scratch.

01
Five findings that change the backlog
These aren't new debt items — they're corrections and elevations to conclusions already published, now that real product context exists to check them against.

1 — PD-14 is real, and it's not the question ADR-03 was asking

The Governance document's ADR-03 asked whether MainShell's persistent chrome should extend to more routes — a real code-level question, but a different one from PD-14, which is a contradiction inside the Blueprint itself between Section 10.9.1's 3-tab structure (Aura/Sync/Explore) and Section 20.2.1's 4-item structure (Feed-Discovery/Messaging/Profile/Mode Switching). ADR-03's question is downstream of PD-14, not equivalent to it. The Governance document's numbering (which mislabeled this "PD-07") is corrected below.

2 — "Spark" almost certainly already exists in code, as "Sync"

The Blueprint itself uses Sync (Matchmaking / Dating Mode) in Section 10.8/10.9.1 and Spark everywhere else (Section 6's title, and cross-references in Sections 7, 8, 11, 13, 17) for what reads as the same system — the register's own PD-08 asks exactly this. The Flutter code's SyncScreen/SyncService/matchroom_screen.dart almost certainly is the intended implementation of Blueprint Spark, just built under the "Sync" label. The Unified Ecosystem Evaluation's earlier verdict of "Spark: Missing" is superseded — see §04, row 6.

3 — TD-02 (mood fragmentation) is more important than it was scoped as

What the Systems & Debt Review called "Mood" is Blueprint Section 12, MoodSync — the single highest-fan-out dependency in the entire product (9+ confirmed consuming sections: AI, Creator Platform, Vent, Companion, Interface, Safety, Journey, Orchestration, Social Ecosystem). The Blueprint's own Engineering Gap Register independently flags the same underlying problem from the product side (EG-05: no defined signal set, detection thresholds, or Social Battery model) — meaning code and product are both missing a formal MoodSync model, for related but distinct reasons. This elevates TD-02/ENG-003 from a UI-consistency bug to foundational, cross-cutting work that a large share of the rest of the product depends on. It also means this can't be resolved by engineering alone — EG-05 needs Product input on the signal set before code can fully converge on one model.

4 — Creator Platform is not purely Post-Beta

The Beta Readiness Checklist confirms TruStudio early monetization (13, partial) as Core Beta — only the expansion tier is Phase 2. ENG-013 was scoped as "Post Beta by default" without this context; it should split into a Core-Beta early-monetization slice and a Phase-2 expansion slice, corrected in §05.

5 — Companion's missing persistence may not be a Beta gap at all

PD-11 proposes that baseline (non-memory) Companion is Core Beta and persistent memory is Phase 2 — not yet confirmed, but if it holds, TD-12/ENG-009's finding ("Companion state is fully ephemeral") describes the correct Core-Beta behavior, not a gap. ENG-009's priority and sprint candidate are revised pending PD-11 in §05, rather than assumed either way.

02
PD-14 — the two candidate navigations, and what code actually does
Quoted directly from the Blueprint, compared against the real GoRouter tree documented in the Architecture Map. This is offered as evidence for whoever resolves PD-14, not a vote for either side.

Section 10.9.1 — Primary Navigation (Top Tabs)
Aura (Social Feed / Identity Layer)
Sync (Matchmaking / Dating Mode)
Explore (Discovery & Spaces)
10.9.2 — Secondary (Side Menu)
Profile · Creator Dashboard · Vent Space · Travel Mode · TruTV · Events/Live Hub · Settings · Marketplace/Shop
Section 20.2.1 — Primary Navigation
Feed / Discovery
Messaging / Conversations
Profile & Identity
Mode Switching
20.2.2 — Secondary
Creator Tools · Matchmaking Spaces · Vent/Support · Settings
What the Flutter code actually does today
A hybrid of both, built independently of this conflict being known: the bottom-nav shell (MainShell) has 4 branches — Home, Messages, Notifications, Profile — matching 20.2.1's cardinality more closely (though "Notifications" isn't "Mode Switching"). But Home internally tab-switches between exactly Aura, Sync, Explore — 10.9.1's three items, verbatim, just nested one level deeper than the Blueprint specifies. The side drawer covers Settings, Vent (/vent), Creator Dashboard (/trustudio), and Live Hub (/live) — a subset of 10.9.2's list; Travel Mode, TruTV, and Marketplace have no code at all, consistent with them being Phase 2+.

Cost of each resolution: confirming 10.9.1 costs little — code already matches it, just needs the Aura/Sync/Explore tabs promoted one level up (to real shell branches) if a literal 3-tab bottom nav is wanted. Confirming 20.2.1 costs more — "Mode Switching" as a primary nav item doesn't exist anywhere in code today and would need new UI, though the 4-item cardinality is already close.

03
Full 26-section matrix
Status reflects code reality, not Blueprint completeness — a section can be Blueprint-complete and still Missing in code, or vice versa. "Blocked by" cites the real register IDs.

§ System Beta Code status Affected Flutter modules Blocked by
1 Identity & Trust Core Beta 🟡 Partial models/user.dart, services/identity_service.dart, identity_profile_service.dart, trust_score_service.dart (unused), providers/app_provider.dart PD-01/15, PD-04, EG-02, EG-03, EG-07, EG-19
2/3 Experience Modes Core Beta ✅ Exists providers/experience_mode_controller.dart, models/experience/experience_mode.dart (8 modes) PD-01
4 Discovery/Aura Core Beta (base) ✅ Partial screens/home/home_feed_screen.dart, services/feed_distribution_engine.dart, visibility_service.dart, post_service.dart EG-04, PD-03
5 Profile Core Beta 🟡 Partial models/user.dart, screens/profile/profile_screen.dart, services/profile_completion_service.dart PD-04, EG-03
6 Matchmaking/Spark Core Beta (base) ✅ Partial — as "Sync" screens/sync/sync_screen.dart, matchroom_screen.dart, services/sync_service/sync_service.dart (local-only, no Supabase) PD-06, PD-08, EG-09, EG-13
7/8 Monetization & Creator Economy Split ✅/🟡 Missing none found — no wallet/payment/payout code anywhere in lib/ PD-07, PD-19, EG-08, EG-12
9 Safety Core Beta 🟡 Partial services/safety_center_service.dart, safety_meter_service.dart, safety_monitoring_service.dart, trust_signal_service.dart, aura_shield_service.dart, reporting_service.dart PD-05, PD-12, EG-06
10 Navigation/State Core Beta 🟡 Partial — hybrid, matches neither candidate cleanly core/navigation/app_router.dart, screens/main_shell.dart, screens/home/home_hub_screen.dart PD-14 (blocks outright)
11 AI Intelligence Split Placeholder openai/openai_config.dart (2 narrow methods only — not a decision engine) EG-05
12 MoodSync Core Beta ✅ (cleanest section) Partial — fragmented models/emotional_presence_state.dart, providers/app_provider.dart, providers/aura_state.dart (two disconnected systems, TD-02) EG-05
13 Creator Platform/TruStudio Split ✅/🟡 Placeholder screens/trustudio/trustudio_screen.dart (full 6-tab UI shell, zero backend), gating flags on AppProvider PD-01, EG-11 remainder
14 Vent Space Core Beta ✅ Exists screens/vent/vent_screen.dart, services/feed_demo_content_service.dart, visibility_service.dart (isolation) PD-12
15 AI Companion Split 🟡 Placeholder screens/ai/ai_companion_screen.dart (ephemeral StatefulWidget state only, TD-12) PD-11, EG-15
16 TruTravel Phase 2 🚫 Missing none — correctly out of scope PD-17
17 TruLuxe Phase 2 🚫 Missing none — correctly out of scope PD-18
18 Gamification ❓ Unclear Missing none — no progression/rewards code found PD-16
19 Orchestration / Social Ecosystem Core Beta 🟡 (Orchestration half) Missing none — no event bus, no Spaces/Communities code EG-23
20 Interface/UI Core Beta 🟡 Partial — well-built, inconsistently adopted widgets/trulura_layered_background.dart, theme.dart, theme/mood_colors.dart (TD-03, TD-07, TD-08) PD-14 (blocks outright)
21 Integrations Core Beta 🟡 Placeholder openai/openai_config.dart only — no payment/verification vendor integration PD-19
22 Security/Compliance Core Beta 🟡 Partial services/compliance_service.dart, communication_safety_service.dart (heuristics, not formal encryption/audit-log/retention code) PD-20
23 Infrastructure Core Beta (baseline) N/A Flutter + Supabase is already the committed stack — compatible with the Blueprint's deliberately stack-agnostic Section 23 —
24 Governance Core Beta 🟡 Missing none — Blueprint itself notes this is likely a separate admin app, not end-user code —
25 UX Journey Core Beta 🟡 Partial features/onboarding/\* (exists, but not yet on the shared theme system, TD-07); no re-engagement/journey-orchestration code beyond onboarding PD-14 (transitively)
26 Future Expansion Planning doc 🚫 N/A not implementable — defines phases, not features —
04
What this changes
Concrete edits made to the three companion documents as a direct result of this synchronization — each cited by its real register ID rather than an invented one.

Engineering Backlog — ENG-001 through ENG-018's "Related Blueprint Sections" and "Related Product Decisions" fields replaced with real section numbers and real PD/EG IDs in place of "Pending blueprint" placeholders; ENG-013 (Creator Platform) split into a Core-Beta early-monetization slice and a Phase-2 expansion slice; ENG-009 (Companion persistence) priority held pending PD-11 rather than assumed Beta-critical; ENG-006 (Notifications) cross-referenced to the Blueprint's own EG-18 (Medium priority, delivery-channel/frequency-cap gap) rather than treated as a pure engineering invention.
Engineering Governance — the ad hoc "PD-01 through PD-09" register is retired; it collided with the real register's numbering and, more importantly, violated the documentation system's own rule that engineering must never author product decisions (docs/04-Engineering's README is explicit on this). Repository-side questions with no real-register match are now logged separately as engineering questions for Product, not decisions engineering made itself. ADR-03 is corrected to distinguish its own question (chrome extent) from PD-14 (the Blueprint's internal contradiction) and now cites PD-14 directly. ADR-01 (Unified Session Object) gains a direct citation to EG-01 (Permission Resolution) as independent validation from the product side.
Systems & Debt Review — TD-02 (mood fragmentation) reframed with its MoodSync/EG-05 context; TD-13 (session topology) cross-referenced to EG-01; TD-01 (identity fragmentation) cross-referenced to PD-01/PD-15's four-way tier-naming conflict.
Still not fabricated

Nothing above assumes an answer to an open Product Decision. Where the Blueprint itself is undecided (PD-14, PD-11, PD-06, PD-08, and the rest), this matrix and the updated backlog say so explicitly rather than picking a side.
