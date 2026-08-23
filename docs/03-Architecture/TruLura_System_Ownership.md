# TruLura Canonical System Ownership

*Format: Owns / Consumes / Produces / Never Owns, per system rather than per section number — several systems span or consolidate multiple Blueprint sections (e.g., Monetization spans Sections 7 and 8; Progression consolidates 4.18.4/6.14.12/13.10.2 under 18.3). Only relationships explicitly documented in the Blueprint are listed. Where "Produces" isn't explicitly named in the Blueprint text, it's inferred from the system's stated outputs and marked accordingly.*

---

## Identity & Trust (Section 1)
**Owns:** Master Profile ID, Verification Levels, Trust & Behavior Score (canonical), Identity States, Emotional Identity Infrastructure, Anonymous Overlay System (named, unspecified).
**Consumes:** Nothing (most upstream section).
**Produces:** Verification status, trust score, identity state — consumed by nearly every gated feature Blueprint-wide.
**Never Owns:** *(not explicitly stated in Blueprint text — no negative-ownership declaration exists for Section 1, unlike Sections 7, 9, 14–18, 25.)*

---

## Experience Modes (Sections 2/3)
**Owns:** Mode Layer, mode activation/transition logic, per-mode behavioral rules, content classification/tagging.
**Consumes:** Discovery (Section 4), Safety (Section 9), Monetization (Section 7), AI Intelligence (Section 11), Governance (Sections 22/24).
**Produces:** Active mode / participation context — consumed by Discovery, Matchmaking, Monetization, Navigation (Active State, Section 10, confirmed equivalent).
**Never Owns:** *(not explicitly stated — no negative-ownership list found for Section 2/3.)*

---

## Discovery / Feed (Section 4)
**Owns:** Feed ranking, discovery algorithms, content distribution, visibility optimization, recommendation systems.
**Consumes:** Identity/Trust (Section 1, safety layer), Experience Modes (Section 2/3), AI Intelligence (Section 11), MoodSync (Section 12), Monetization (Section 7/8, influence layer).
**Produces:** Ranked feed content, discovery surfacing — consumed by Matchmaking (Section 6) and Creator Platform (Section 13).
**Never Owns:** *(not explicitly stated.)*

---

## Profile System (Section 5)
**Owns:** Core Profile Framework, Adaptive Profile Logic, Attraction Mapping, Profile Data Architecture.
**Consumes:** Identity/Trust (Section 1), Experience Modes (Section 2/3, drives rendering).
**Produces:** Profile signals feeding Discovery (explicit, 5.3.1) and Matchmaking compatibility (Section 6).
**Never Owns:** *(not explicitly stated.)*

---

## Matchmaking (Section 6)
**Owns:** Effort-Gated Escalation, Match Discovery Flow, Match Lifecycle/Connection States, Spark Progression pathway (domain-specific under Section 18.3).
**Consumes:** Identity/Trust (Section 1), Experience Modes (Section 2/3, Romantic Mode gates entry), Profile (Section 5, Attraction Mapping).
**Produces:** Match/connection state — consumed by Discovery surfacing (4.16), Monetization (Spark stages), TruTravel, TruLuxe.
**Never Owns:** *(no explicit negative-ownership declaration — Section 6 has no "System Boundaries" subsection.)*

---

## Monetization & Creator Economy (Sections 7/8)
**Owns:** Trulura Coin System, Gifting Economy, Subscription Systems, Economic Governance, Financial Safety.
**Consumes:** Mood States (Section 12), Creator Wellness (Section 13/18), Progression Systems (Section 18), Journey Routing (Section 25), Interface Rendering (Section 20) — all explicitly named as *inputs the system does not own*.
**Produces:** Monetization eligibility/state — consumed by Experience Modes (2.5) and Creator Platform (13.12).
**Never Owns (explicit):** Mood States, Creator Wellness, Progression Systems, Journey Routing, Interface Rendering.

---

