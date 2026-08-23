# TruLura Blueprint — Implementation Roadmap (Living Document)

*New as of Sections 16–20 batch. Covers Sections 1–20 reviewed so far. "Flutter modules / Backend / Database" columns are anticipated categories only — no repository has been reviewed, so nothing here is verified against real code. This roadmap sequences by dependency, not by calendar time.*

| Blueprint Section | Anticipated Feature Area (unverified) | Anticipated Backend Systems | Anticipated Data Entities | Priority | Blocked By |
|---|---|---|---|---|---|
| 1 — Identity & Trust | Auth/verification/profile-anchor module | Identity service, Trust score service | Master Profile ID, Verification record, Trust Score history | **Critical** | PD-01 (tier naming) |
| 2/3 — Experience Modes | Mode-switching shell, wraps all other features | Mode/state service | Active Mode, Mode Transition log | **Critical** | Section 2/3 merge execution; PD-01 |
| 4 — Discovery/Aura | Feed module | Feed ranking service | Content object, Tag taxonomy, Ranking signals | **Critical** | EG-04 (ranking formula), PD-03 |
| 5 — Profile | Profile module | Profile service | Profile schema (EG-03) | **Critical** | EG-03 |
| 6 — Matchmaking/Spark | Matchmaking/dating module | Match service, effort-scoring service | Connection/Match object | **High** | EG-09 (effort formula), PD-06 |
| 7/8 — Monetization | Wallet/payments module, Creator monetization | Wallet service, Payout integration | Wallet, Transaction, Payout | **High** | PD-07 (financial figures) |
| 9 — Safety | Trust & Safety module (cross-cutting, not a single screen) | Moderation service, real-time behavioral analysis | Report, Moderation Action, Safety Flag | **Critical** | PD-12 (crisis detection, needs Trust & Safety input) |
| 10 — Navigation/State | App shell, primary navigation | Session state service | Session/Active State | **Critical** | **PD-14 (Navigation contradiction — blocks this entirely)** |
| 11 — AI Intelligence | Recommendation/decision layer (backend-primary) | AI decision service | — (consumes, doesn't own data) | Medium | EG-05 (MoodSync signals) |
| 12 — MoodSync | Cross-cutting emotional-state layer | MoodSync service (highest fan-out) | Emotional State object/history | **Critical** | EG-05 |
| 13 — Creator Platform/TruStudio | Creator dashboard module | Creator/tier service | Creator profile/tier | Medium | PD-01, EG-11 (now single-source via 18.3) |
| 14 — Vent Space | Isolated support module | Crisis-detection service (shared with 9, 15) | Vent post/session (privacy-sensitive) | **High** | PD-12 |
| 15 — AI Companion | Companion/chat module | Companion service, memory store | Companion memory (privacy-sensitive) | Medium | PD-11 (baseline/enhanced line), EG-15 (retention policy) |
| 16 — TruTravel | Travel/Experience module | Experience/Travel-Match service | Experience, Travel Match, Group | Low (Phase 2) | PD-17 |
| 17 — TruLuxe | Premium-tier module | Qualification/concierge service | TruLuxe tier/qualification status | Low (Phase 2) | PD-18 |
| 18 — Gamification | Progression/rewards module | Progression service (now single, per 18.3) | Progression/Pathway state | Medium | Advancement criteria (EG-11 remainder) |
| 19 — Orchestration / Social Ecosystem | Event bus (cross-cutting) + Spaces/Communities module | Orchestration engine, Space service | Space, Space Membership, Space Role | **High** | EG-23 (schema), EG-01 remainder |
| 20 — Interface/UI | Adaptive UI framework, accessibility modes | N/A (frontend-primary) | UI/interface preference state | **Critical** | **PD-14** |

## Sequencing Notes

1. **PD-14 (Navigation contradiction) blocks both Section 10 and Section 20's implementation entirely** — recommend this be the first Product Decision resolved once this roadmap is in hand, since it's the only item blocking two Critical-priority rows simultaneously.
2. **Sections 1, 2/3, 4, 5, 9, 12 form the true Core Beta backbone** — every one of them is either explicitly Core Beta or so foundational that nothing else can be built without it. These should be sequenced first regardless of the roadmap's other priorities.
3. **MoodSync (12) has the highest fan-out of any backend service** (11, 13, 14, 15, 18, 19, 20 all depend on it) — recommend it be built early enough that dependent teams aren't blocked, even though it's not itself a user-facing feature.
4. **Sections 16 and 17 are correctly low-priority** per their own Phase 2 classification — no need to front-load these.

*Roadmap will be extended with Sections 21–26 after the final batch.*

## Batch Update: Sections 21–26

| Blueprint Section | Anticipated Feature Area (unverified) | Anticipated Backend Systems | Anticipated Data Entities | Priority | Blocked By |
|---|---|---|---|---|---|
| 21 — Integrations | Adapter/gateway layer (not user-facing) | Integration gateway | — | **High** | PD-19 (vendor selection) |
| 22 — Security/Compliance | Cross-cutting middleware | Auth, encryption, audit logging | Retention policy per data type | **Critical** | PD-20 (retention periods) |
| 23 — Infrastructure | N/A (deployment/infra, not app feature) | Cloud provisioning, scaling config | — | Medium | Stack selection (outside blueprint scope) |
| 24 — Governance | Admin/moderation panel (likely separate from end-user app) | Policy/rule engine | Rule/Policy records | Medium | — |
| 25 — UX Journey | Onboarding + engagement-orchestration module | Journey service (consumes event bus) | Journey/flow state | **High** | PD-14 (transitively, via Section 20) |
| 26 — Future Expansion | N/A (planning document) | N/A | N/A | N/A | — |

## FINAL Sequencing Recommendation (all 26 sections)

1. **Resolve PD-14 (Navigation) and PD-12 (Crisis Detection) first** — both are Critical, both block multiple downstream rows, neither is a pure engineering decision (PD-14 needs a Product call on which nav structure is correct; PD-12 needs Trust & Safety).
2. **Build the Foundation layer next:** Identity (1), Mode (2/3), MoodSync (12), Security/Compliance (22) — everything else depends on these four, directly or transitively.
3. **Vendor decisions (PD-19: payment, identity verification) should happen in parallel with #2**, not after — they're pure Product/procurement work and don't block engineering on the Foundation layer, but they do block Sections 1.2 and 7/8 specifically.
4. **Mid-tier systems** (Discovery/4, Profile/5, Matchmaking/6, Monetization/7-8, Safety/9, AI/11, Creator/13, Vent/14, Companion/15, Orchestration/19, Progression/18) follow, largely in parallel once Foundation is stable.
5. **Phase 2+ systems** (TruTravel/16, TruLuxe/17) are correctly deferred — no need to front-load.
6. **Governance/Infra/Journey** (21, 23, 24, 25) are cross-cutting and can proceed alongside the mid-tier once their specific blockers (PD-19, PD-20, PD-14 transitively) clear.

*Implementation Roadmap is now complete for all 26 sections (v1 of the Product Knowledge System).*
