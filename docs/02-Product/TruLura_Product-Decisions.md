# TruLura Blueprint — Product Decisions Register (Living Document)

*Consolidated from Sections 1–15. Add new entries here going forward instead of scattering them in section reviews. Nothing in this register has been decided — each entry is open until Product resolves it.*

| ID | Section(s) | Decision Required | Reason | Blocking Level | Related Systems | Recommendation |
|---|---|---|---|---|---|---|
| PD-01 | 1, 2, 9 | Is verification/trust tier naming (Section 1.2: Level 0–3; Section 2.1.2: Unverified–Elite Verified; Section 9.2.1/9.2.2: third scheme) one system under three names, or genuinely different scales? | Three-way naming conflict, now the highest-priority unresolved item, touching Identity, Modes, and Safety | **Critical** | 1, 2, 9 | Confirm one canonical scale; recommend Section 1.2's Level 0–3 as the base, with others as display-label variants only if confirmed equivalent |
| PD-02 | 2/3 | Do Travel Mode and Event Mode exist dormant at launch, or arrive with Phase 2? | Section 3.8 fully specifies both; 26.16.2 places TruTravel/Events in Phase 2 | Medium | 2/3, 16, 26 | — |
| PD-03 | 4 | Do the feed's Event/Community-World layers (4.13, 4.18) ship at launch or defer to Phase 2? | Fully specified in Section 4 but overlaps Phase 2 systems per 26.16.2 | Medium | 4, 19, 26 | — |
| PD-04 | 1, 5 | Confirm Sections 1 (Identity/Trust) and 5 (Profile) as explicitly Core Beta | Required by every Phase 1 system but never named in 26.16 | Low (inference is very likely correct) | 1, 5, 26 | Confirm and add to 26.16's Phase 1 list |
| PD-05 | 9 | Confirm Section 9 (Safety) as explicitly Core Beta | Same gap as PD-04, but highest-stakes given harm potential if deprioritized | **High** | 9, 26 | Confirm and add to 26.16's Phase 1 list as a priority item |
| PD-06 | 6 | Which of Section 6's 24 subsections are Core Beta (base Spark) vs. Phase 2 (advanced Spark)? | 26.16 distinguishes "Spark" (P1) from "Advanced Spark Features" (P2) but Section 6 doesn't mark which subsections are which | Medium | 6, 26 | Best-effort mapping proposed in Section 6 review — needs confirmation |
| PD-07 | 7/8 | Exact revenue-split figures (not ranges), payout mechanics (processor, threshold, cadence), and Core-Beta-vs-Phase-2 split within monetization | Section 7 gives ranges only; "early monetization" (P1) vs. "Creator Monetization Expansion" (P2) boundary is inferred | **High** (financial/compliance risk) | 7/8, 26 | Best-effort mapping proposed in Section 7/8 review — needs confirmation |
| PD-08 | 10 | "Sync" (nav tab label) vs. "Spark" (system name used everywhere else) — same system, different label, or an error? | Only user-facing naming inconsistency found so far | Medium | 6, 10 | Do not rename either without confirmation — flagged only |
| PD-09 | 10 | Navigation menu phase-visibility rule: does the full menu (including Phase 2/3 items) show at launch, or reveal progressively? | 10.9.2 lists Phase 1–3 items in one undifferentiated menu | Medium | 10, 26 | — |
| PD-10 | 1, 10 | Is Section 1.1.4's Identity States a third naming of Mode (Section 2/3, confirmed equal to Section 10's Active State), or a genuinely separate axis? | Narrowed from a 3-way to a 2-way question after Section 10's review | Medium | 1, 2/3, 10 | Likely the same list under a third name, given the PD-01 pattern — needs confirmation, not assumption |
| PD-11 | 15 | Where exactly does the Core-Beta/Phase-2 line fall within AI Companion — is memory persistence the dividing feature, as proposed? | 26.16.2 calls out "memory-based support" as Phase 2 but doesn't define the P1 baseline | Medium | 11, 15, 26 | Proposed: baseline (non-memory) Companion is Core Beta; persistent memory is Phase 2 — needs confirmation |
| PD-12 | 9, 14, 15 | What is the crisis-detection mechanism (method, thresholds, escalation)? | Referenced identically in three sections with no shared spec | **High** (safety-critical) | 9, 14, 15 | Requires Trust & Safety input, not an engineering placeholder — do not invent |
| PD-13 | 13, 14, 15 | Blocked/restricted monetization mechanics in Vent Space (14.9) and AI Companion (15.10) — "strict rule" stated without an actual rule set | "Strict" is a label, not an enforceable spec | Medium | 7/8, 14, 15 | — |