## Safety, Trust, Privacy & Compliance (Section 9)
**Owns:** Behavioral Monitoring & Moderation, AuraShield (Red Flag Detection), Anti-Harassment Systems, Crisis Detection framework (mechanism unspecified), Dispute Resolution.
**Consumes:** Identity/Trust (Section 1.3, canonical Trust Score — 9.22 is a documented consumer, not a redefinition).
**Produces:** Moderation actions and safety outcomes — consumed by Experience Modes (2.4) and Navigation (Restriction Triggers, Section 10).
**Never Owns:** *(no explicit negative-ownership declaration — Section 9 has no "System Boundaries" subsection.)*

---

## Navigation & Session State (Section 10)
**Owns:** Active/Passive/Restricted state model, Restriction Triggers, Permission Factors (10.5.1), Primary/Secondary Navigation structure *(currently in direct conflict with Section 20's separately-declared navigation — unresolved, PD-14)*.
**Consumes:** Identity/Trust (Section 1), Experience Modes (Section 2/3, Active State = Mode, confirmed), Safety (Section 9, moderation feeds Restriction Triggers), MoodSync (Section 12, synchronization effects).
**Produces:** Session/access state — consumed Blueprint-wide by any mode- or state-gated UI.
**Never Owns:** *(not explicitly stated.)*

---

## AI Intelligence (Section 11)
**Owns:** AI decision-making authority for mode recommendations, feed ranking signals, compatibility intelligence, monetization-timing influence (constrained).
**Consumes:** MoodSync (Section 12) — explicit: "Section 11 consumes emotional intelligence signals generated by MoodSync but does not own or define those systems."
**Produces:** Recommendation/decision outputs — consumed by Experience Modes, Discovery, Matchmaking, Monetization (timing only).
**Never Owns (explicit):** Emotional intelligence / MoodSync's underlying systems.

---

## MoodSync — Emotional State System (Section 12)
**Owns:** Emotional States, Emotional Readiness, Social Battery, Atmosphere States, Recovery States, Context Routing.
**Consumes:** Nothing (most upstream emotional-intelligence section).
**Produces:** Emotional state / mood signal — consumed by AI (11), Creator Platform (13), Vent Space (14), AI Companion (15), Interface (20), Security (22), Journey (25). **Highest-fan-out production relationship in the Blueprint.**
**Never Owns (explicit, per 12.11):** Does not diagnose mental health conditions, does not manipulate emotional states, does not force behavior changes, does not replace real emotional support systems.

---

## Creator Platform / TruStudio (Section 13)
**Owns:** Creator Identity, Creator Tools, Creator Wellness, Creator Communities, Creator Trust, Creator Sustainability.
**Consumes:** Monetization (Section 7), AI (Section 11), MoodSync (Section 12, "dynamically influenced by"), Interface (Section 20), Journey (Section 25).
**Produces:** Creator-side monetization eligibility and progression state — consumed by TruTravel (16.14 explicit dependency).
**Never Owns (explicit):** Exploitative engagement tactics, outrage/controversy rewards, uncontrolled monetization pressure, creator priority over user safety (stated as boundaries, not as owned-elsewhere systems — Section 13 is unusual in framing its "does not" list as prohibited behaviors rather than systems owned by other sections).

---

## Vent Space & Emotional Support (Section 14)
**Owns:** Vent Space, Healing Pathways, Recovery Support, Healing Circles, Reflection Systems, Reintegration Support, Recovery Recognition.
**Consumes:** AI (Section 11), MoodSync (Section 12, "dynamically influenced by"), Interface Rendering (Section 20), Journey Systems (Section 25).
**Produces:** Vent/support session state — not explicitly consumed elsewhere per the Blueprint's text (deliberately isolated, consistent with 14.13's non-viral, non-monetized boundary).
**Never Owns (explicit):** Recovery States, MoodSync Intelligence, Interface Rendering, Journey Routing.

---

