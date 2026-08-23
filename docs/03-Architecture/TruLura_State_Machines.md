# TruLura State Machine Inventory

*Every system in the TruLura Blueprint that defines states, stages, or transitions, compiled from the "Lifecycle/State/Transition Language" flagged lists gathered while producing `TruLura_Blueprint_Cross_Reference.md`. Organized around the 12 systems named in the current documentation task: Identity, Modes, Mood, Recovery, Travel, Creator, Verification, Trust, Safety, Connection, Progression, Journey. Where the Blueprint presents states as a sequential, ordered progression, this document represents that as a state machine; where the Blueprint presents states as a parallel, non-sequential set (several named states a user can independently be in), this document says so explicitly rather than inventing an ordering. No transition trigger, threshold, or timing is stated below unless the source text states it — the overwhelming majority of transitions in the Blueprint have no numeric threshold at all, which is the substance of Engineering Gap EG-13 (Connection/Match data model) and its analogs across the other 11 systems.*

## 1. Identity

**Type: Parallel state set, not a sequential machine.** Section 1.1.4 explicitly frames these as simultaneously-held identity contexts, not a progression: *"A user may be socially active, emotionally low-energy, creator-enabled, and currently unavailable for dating all at once."* (§10.1, restating the same principle from the state-model side.)

| State | Description | Source |
|---|---|---|
| Social | Default participation context | §1.1.4 |
| Relationship | Romantic/dating-context identity | §1.1.4 |
| Creator | Creator-mode identity | §1.1.4 |
| Community | Community-participation identity | §1.1.4 |
| Anonymous | Identity-masked context | §1.1.4 |
| Healing | Recovery/support-context identity | §1.1.4 |
| Travel | TruTravel-context identity | §1.1.4 |
| Luxe | TruLuxe-context identity | §1.1.4 |

**Invariant across all states**: *"Trust remains unified across states / Safety systems remain unified across states / Platform accountability remains unified across states."* Core Principle: *"Different expressions are permitted. Identity fragmentation is not."* (§1.1.4)

**Transition logic** (§1.1.1, Identity State Transition Logic):
- **Triggers**: Direct user action (switching modes, activating creator tools, enabling anonymity, entering Luxe environments) OR System-triggered condition (attempting restricted actions, entering high-risk/high-trust environments, behavioral signals requiring elevation).
- **Eligibility checks consumed**: Verification level, Trust score thresholds, Privacy settings, Platform compliance requirements — no numeric values given.
- **State persistence**: *"The system remembers the user's last valid identity state"*; *"Returning users resume their previous mode when applicable."*
- **Restriction logic**: If requirements are not met, *"the transition is blocked / the user is clearly informed of missing requirements."*
- **Reversibility**: Not explicitly addressed at the identity-state level (contrast with Connection states below, which explicitly support reverse transitions).

**Conflict/Alias**: Product Decision PD-10 asks whether this Identity States list is a third naming of the same underlying concept as Section 2/3's Mode and Section 10.1's Active State — unresolved in the text.

## 2. Modes (Experience Modes / Participation Contexts)

