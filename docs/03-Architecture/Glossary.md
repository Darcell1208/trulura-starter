# TruLura Glossary

*One authoritative definition per term, drawn directly from the Blueprint's own text. Where the Blueprint uses a term without ever formally defining it, that's noted rather than filled in. Where the same concept appears under more than one name across the Blueprint (a known, still-open issue — see PD-01, PD-10), both names are cross-referenced rather than merged, since resolving that naming conflict is a Product Decision, not a documentation task.*

---

### Active State
The current mode or participation context governing a user's experience at the session level (Section 10.2). **Confirmed equivalent to Mode** (see *Mode*) — this equivalence was established by cross-reading Sections 2/3 and 10, since the Blueprint doesn't state it explicitly in either section's own text.

### AI Companion
Trulura's support/guidance AI layer (Section 15) — "supports, guides, reflects, enhances awareness." Explicitly does **not**: replace real human relationships, provide medical/psychological diagnoses, act as a therapist or authority figure, or make decisions for the user (15.13).

### Anonymous Overlay System
A component named in Section 1.1 as part of the Identity Core but never defined anywhere else in the Blueprint. No mechanism, behavior, or restrictions are specified — logged as an open Engineering Gap (EG-19), not a defined term.

### Atmosphere State
One of the six things Section 12 (MoodSync) explicitly owns, alongside Emotional States, Emotional Readiness, Social Battery, Recovery States, and Context Routing. The Blueprint does not further define what specifically constitutes an Atmosphere State beyond naming it as an owned output of MoodSync.

### Aura
TruLura's mood/energy-presentation system, referenced throughout the Blueprint (feed personality, profile theming, discovery filtering) but never given a single formal definition subsection of its own — it functions as the umbrella visual/behavioral expression of a user's current emotional state, as interpreted by MoodSync (Section 12) and rendered through Interface Systems (Section 20).

### AuraShield
The named red-flag detection component of Section 9 (Safety, Trust, Privacy & Compliance) — "AuraShield (9.7)." Powers feed visibility scoring (unsafe tone reduces reach), mood-based content warnings, and Teen/Kid-specific filtering (Lite Mode), per Section 1's reference to AuraShield tagging profile access levels.

