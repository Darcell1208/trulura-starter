# TruLura Blueprint — Engineering Gap Register (Living Document)

*Consolidated from Sections 1–15. Priority: **Critical** (blocks multiple systems) / **High** (blocks one major system) / **Medium** (needed before that system ships, not blocking others) / **Low** (nice to have before build).*

| ID | System | Gap | Priority | Dependencies | Suggested Engineering Artifact |
|---|---|---|---|---|---|
| EG-01 | Permission Resolution (Sections 1, 2/3, 6, 9, 10) | No formula for combining Mode + Trust Score + Verification Level + Emotional State into one access decision — the single most-referenced gap in the blueprint, home is Section 10.5.1 but logic is unwritten | **Critical** | PD-01 | **Permission Matrix** (companion doc) |
| EG-02 | Trust Score (Section 1.3) | No numeric scale, per-signal weights, or feature-gating thresholds | **Critical** | EG-01 | **Parameter Specification** |
| EG-03 | Master Profile / Profile Data (Sections 1, 5) | No field-level schema; Master Profile ID has no defined data model | **Critical** | — | **Database Schema** |
| EG-04 | Feed Ranking (Section 4) | Layer Priority Rule (4.2.7) has no actual precedence values or scoring formula — blocks the entire 6-layer feed architecture | **Critical** | EG-01 | **Feed Ranking Formula spec** |
| EG-05 | MoodSync signal set (Section 12) | No defined input signals, detection confidence thresholds, or Social Battery numeric model — highest fan-out dependency in the blueprint (7 consuming sections) | **Critical** | — | **Parameter Specification** + **Event Flow** (pub/sub design) |
| EG-06 | Crisis Detection (Sections 9, 14, 15) | No defined detection method or escalation thresholds — same gap in three places, needs Trust & Safety input before an engineering spec can even be scoped | **High** (safety) | PD-12 | Awaiting Product/Trust & Safety input before an artifact can be scoped |
| EG-07 | Verification Levels (Section 1.2) | No permission matrix mapping each level to every gated feature (only one example per level given) | **High** | PD-01, EG-01 | **Permission Matrix** |
| EG-08 | Monetization financials (Sections 7/8) | Coin exchange rate, payout threshold/cadence, exact revenue-split figures, coin dormancy period all undefined | **High** | PD-07 | **Parameter Specification** |
| EG-09 | Effort-Gated Escalation (Section 6.3) | Core Spark pacing/gating mechanism has no scoring formula | **High** | — | **Parameter Specification** |
| EG-10 | Mode/Bandwidth throttling (Sections 2.2.1, 6.6.1, 10.4.1) | Possibly one mechanism described three times — Emotional Bandwidth Limits, Low Energy Mode, Temporary States — none have numeric thresholds | Medium | Needs content comparison across all three before spec'd | **State Machine** + **Parameter Specification**, once consolidated |
| EG-11 | Progression Ladders (Sections 4.18.4, 6.14.12, 13.10.2) | Community, Spark, and Creator progression all name stages with no advancement criteria — same gap pattern, three places | Medium | — | One general **Progression System spec**, referenced by all three |
| EG-12 | Wallet/Transaction data model (Section 7/8) | No schema for Wallet, Transaction, Payout objects | **High** | EG-08 | **Database Schema** |
| EG-13 | Match/Connection data model (Section 6) | No schema for Connection object, stage history | Medium | — | **Database Schema** |
| EG-14 | State-change event propagation (Section 10.8) | Describes *what* propagates (mood→feed, trust→visibility, mode→discovery) but not *how* — implies event-driven architecture, not specified as such | **High** | EG-01, EG-05 | **Event Flow** spec |
| EG-15 | Companion Memory (Section 15.4) | No retention period, storage scope, or deletion mechanism — privacy-sensitive, not just a technical gap | **High** (privacy) | PD-11 | **Parameter Specification** + Privacy/Legal review before an artifact is finalized |
| EG-16 | Accessibility cross-references (blueprint-wide) | Section 10.12.2 is well-developed but not linked from Sections 1, 2/3, 4, 5, 6, 9, or 13–15 | Medium | — | Documentation fix (linking), not a new artifact |
| EG-17 | Drafting artifacts (blueprint-wide) | 5 confirmed leftover editorial/AI-drafting fragments across Sections 6, 13, 14, 15 (and possibly more in unreviewed sections) | Medium (integrity, not functionality) | — | Full-document text sweep — documentation task, not an engineering artifact |
| EG-18 | Notification System (Section 10.13) | Types listed, no delivery-channel or frequency-cap specification | Medium | — | **Notification Matrix** |
| EG-19 | Anonymous Overlay System (Section 1.1) | Named as a core component, never actually specified anywhere in Section 1 | **High** | — | Needs a **spec written first** (not just an artifact — the underlying design is missing, not just its formalization) |