## AI Companion (Section 15)
**Owns:** Companion behavior, tone, memory, support routing, user controls, relationship guidance.
**Consumes:** Discovery *(likely a mislabeled citation for Section 4 — see Cross-Reference Index)*, Monetization (Section 7), MoodSync (Section 12), Spark (dating flow), Creator system (events/experiences).
**Produces:** Companion guidance/support output — consumed within Spark and Creator contexts per the in-text "connects to" list.
**Never Owns (explicit):** Core AI infrastructure, Mood states, Clinical support, Interface rendering, Journey routing.

---

## TruTravel (Section 16)
**Owns:** Travel Experiences, Real-World Experiences, Travel Matching, Group Travel, Experience Safety, Travel Memories, Experience Continuity.
**Consumes:** AI (Section 11), MoodSync (Section 12), Creator Platform (Section 13), Interface (Section 20), Journey (Section 25).
**Produces:** Travel/experience state — no other section explicitly cites consuming this.
**Never Owns (explicit):** Mood States, Trust Scores, Interface Rendering, Journey Routing, Creator Monetization.

---

## TruLuxe (Section 17)
**Owns:** TruLuxe Access, Qualification, Experiences, Networking, Privacy Controls, Concierge Systems, Verification (TruLuxe-specific).
**Consumes:** Monetization (Section 7, alignment stated), AI (Section 11), MoodSync (Section 12, "dynamically influenced by"), AI Companion (Section 15), TruTravel (Section 16), Interface (Section 20), Journey (Section 25).
**Produces:** TruLuxe access/qualification state — no other section explicitly cites consuming this.
**Never Owns (explicit):** Mood States, Core Trust Scoring, Interface Rendering, Creator Monetization, Journey Routing.

---

## Progression System (Section 18, canonical for progression Blueprint-wide)
**Owns:** Multi-Dimensional Progression System (18.3 — dimensions, pathways, expression), Recognition, Achievement, Ritual, Participation, Legacy Systems.
**Consumes:** AI (Section 11), MoodSync (Section 12), Creator Platform (Section 13), Vent Space (Section 14), Interface (Section 20), Journey (Section 25).
**Produces:** Progression state, consumed by Community pathway (4.18.4), Spark pathway (6.14.12), Creator pathway (13.10.2) — all explicit in-text pointers to Section 18.3 as canonical.
**Never Owns (explicit):** Mood States, Recovery States, Interface Rendering, Journey Routing.

---