*Register will continue to grow as Sections 16–26 are reviewed.*

## Batch: Sections 16–20 additions

| PD-14 | **10, 20** | **Which Primary Navigation structure is correct — Section 10.9.1 (Aura/Sync/Explore, 3 tabs) or Section 20.2.1 (Feed-Discovery/Messaging/Profile/Mode Switching, 4 items)?** | Direct contradiction, not just a naming variance — two different structures for the same top-level navigation, no cross-reference between the sections | **Critical** | 10, 20 | Escalated above PD-08/PD-09, which are now subordinate to this — resolve this first, then reconcile "Sync" labeling within whichever structure is confirmed |
| PD-15 | 1, 2, 9, 16 | PD-01 update: safety/trust tier-naming conflict is now **four-way** — Section 16.5 adds a "safety score (internal)" as a fourth independent reference | Same root question as PD-01, expanding in scope with each batch reviewed | **Critical** (upgraded from Critical, scope expanded) | 1, 2, 9, 16 | Same as PD-01 — resolve once, applies to all four |
| PD-16 | 18 | Is Gamification/User Evolution (Section 18) Core Beta, Phase 2, or partially both? | Not named in 26.16 at all; unlike Identity/Safety/Navigation, plausibly separable rather than strictly foundational | Medium | 18, 26 | Do not assume Core Beta by default here, unlike PD-04/PD-05 — needs an actual decision |
| PD-17 | 16 | Group-size limits and safety-score threshold for TruTravel real-world meetups | Real-world physical safety stakes, not a typical engineering placeholder | **High** (safety, real-world) | 9, 16 | Recommend Trust & Safety / Legal input, not an engineering guess |
| PD-18 | 17 | TruLuxe qualification algorithm — must avoid discriminatory-access risk | Gated-access system at scale raises anti-discrimination considerations | **High** (legal/compliance) | 9, 17, 22 | Recommend Legal review before qualification criteria are finalized |

## Batch: Sections 21–26 additions

| PD-19 | 21 | Select and name the payment processor and identity-verification vendor | Real external dependency with cost/compliance implications; blocks Section 7/8 and Section 1.2 engineering | **High** | 1, 7/8, 21 | Product/procurement decision, not engineering |
| PD-20 | 22 | Define data retention periods per data category | Blocks EG-15 (Companion memory retention) and general compliance posture at scale | **High** (compliance) | 15, 22 | Requires Legal/Compliance input |
| PD-21 | 22, 1, 9 | Confirm the 22.25 escalation ladder (Warning→Restriction→Suspension→Ban) as the single enforcement mechanism referenced by Sections 1.6 and 9.5.4.1 | Resolves a previously-flagged duplication gap with an actual usable answer | Low (mostly a documentation confirmation) | 1, 9, 22 | Recommend confirming and cross-referencing rather than re-specifying |

## FINAL STATUS: 21 open Product Decisions across 26 sections reviewed.
**Top 3 by blocking severity:** PD-14 (Navigation contradiction, Sections 10/20) · PD-12 (Crisis detection mechanism, Sections 9/14/15) · PD-01/PD-15 (four-way trust/verification tier naming, Sections 1/2/9/16).