*Register will continue to grow as Sections 16–26 are reviewed.*

## Batch: Sections 16–20 updates & additions

**EG-01 status updated:** Section 19.1.1 provides a coarse conflict-resolution hierarchy (Safety & Consent → State & Mode Logic → AI Interpretation → Experience Systems). This is now **partially resolved** — the category-level ordering exists; the fine-grained formula (exact scoring/weighting when two rules within the same category conflict) is still missing. Natural home for the remaining work is Section 19.5 (Conflict Resolution Framework).

**EG-11 status updated:** **Resolved from 3 gaps to 1.** Section 18.3 (Multi-Dimensional Progression System) confirmed canonical; Sections 4.18.4, 6.14.12, 13.10.2 reframed as consuming pathways. One remaining gap: advancement criteria for 18.3's dimensions/pathways.

| ID | System | Gap | Priority | Dependencies | Suggested Engineering Artifact |
|---|---|---|---|---|---|
| EG-20 | Navigation (10, 20) | Two contradictory Primary Navigation structures | **Critical** | PD-14 | Blocked until PD-14 resolved — no artifact can be built against two conflicting structures |
| EG-21 | TruTravel (16) | No group-size cap, safety-score threshold, or per-layer verification criteria | **High** | PD-17 | **Parameter Specification** — pending Trust & Safety input |
| EG-22 | TruLuxe (17) | No qualification threshold or layered-reveal sequence | **High** | PD-18 | **Parameter Specification** — pending Legal input on qualification criteria |
| EG-23 | Social Ecosystem (19.11–19.23) | No schema for Space, Space Membership, or Space Role; no defined per-role permission set | **High** | EG-01/EG-07 (shares the permission-matrix dependency) | **Database Schema** + **Permission Matrix** |
| EG-24 | Interface/UI State (20.11) | No state-to-UI mapping table | Medium | EG-01 | **State Machine** or mapping table |
| EG-25 | Accessibility modes (20.19) | Strong conceptual content (Neurodivergent, Epilepsy-Safe, Elder-Friendly, Low-Stimulation), no technical spec for what each mode actually changes | Medium | — | **Parameter Specification** |
| EG-26 | Section 20 | Missing "Dependencies" closing subsection — inconsistent with house style established in Sections 12–19 | Low (documentation, not functionality) | — | Documentation fix |

## Batch: Sections 21–26 updates & additions

**EG-06 status updated:** Partially resolved. Section 22.25 provides a usable 4-stage escalation ladder (Warning→Restriction→Suspension→Ban) that Sections 1.6 and 9.5.4.1 should reference. The detection *mechanism* itself (what triggers each stage) remains open pending PD-12/Trust & Safety input — this splits EG-06 into "ladder: resolved" and "detection triggers: still open."

| ID | System | Gap | Priority | Dependencies | Suggested Engineering Artifact |
|---|---|---|---|---|---|
| EG-27 | Payment/Identity vendors (21) | No named processor or verification vendor | **High** | PD-19 | N/A — vendor selection precedes any artifact |
| EG-28 | Data retention (22.5) | No retention period per data category | **High** | PD-20 | **Parameter Specification** — pending Legal input |
| EG-29 | Caching strategy (23.10.1) | No invalidation policy, despite three identified high-read entities (Trust Score, Feed, Profile) needing it | **High** | EG-02, EG-04, EG-03 | **Parameter Specification** |
| EG-30 | Onboarding/Journey (25) | No defined step sequence, friction rules, or re-engagement triggers | Medium | PD-14 (transitively, via Section 20 dependency) | **State Machine** (onboarding flow) |
| EG-31 | Documentation consistency (20–24) | Missing "Dependencies" closing subsection, present in 12–19 and 25 | Low | — | Documentation fix |

## FINAL STATUS: 31 engineering gaps logged across 26 sections.
**Top 5 Critical-priority items, unchanged core group:** EG-01 (Permission Resolution — now partially resolved via 19.1.1), EG-02 (Trust Score parameters), EG-03 (Profile/Master ID schema), EG-04 (Feed Ranking formula), EG-05 (MoodSync signal set), EG-20 (Navigation contradiction).