## Orchestration (Section 19.1–19.10)
**Owns:** System Hierarchy / execution priority (19.1.1: Safety & Consent → State & Mode Logic → AI Interpretation → Experience Systems), Event-Driven Architecture, Conflict Resolution Framework.
**Consumes:** Nothing named explicitly — sits structurally above other systems as a sequencing layer.
**Produces:** Execution/conflict-resolution ordering — implicitly governs every other section's runtime behavior, though this isn't stated as a formal "consumed by" relationship anywhere.
**Never Owns:** *(not explicitly stated — and the section's dual nature with Social Ecosystem below means this boundary is itself undocumented.)*

## Social Ecosystem / Community Worlds (Section 19.11–19.23, canonical per merge)
**Owns:** Core Space Types, Space Discovery & Matching, Space Governance, AI-Driven Community Formation.
**Consumes:** MoodSync (Section 12), AI (Section 11), Spark/Matchmaking (Section 6), Monetization (Section 7), TruTravel (Section 16).
**Produces:** Community/space membership state — not explicitly consumed elsewhere in-text.
**Never Owns:** *(not explicitly stated.)*

---

## Interface Systems (Section 20)
**Owns:** Adaptive UI philosophy, Atmosphere Rendering, Interface Personality, Accessibility Intelligence Framework, Primary/Secondary Navigation structure *(conflicts with Section 10 — PD-14, unresolved)*.
**Consumes:** MoodSync (Section 12) — inferred from Section 12's own citation of Section 20 as a consumer; Section 20 does not reciprocally state this.
**Produces:** Rendered UI/theming state — consumed (per their own explicit citations) by Sections 11, 12, 13, 14, 15, 16, 17, 18, 19. **The single highest-fan-out "consumed by" relationship in the Blueprint, despite Section 20 itself having no formal Dependencies subsection.**
**Never Owns:** *(not explicitly stated — this absence is itself flagged as a documentation gap given how central this section is.)*

---

## Integrations (Section 21)
**Owns:** Modular Connection Framework, external payment/identity integrations, Internal/External Boundary Rule (external systems never control platform decisions).
**Consumes:** Nothing explicitly named.
**Produces:** Vendor connectivity — implicitly required by Section 1.2 (verification) and Section 7/8 (payments), not explicitly cited by either.
**Never Owns:** *(explicit in spirit via 21.16's boundary rule — external systems never control decisions, though this isn't phrased as a "never owns" list.)*

---

## Security, Privacy, Compliance (Section 22, canonical for data security per merge)
**Owns:** Zero-Trust Model, Data Protection & Encryption, Data Minimization & Purpose Limitation, Multi-Layer Enforcement System (22.25 escalation ladder), Adaptive Trust Scoring (22.18, consumer relationship).
**Consumes:** Identity/Trust (Section 1.3, Trust Score, via 22.18's consumer relationship).
**Produces:** Enforcement/escalation decisions — recommended (not yet executed in-text) as the reference point for Sections 1.6 and 9.5.4.1.
**Never Owns:** *(not explicitly stated — Section 22 has no formal negative-ownership list, despite being canonical for a system many other sections touch.)*

---

## Infrastructure (Section 23)
**Owns:** Auto-scaling philosophy, caching strategy (unspecified numerics), system throttling, global scaling/regional adaptation.
**Consumes:** Nothing — deliberately stack-agnostic by design, appropriate for a product blueprint.
**Produces:** Platform-wide performance/availability substrate — implicitly required by every section, not explicitly cited by any.
**Never Owns:** *(not applicable — this section is intentionally generic.)*

---

## Governance (Section 24)
**Owns:** Rule Framework, Role-Based Access & Permission Hierarchies (staff/admin, distinct from user verification tiers), System Override & Emergency Control, Anti-Manipulation Systems.
**Consumes:** Nothing explicitly named (recommended, not yet executed: Section 22's enforcement ladder and Section 19.1.1's orchestration priority).
**Produces:** Governance outcomes — consumed by Experience Modes (explicit, 2.12: "Section 22 and Section 24 own" governance outcomes Section 2 consumes).
**Never Owns:** *(not explicitly stated.)*

---

## Journey Systems / UX Flow (Section 25)
**Owns:** Onboarding Flow, Journey Mapping, Drop-Off Prevention, Friction Design, Multi-Path User Journeys, UX/AI/Governance alignment (25.19).
**Consumes:** AI (Section 11), MoodSync (Section 12), Interface (Section 20).
**Produces:** Journey/flow state — consumed by Creator Platform, Vent Space, TruTravel, TruLuxe, Progression System (all explicitly cite Section 25 as a dependency).
**Never Owns (explicit):** Emotional States, Atmosphere States, Social Battery States, Recovery States, Interface Rendering.

---

## Future Expansion / Roadmap (Section 26)
**Owns:** The Phase 1/2/3/4 rollout roadmap (26.16) — the sole source every other section's Phase classification traces back to.
**Consumes:** Nothing.
**Produces:** Phase classification — consumed indirectly by all 25 other sections' Beta Classification.
**Never Owns:** Not applicable — this section owns planning/sequencing only, never product mechanics themselves.

---

## Cross-Cutting Observation

Three systems in this document have an unusually short **"Never Owns"** list relative to how central they are: **Section 1 (Identity/Trust)**, **Section 9 (Safety)**, and **Section 20 (Interface)** each lack any explicit negative-ownership declaration, despite being among the most depended-upon systems in the Blueprint. Every other heavily-depended-upon system (7, 12, 13, 14, 15, 16, 17, 18, 25) has a clear "does not own" list. This asymmetry is worth flagging as a documentation priority: the systems most likely to accumulate scope creep or duplicated logic are exactly the ones without an explicit boundary statement.