### Community Worlds / Social Ecosystem
Canonical definition lives in Section 19.11–19.23 (per the modernization project's executed merge — Section 4.18 now points here as a pointer, with its specific example-World list preserved and folded in). Covers Core Space Types, Space Discovery & Matching, Space Governance, and AI-Driven Community Formation.

### Connection States
See *Match Lifecycle*.

### Context Routing
One of the six things Section 12 (MoodSync) explicitly owns. Not independently defined beyond being named as an owned MoodSync output — presumably governs how emotional/mood signals get routed to consuming systems, but the Blueprint does not specify the routing mechanism itself.

### Creator Identity
Referenced within Section 13 (Creator Platform & TruStudio) as part of what Section 13 owns, alongside Creator Tools, Creator Wellness, Creator Communities, Creator Trust, and Creator Sustainability. Not given an independent definition subsection distinguishing it from general Identity (Section 1).

### Effort-Gated Escalation
Section 6's core pacing/gating mechanism for matchmaking interaction depth (6.3) — gates conversation and interaction progression based on demonstrated effort rather than time or swipe volume. No scoring formula is defined (EG-09).

### Emotional Identity
Defined in Section 1.1.2 as the Emotional Identity Infrastructure — governs how users express, communicate, and participate through emotional patterns, energy states, and behavioral tendencies. Distinct from Emotional State (see below): Emotional Identity is the more stable, trait-level layer ("who you generally are, emotionally"), while Emotional State (MoodSync, Section 12) is the real-time layer ("how you feel right now"). The Blueprint does not explicitly draw this distinction in its own text — it's inferred from the two sections' separate content and ownership.

### Emotional Readiness
One of the six things Section 12 (MoodSync) explicitly owns. Not independently defined beyond being named as an owned output.

### Emotional State
See *MoodSync*. The real-time layer of a user's mood, owned exclusively by Section 12.

### Feed Layer Priority
Section 4's six-layer feed architecture concept (Trust & Safety, Mode, Emotional Intelligence, Relevance, Visibility, Monetization) — the layers themselves are named (4.2.1–4.2.6), but the priority/resolution rule between them when layers conflict is not defined (EG-04, the single highest-priority Engineering Gap tied to Discovery).

### Glow
One of Trulura's core Experience Modes (Section 3) — friendship/platonic connection, distinct from Spark (romantic). Named directly as Core Beta in Section 26.16.1. The Blueprint does not define Glow as deriving from or being built on Aura — that relationship, if it exists, is not stated in the current Blueprint text.

### Master Profile ID
Defined in Section 1.1 as the "global identity anchor" — the platform's central identity reference. No data schema or field-level structure is defined in the Blueprint itself (EG-03).

### Match Lifecycle / Connection States
Owned by Section 6 (6.9) — the staged progression of a match from initial connection through ongoing interaction. Named conceptually; no defined transition triggers or minimum time-in-stage (per the modernization project's gap analysis).

### Mode
The Experience Modes / Participation Context framework (Sections 2/3) — Social, Friendship, Romantic (Spark), Vent, Creator, Youth, and Specialized (Travel/Events/Luxe) modes. **Confirmed equivalent to Active State** (Section 10.2). A separate, still-unresolved question is whether Section 1.1.4's "Identity States" (Social, Relationship, Creator, Community, Anonymous, Healing, Travel, Luxe) are a third naming of this same concept (PD-10) — not resolved by this glossary, since the Blueprint itself never states the relationship.

### MoodSync
The formal name for Section 12 (TruLura Mood & Emotional State System) — TruLura's real-time emotional-intelligence layer. Owns Emotional States, Emotional Readiness, Social Battery, Atmosphere States, Recovery States, and Context Routing (12.11.1). Explicitly does **not** diagnose mental health conditions, manipulate emotional states, force behavior changes, or replace real emotional support systems (12.11). The single highest-fan-out system in the Blueprint — consumed by Sections 11, 13, 14, 15, 20, 22, and 25.

### Permission Factors
Named in Section 10.5.1 as the inputs to permission resolution: Current Mode, Trust Level, Emotional State, Verification Status, Environment Context. The actual resolution logic combining these into one access decision is not defined — this is the Blueprint's single most-referenced open Engineering Gap (EG-01), touching Sections 1, 2/3, 6, 9, 10, and 19.

### Recovery State
One of the six things Section 12 (MoodSync) explicitly owns. Referenced by name across multiple sections (Vent Space, Progression System) as something they explicitly do *not* own — Recovery State stays exclusively with MoodSync.

### Restriction Triggers
Owned by Section 10 (10.2.2) — categories that can move a user into a Restricted session state: age/verification changes, trust score changes, moderation actions, user preference. No numeric threshold values are defined for any category.

### Social Battery
One of the six things Section 12 (MoodSync) explicitly owns — a metaphor for a user's current capacity for social interaction. No numeric depletion/recovery rate is defined in the Blueprint (Engineering Gap, tracked under MoodSync's broader "signal set undefined" gap, EG-05).

### Spark
One of Trulura's core Experience Modes (Section 3) — romantic/dating connection. Named directly as Core Beta in Section 26.16.1, with "Advanced Spark Features" (Matchrooms, guided dating flows, compatibility layers) named as Phase 2 (26.16.2). The exact subsection-level split between base and advanced Spark is not stated in the Blueprint text (PD-06). Also referenced in Section 10.9.1's navigation tab list under the label "Sync" — whether this is the same system under two names or a naming error is unresolved (PD-08).

### Trust Score
The canonical private trust-scoring system, owned by Section 1.3 (Trust & Behavior Scoring System — Full Logic). Per the modernization project's executed canonical merge, Sections 9.22 (Behavioral Reputation) and 22.18 (Adaptive Trust Scoring) are documented *consumers* of this one score, not independent redefinitions. No numeric scale, per-signal weighting, or feature-gating threshold values are defined in the Blueprint text (EG-02). A related but still-unresolved naming question: Sections 2.1.2, 9.2.1/9.2.2, and 16.5 each independently name their own verification/trust tier schemes that may or may not be the same underlying concept under different names (PD-01) — not resolved here.

### TruJourney
Referenced across multiple sections (Matchmaking, TruTravel, TruLuxe dependency lists) as the post-match/relationship-growth experience, though the Blueprint does not contain a dedicated numbered section defining it as its own system — it appears as a named concept within Section 6 and as a cross-referenced dependency elsewhere, without an independent "TruJourney owns / does not own" declaration.

### TruLuxe
Section 17's formal name — the Elite Experience & High-Value Network System. Explicitly **is**: a trust-based ecosystem, a privacy-first environment, a high-quality interaction layer. Explicitly **is not**: a status-symbol system, a sugar-only platform, or a pay-for-access model to other users (17.14). Does not allow users to pay for access to other individuals — monetization applies only to environment access. Phase 2, explicit (26.16.2).

### TruStudio
The Creator Platform's tool/dashboard component, referenced within Section 13 (TruLura Creator Platform & TruStudio System). Named as Core Beta for "early monetization" specifically (26.16.1) — the rest of Section 13's content (Sustainability Framework, Mentorship Framework) is not confirmed for the same phase.

### TruTravel
Section 16's formal name — the Travel & Real-World Experience System. Explicitly **is not**: a replacement for Airbnb, a random meetup platform, or a dating-first travel system. Explicitly **is**: a structured, safety-first experience layer, a connection-driven travel system, a real-world extension of Trulura (16.13). Phase 2, explicit (26.16.2).

### Verification Levels
Section 1.2's four-tier framework: Level 0 (Basic — email/phone only, limited access), Level 1 (Standard — selfie verification, messaging + basic features), Level 2 (Verified — ID upload, dating + monetization access), Level 3 (Trusted — optional background check, high-trust badge). This is the Blueprint's canonical verification scheme, though Sections 2.1.2, 9.2.1/9.2.2, and 16.5 each separately reference what may be the same or a different tier system (PD-01, unresolved — four-way naming conflict).

### Vent Space
Section 14's formal name — the Emotional Support System. Explicitly **is not**: a replacement for therapy or professional care, a public content platform, a venue for viral exposure of emotional content, or a means of monetizing vulnerability. Explicitly **is**: a safe, structured environment for emotional expression that integrates with the broader emotional system of Trulura (14.13). Named directly as Core Beta in Section 26.16.1. Does not own Recovery States, MoodSync Intelligence, Interface Rendering, or Journey Routing (14.14) — all of those stay with their respective owning sections.

---

## Terms Used But Not Formally Defined in the Blueprint

These appear in the Blueprint's text but have no dedicated definition subsection — listed here rather than silently defined, per the instruction not to invent:

- **Safety Score** — appears once, in Section 16.5, as "safety score (internal)" for TruTravel eligibility. Never defined as its own system; its relationship to the canonical Trust Score (Section 1.3) is unresolved (part of PD-01).
- **Creator Trust** — named as something Section 13 owns, never independently defined apart from the canonical Trust Score.
- **Sync** — the label used for the dating/matchmaking tab in Section 10.9.1's navigation list, while every other section calls the same system "Spark." Not resolved as a synonym or an error (PD-08).