## Batch: Cross-Reference Index sweep (full-document, all 26 sections)

**EG-17 status updated — scope expanded from 5 confirmed instances (Sections 6, 13, 14, 15) to a full-document inventory.** Producing `docs/03-Architecture/TruLura_Blueprint_Cross_Reference.md` (exhaustive, line-cited, all 26 sections read in full) surfaced substantially more drafting/structural artifacts than the original 5-instance scope. This is a documentation-integrity finding about the Blueprint's own text, not a product-behavior gap and not a new Product Decision — logged here as an EG-17 scope update per this register's own established pattern (see the EG-01, EG-06, and EG-11 status updates above), not as a new ID.

**Confirmed additional instances, by category:**
- **Duplicate headings, same number, different bodies:** §5.4 (×2, lines 5444/5454), §5.6 (×2, lines 5690/5698, with §5.6.2 entirely absent from the sequence), §6.9 (orphaned title followed by a second, differently-titled §6.9), §6.11 (substantially repeats §6.7/§6.7.3), §7.7.2 (×2, lines 10241/10499), §7.11.1 (×2, lines 10696/10732), §7.12.1 (×2, lines 10780/10817), §9.6 (heading repeats consecutively with a stray one-line fragment between), §9.12 (×3 — lines 12000/12038/12044, three unrelated bodies under one number), §9.13 (×2, lines 12080/12084).
- **Title/body mismatches:** §6.7 (titled "Trust, Safety Signals & Risk Awareness Integration," body is "Post-Match Experience Layer"), §6.8 (titled "...Sponsored Integration," body never addresses sponsorship).
- **Out-of-sequence numbering:** §13.10.2 (appears after §13.11), §14.8.1 (appears before §14.8).
- **Self-referential citations** (a section's own text cites itself by number): §12.10 (line 14058, "dynamically influenced by the Mood System (Section 12)" appearing inside Section 12), §15.13 (line 15472, "This connects to" list includes "Section 15 (AI Companion)" as one of its own targets).
- **Likely miscited cross-reference:** §15.13's "This connects to" list also names "Section 6 (Discovery)" where the rest of the document consistently maps Discovery to Section 4 and Matchmaking/Spark to Section 6 — quoted verbatim in the Cross-Reference Index rather than silently corrected.
- **Malformed placeholder text:** §4.3.1 (line 2609), a literal, unresolved "(see Section 6.X)" citation.
- **Missing "Section N owns / does not own / Primary Dependencies" closing subsection**, beyond the six sections (20–24, plus 9 and 10) already known: confirmed absent for Sections 9, 10, 20, 21, 22, 23, and 24 by direct full read of each (previously EG-26/EG-31 covered only 20–24; Sections 9 and 10 have the identical gap and were not previously included in either ID's scope).
- **Asymmetric merge pair:** Section 8 has no closing Dependencies subsection at all, unlike its declared merge partner Section 7 (§7.16) — the two sections were never reconciled to matching structure despite covering near-identical content under parallel numbering.
- **Self-inconsistent "Primary Dependencies" declaration:** §7.16's own explicit dependency list (Sections 11, 12, 13, 18, 20, 25) omits Section 6, despite §6.14.1 explicitly stating that Section 7 is triggered by Section 6's Spark-stage progression events — a genuine cross-subsection inconsistency within Section 7 itself, surfaced independently while rebuilding `TruLura_Dependency_Heat_Map.md` at subsection granularity.
- **One genuine content void, distinct from the above (not a drafting artifact but an unwritten-content gap — flagged, not merged into EG-17's scope):** §5.10 ("Visual Attraction Rendering & Main Character Identity Expression") contains no content — the body reads only "**RECONSTRUCTION PENDING**... removed due to ownership conflict with Profile Privacy & Visibility Controls. To be rebuilt after architecture verification." This has no existing register ID; it is noted here rather than folded into EG-17 since it is a missing-content problem, not a leftover-fragment problem.

**Suggested engineering artifact (unchanged from EG-17's original entry):** a full-document text sweep is still the right remediation shape — this is a documentation task for whoever maintains the Blueprint source, not a new engineering build artifact. Priority remains **Medium (integrity, not functionality)** for the drafting-artifact items; the one content-void item (§5.10) is a Product-side authoring gap and is outside this register's scope to prioritize.