**Type: Named states with explicit transition examples, not a strict linear machine.** Users hold one active Mode at a time (per §10.2's Active/Passive/Restricted model, below) but may move between named Modes.

| Mode | Source |
|---|---|
| Social Participation | §2.1, §3.2 |
| Friendship Discovery | §2.1, §3.3 |
| Romantic Connection | §2.1, §3.4 |
| Vent / Support | §2.1, §3.5 |
| Creator (Overlay System Layer) | §2.1, §3.6 |
| Youth (Isolated Safety Environment) | §2.1, §3.7 |
| Luxe / Elite | §2.1 |
| Travel / Event (Specialized Modes) | §3.8 |

**Named transition examples** (§2.8, §2.14): Social → Friendship, Friendship → Spark, Spark → TruTravel, Vent → Recovery, Creator → TruLuxe, Community → Real-World Experiences.

**Transition mechanisms** (§3.9): Manual switching, Guided transitions, Restricted transitions. Transitions affect: Discovery logic, Interaction permissions, UI layout, Safety enforcement levels.

**Underlying state categories** (§10.2, the formal state-model definitions layered under Mode):
- **Active State** — "the mode or participation context currently governing the user's experience"
- **Passive State** — "remain enabled in the background without controlling the interface"
- **Restricted State** — "systems or environments that are currently unavailable"

**Mode persistence & re-entry** (§10.3/10.3.1): Activation is recorded as both a current experience state and a persistent preference condition; *"Re-entry logic allows users to return to a mode with continuity instead of restarting."* Mode Behavior includes explicit **"Mode Expiration Or Manual Exit"** as a transition event, but no expiration duration is given.

**Temporary sub-states within Modes** (§10.4/10.4.1): Low-Energy Mode, Social/Matchmaking Cooldowns, Burnout Prevention States, Temporary Trust Review — each a time-bounded overlay on the active Mode, not a Mode itself. **Recovery Conditions** (§10.4.2) that end a temporary state: Time-Based Reset, User Action/Manual Reset, Behavioral Stabilization, Trust Restoration — no durations given (**Engineering Gap EG-10**, "none have numeric thresholds," cited three times: §2.2.1, §6.6.1, §10.4.1).

## 3. Mood (MoodSync Emotional State)

**Type: Continuous, non-discrete — the Blueprint explicitly rejects a strict step-machine model here.** *"Each state is dynamic and continuously updated based on behavioral patterns rather than single interactions"* (§12.2); *"It recalibrates gradually, rather than making abrupt changes"* (§12.3).

**9 Primary Emotional States** (§12.2 — parallel, not sequential; a user occupies one at a time but can move between any two without a fixed path):

| State | System Behavior Triggered |
|---|---|
| Open / Social | Increases visibility, expands social opportunities, prioritizes interactive content |
| Flirty / Romantic | Enhances Spark exposure, introduces more compatible matches, enables light progression |
| Curious / Exploring | Low-pressure discovery, avoids aggressive matching, diverse content exposure |
| Low Energy / Passive | Slows feed pacing, limits notifications, reduces interaction demands |
| Overwhelmed / Burnt Out | Minimizes stimulation, reduces visibility pressure, shifts to calmer content |
| Emotionally Vulnerable | Prioritizes safety, reduces high-risk exposure, avoids monetization/pressure features |
| Healing / Reflective | Supports reflective content, journaling prompts, low-pressure interactions |
| Confident / High Energy | Expands reach, increases interaction opportunities, deeper feature access |
| Disconnected / Withdrawn | Reduces interaction pressure, lowers visibility expectations, passive content flow |

**Related, separately-defined parallel state sets** (all Section 12, all continuous/gradual per the same "no abrupt changes" principle):

| Sub-system | States | Source |
|---|---|---|
| Emotional Readiness | Open, Guarded, Exploring, Friendship Focused, Relationship Ready, Healing, Unavailable | §12.5 |
| Social Battery | High Energy, Moderate Energy, Low Energy, Recovering, Offline | §12.7 |
| Atmosphere | 10 categories (see Glossary) | §12.8.1 |

**Readiness Transitions** (§12.5.2): *"May occur due to: Personal growth, Relationship experiences, Life events, Recovery progress, Community involvement, Emotional development."* *"The system evaluates readiness gradually and avoids abrupt classification changes."* No numeric trigger given.

**Operational core**: The Context Routing Engine (§12.8.5) is the single component that ingests all MoodSync sub-states and routes them to 10 named platform-area outputs — but the routing logic itself is unspecified (**EG-05**, MoodSync's canonical, highest-priority engineering gap).

## 4. Recovery

**Type: Named states presented in a consistent order across three separate sections, but never explicitly declared a strict sequence.**

| State | Source(s) |
|---|---|
| Healing | §12.8.4, §14.7.1, §25.11.1 |
| Recovering | §12.8.4, §14.7.1, §25.11.1 |
| Reflecting | §12.8.4, §14.7.1, §25.11.1 |
| Rebuilding | §12.8.4, §14.7.1, §25.11.1 |
| Reintegrating | §12.8.4, §14.7.1, §25.11.1 |

**Named entry conditions** (§14.6, crisis/moderation trigger): Distress signals, harmful interaction patterns, repeated negative engagement loops route a user toward Recovery-state content.

**Named exit transition** (§14.12, the one place the Blueprint states a Recovery exit rule): *"When users stabilize emotionally: System gradually reintroduces broader platform features; Interaction intensity increases naturally."* No stabilization criterion or duration given.

**Bidirectional relationship with Vent Space** (§14.7): *"Emotional expression [in Vent Space] updates mood detection accuracy"* — Recovery-state classification and Vent-Space activity influence each other, though no formula is given for how.

## 5. Travel (TruTravel Experience Flow)

**Type: Explicit, ordered 7-stage sequence — the most fully-specified state machine in the Blueprint.** Confirmed Phase 2 (§16 — see `TruLura_Blueprint_Cross_Reference.md`).

```
Discovery → Interest Expression → Eligibility Check → Commitment Phase
   → Pre-Experience Alignment → Experience Execution → Post-Experience Reflection
```

*Source: §16.4, Experience Structure & Flow.*

| Stage | Content |
|---|---|
| 1. Discovery | Surfacing travel experiences to the user |
| 2. Interest Expression | User signals interest |
| 3. Eligibility Check | **"Safety + compatibility verification"** — the explicit hard gate |
| 4. Commitment Phase | User commits to the experience |
| 5. Pre-Experience Alignment | Pre-trip coordination/matching |
| 6. Experience Execution | The travel experience itself |
| 7. Post-Experience Reflection | Feeds into §16.11 Post-Experience Continuity (memory logging, highlights, progression tracking) |

**No forward-only enforcement is stated** — whether a user can be returned to an earlier stage (e.g., re-run the Eligibility Check) is not addressed in the text.

## 6. Creator

**Type: Three overlapping named progressions that are not explicitly reconciled with one another.**

**A. Creator Progression & Mentorship** (§13.10.2 — explicitly reframed as a consuming pathway of the canonical §18.3 Progression System, per Engineering Gap EG-11):

```
Emerging Creator → Developing Creator → Established Creator → Community Leader → Mentor Creator → Platform Ambassador
```

**B. Creator Revenue Tier Framework** (§7.7.2/§8.9 — a parallel, monetization-specific tier list, not explicitly mapped to (A)):

```
Emerging Creator → Growing Creator → Established Creator → TruElite Creator
```

*Advancement criteria for either progression are not numerically defined — Engineering Gap EG-11 ("advancement criteria for 18.3's dimensions/pathways" remains open even after the 3-gaps-to-1 resolution).*

**C. Creator Journey Phases** (§25.8 — a lifecycle framing distinct from both tier systems above):

```
Entry Phase → Growth Phase → Expansion Phase
```

| Phase | Activities |
|---|---|
| Entry | Activate creator mode, set up monetization |
| Growth | Build content, audience, and earnings |
| Expansion | Brand partnerships, live events, premium offerings |

**Creator Sustainability/Burnout states** (§7.6.1, §11.2.6): Fatigue/burnout indicators trigger reduced monetization prompts, encouraged rest periods, limited engagement pressure — a wellness overlay on the progression, not itself a stage.

## 7. Verification

**Type: Ordinal tier system — the closest thing to a clean, numbered scale the Blueprint provides, though not framed as a state machine with transition rules.**

```
Level 0 (Basic) → Level 1 (Standard) → Level 2 (Verified) → Level 3 (Trusted)
```

| Level | Requirement | Unlocks |
|---|---|---|
| 0 — Basic | Email or phone verification | Limited access |
| 1 — Standard | Selfie verification | Messaging and basic interactions |
| 2 — Verified | Government ID | Dating, monetization, higher-trust features |
| 3 — Trusted | Optional background check | High-trust badge, premium access credibility |

*Source: §1.2.* No explicit re-verification, expiration, or downgrade trigger is stated for this scheme. **This is one of at least four independently-named verification/tier schemes in the Blueprint that are never reconciled to each other — see the Trust entry below and PD-01/PD-15.**

## 8. Trust

**Type: Two independently-named progressions, plus a canonical scoring system, none explicitly cross-mapped.**

**A. Trust Progression System** (§1.3.2 — explicit numbered stages):

```
1. Basic Trust → 2. Community Trust → 3. Relationship Trust → 4. Creator Trust → 5. High-Trust Participation → 6. Luxe Trust Eligibility
```

Progression factors: Verification completion, Positive participation, Consistency, Community reputation, Safety history, Platform compliance — no numeric weights given (**Engineering Gap EG-02**).

**B. Trust Level Classification** (§9.2.2 — a parallel, differently-named scheme):

```
Unverified → Partially Verified → Verified → High-Trust / Trusted → Restricted / Flagged
```

*This is the "third scheme" Product Decision PD-01 names in the four-way naming conflict — never reconciled in-text to (A) above.*

**C. Canonical Trust Score** (§1.3 — the single explicitly-declared canonical number): *"[Canonical definition. Sections 9.22 and 22.18 consume this score rather than redefining it.]"* Rises/falls based on message behavior patterns, report history, block frequency, ghosting patterns, response behavior, verification level — **no numeric scale, per-signal weights, or thresholds given anywhere (EG-02, Critical).**

## 9. Safety (Enforcement Escalation)

**Type: Two explicit, ordered escalation ladders — one general-purpose (canonical), one behavior-correction-specific — plus one crisis-response framework with no defined stages.**

**A. Canonical Enforcement Ladder** (§22.25 — confirmed by Product Decision PD-21 as the single mechanism Sections 1.6 and 9.5.4.1 should reference):

```
Warning → Restriction → Suspension → Ban
```

*No per-stage trigger conditions, durations, or reversal/appeal mechanics are specified within §22.25 itself.* Appeals are handled generically at §22.26 without linking back to specific ladder stages.

**B. Graduated Behavioral Correction** (§9.5.4.1 — a softer, pre-ladder sequence):

```
Educational prompts → Boundary clarification warnings → Temporary interaction slowdowns → Visibility reductions → Guided behavioral correction → [escalates into (A) above]
```

*Explicit bypass clause: "Severe violations involving exploitation, predatory behavior, threats, or repeated abuse may bypass soft intervention systems entirely."*

**C. Crisis Signal Detection & Response** (§9.8.1/§9.8.2, restated at §14.6, §15.9.1, §22.16 — **no defined states or thresholds at all**, only named signal categories: Severe Distress Language Patterns, Self-Harm Indicators, Emotional Breakdown Signals, Behavioral Withdrawal Or Escalation). This is the Blueprint's single largest unresolved state-machine gap — **Product Decision PD-12 / Engineering Gap EG-06**, restated identically in four places with no cross-reference tying them together.

**Underlying safety feedback loop** (§9.23.2 — a continuous, cyclical process, not a linear escalation):

```
1. User Behavior → 2. System Analysis → 3. Risk And Trust Update → 4. Permission Adjustment → 5. System Learning And Adaptation → (repeats)
```

## 10. Connection (Match Lifecycle)

**Type: The Blueprint's most explicitly-framed state machine, with a named support for reverse transitions.** *"The Match Lifecycle System defines the full progression of a connection within Trulura, from initial discovery to potential long-term interaction or disengagement... Trulura structures connections as evolving states with clear transitions."* (§6.9)

**A. Defined Connection Stages** (§6.9.1):

```
Initial connection → Active interaction → Deepening connection → Transition or resolution
```

**B. Interaction State Transitions** (§6.9.2): *"State changes are behavior-driven... Engagement consistency, Communication depth, Mutual interaction signals"* trigger forward movement. ***"The system also supports reverse transitions"*** — the one explicit statement anywhere in the Blueprint's state machines that regression is a first-class, designed behavior, not an error state.

**C. Spark Progression** (§6.14.12 — a parallel six-stage sequence, explicitly reframed as a consuming pathway of the canonical §18.3 Progression System):

```
1. Initial Interest → 2. Mutual Spark → 3. Active Conversation → 4. Compatibility Exploration → 5. Real-World Transition → 6. Relationship Building
```

**D. Structured Escalation Stages** (§6.3, the Effort-Gated Escalation System — a coarser-grained version of (C)):

```
Initial Engagement → Early Communication → Deep Interaction → Private Environments
```

*No scoring formula exists for what moves a connection from one stage to the next in (C) or (D) — Engineering Gap EG-09, "Core Spark pacing/gating mechanism has no scoring formula," the single most load-bearing gap across Section 6.*

**E. Auto-Pause** (§6.5.1, §6.14.3): *"When a conversation becomes inactive beyond a defined threshold, the system automatically transitions it into a paused state."* No threshold value given. Auto-pause is explicitly framed as a substitute for ghosting, not a penalty.

**F. Match Exit / Disengagement** (§6.10): Mutual disengagement, one-sided exit, and system-triggered disengagement are named as three distinct terminal-state pathways, each with its own support tooling (§6.10.1 Respectful Disengagement Tools, §6.10.2 Closure & Reflection System).

*No field-level schema exists for the Connection object or its stage history anywhere in the Blueprint — Engineering Gap EG-13, the canonical home of which is §6.9 ("Match Lifecycle & Connection States").*

## 11. Progression (Multi-Dimensional Progression System)

**Type: Explicitly NOT a single linear ladder — the canonical system (§18.3) is framed as independent axes.**

**Progression Dimensions** (§18.3.1 — parallel, independent axes a user advances on unevenly):

Social Fluency, Trust Maturity, Emotional Stability, Relationship Depth, Creator Development, Platform Familiarity

**Growth Pathways** (§18.3.3 — 8 named, independent pathways):

Personal Growth, Friendship Development, Relationship Development, Creator Development, Community Participation, Wellness & Recovery, Travel Experiences, Leadership & Mentorship

**Confirmed consuming pathways** (per Engineering Gap EG-11's resolution note — these are domain-specific labels applied to §18.3's canonical dimensions, not separate mechanisms): §4.18.4 Community Progression (Member → Contributor → Trusted Member → Community Leader → Mentor → Ambassador), §6.14.12 Spark Progression (see Connection above), §13.10.2 Creator Progression (see Creator above).

**Relationship Development sub-pathway** (§18.8, presented as one linear sequence but explicitly marked reversible — §18.8.1: *"fully optional and reversible"*):

```
Discovery → Early Interaction → Trust Building → Emotional Engagement → Deep Connection
```

**Lifecycle phases** (§18.9, a coarser life-stage framing, parallel to but not cross-referenced against §25.17 below):

```
Onboarding → Exploration → Active Participation → Selective Engagement → Creator Expansion → Intermittent Use
```

*One remaining gap after EG-11's partial resolution: no numeric advancement criteria exist for any of §18.3's dimensions or pathways.*

## 12. Journey (UX Journey / Long-Term User Evolution)

**Type: Two independently-stated, near-identical long-term progressions, not cross-referenced to each other or to Section 18's Progression system.**

**A. Long-Term User Evolution & Lifecycle Mapping** (§25.17):

```
New user → Explorer → Connector → Relationship builder → Creator / Community role
```

**B. Life Stage & Identity Evolution Framework** (§25.17.1 — parallel, not necessarily sequential):

Exploration, Friendship, Dating, Relationships, Parenting, Community Leadership, Creator Development, Healing & Recovery

**C. Rituals, Milestones & Progression Framework** (§25.17.2 — near-identical to §18.3.3's Growth Pathways list, uncited between the two, flagged as a possible additional occurrence of the same content-duplication pattern EG-11 already tracks for the Progression system specifically):

Personal Growth, Friendships, Romantic Relationships, Community Participation, Creator Development, Healing & Recovery, Travel & Experiences, Leadership & Mentorship

**Onboarding sequence** (§25.2 — 4 named steps, no ordering or friction rules given, Engineering Gap EG-30):

```
Account creation & verification → Mood + intent selection → Profile setup → Preference controls
```

**Drop-Off / Re-Engagement flow** (§25.13 — the Journey system's own recovery loop, no threshold given, also EG-30):

```
Detect inactivity → Reduce pressure → Offer gentle re-entry points
```

**MoodSync dependency**: *"All user journeys within Trulura are influenced by the MoodSync Operating System"* (§25.1.1) — the Journey system's states are themselves shaped by, but not identical to, the Mood/Recovery states covered above.

## Other State Sets Found (Not Among the 12 Named Systems, Included for Completeness)

| System | States | Type | Source |
|---|---|---|---|
| Space State (Social Ecosystem) | Open, Restricted, Private, Event-Based, Premium | Parallel — no transition rules stated | §19.13.2 |
| Feed Mode | Immersive, Interactive, Guided, Soft | Parallel, user-switchable | §20.12.1 |
| Deployment Environment | Development → Testing → Staging → Production | Linear pipeline (infrastructure, not user-facing) | §23.12 |
| Orchestration Pipeline Outcomes | Continue execution / Modify behavior / Redirect system path / Halt execution (safety override) | Per-request decision, not a persistent state | §19.3.2 |

## Not Yet Defined

- Numeric thresholds, durations, or trigger conditions for the overwhelming majority of transitions cataloged above — each system above independently restates the pattern the Engineering Gap Register tracks per-domain (EG-02 for Trust, EG-06 for Safety/Crisis, EG-09/EG-13 for Connection, EG-10 for temporary Mode states, EG-11 for Progression, EG-30 for Journey/Onboarding).
- Whether Section 1.1.4's Identity States, Section 2/3's Modes, and Section 10.1's Active State are the same underlying state axis (PD-10).
- Whether the Creator's three named progressions (Progression & Mentorship, Revenue Tier Framework, Journey Phases) are meant to move in lockstep or are genuinely independent.
- Whether Section 25.17's Journey progressions and Section 18.3's canonical Progression System are the same mechanism under different names, given their near-identical Growth-Pathway/Progression-Dimension lists.
- A crisis-detection state machine of any kind (PD-12/EG-06) — the Blueprint names trigger signal categories in four places but defines no states, thresholds, or transitions for crisis response itself.

## Cross-References

`docs/03-Architecture/TruLura_Blueprint_Cross_Reference.md` (source of every citation above) · `docs/02-Product/Glossary.md` (term definitions for every named state) · `docs/02-Product/TruLura_Engineering-Gap-Register.md.md` (EG-02, EG-06, EG-09, EG-10, EG-11, EG-13, EG-30) · `docs/02-Product/TruLura_Product-Decisions.md.md` (PD-01, PD-10, PD-12, PD-15, PD-21) · `docs/03-Architecture/TruLura_Domain_Model.md`.
