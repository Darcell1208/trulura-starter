# TruLura Glossary

*Every term the TruLura Blueprint formally introduces with a definition — one authoritative entry per term, alphabetical, cited to its source subsection. Built from the "Defined Terms" flagged lists compiled while producing `docs/03-Architecture/TruLura_Blueprint_Cross_Reference.md` (see that document for full section-by-section extraction). Where the Blueprint defines the same or a similarly-named term in more than one place with different meanings, both definitions are given and the conflict is flagged rather than silently resolved — per the Product Knowledge System's rule that engineering does not invent product decisions, a naming conflict is reported, not settled, here. Terms already tracked as open naming conflicts in the Product Decisions Register (PD-01/PD-08/PD-09/PD-10/PD-15) are cross-referenced rather than re-litigated.*

## How to read this document

Each entry gives the term, its Blueprint-stated definition (quoted or closely paraphrased), the subsection that defines it, and — where relevant — a **Conflict/Alias** note. This glossary does not invent definitions for terms that are named but never defined in the source text; those are listed under **Named But Not Defined** at the end.

---

## A

**Active State** — One of three participation-state categories: "the mode or participation context currently governing the user's experience." Distinguished from Passive State (background, non-controlling) and Restricted State (currently unavailable). *Source: §10.2.* **Conflict/Alias**: Product Decisions register PD-10 asks whether this is a third naming of the same underlying concept as §1.1.4's Identity States and §2/3's Mode — not resolved in the Blueprint text.

**AI Companion** — "A personalized, adaptive intelligence layer... emotionally aware, behaviorally adaptive, and context-driven." The canonical specification lives in Section 15; Section 11.7.4 explicitly defers to it ("See Section 15 for the full canonical AI Companion specification"). *Source: §15.1.*

**AI Decision Engine** — "The core processing system that determines how the platform behaves in real time... functions as a rule-bound contextual interpreter rather than a simple recommendation algorithm." *Source: §11.3.*

**Anonymous Overlay System** — Named as a core component of Identity Core (alongside Master Profile ID, Mode-Based Identity States, Profile Type Assignment, Identity Layer Switching) but never further specified anywhere in Section 1. *Source: §1.1.* **Note**: Engineering Gap EG-19 — mechanism undefined; Section 9.3.3 and 9.18.1 reference "anonymous" identity concepts without specifying this system either.

**Atmosphere** — "The type of emotional environment a user currently seeks, benefits from, or naturally aligns with," explicitly distinct from Mood. *Source: §12.8.1.* Ten categories are named at §12.8.1: Healing, Creative, Playful, Supportive, Romantic, Luxury, Reflective, Social, Adventure, Wellness. **Conflict/Alias**: Section 20.13.3's "Atmosphere Rendering Framework" independently defines nine categories with one-line descriptions each (Healing, Creative, Playful, Supportive, Romantic, Luxury, Reflective, Adventure, Wellness) — omitting "Social" from Section 12's list of ten, with no cross-reference between the two sections reconciling the count. Section 25.3.1 reuses five of the nine (Healing, Creative, Romantic, Luxury, Adventure) as routing destinations, again uncited.

**Atmosphere Intelligence** — "Evaluates environmental compatibility between users, communities, creators, events, experiences, and platform environments... evaluates where a user is most likely to thrive." *Source: §11.2.4.*

**Attraction Code (Soul, Mind, Body)** — "Multi-dimensional compatibility model that evaluates emotional, intellectual, and physical alignment." *Source: §6.14.8, quiz-integration reference at §5.8/§5.9.*

**AuraShield** — "Trulura's advanced behavioral intelligence system designed to detect, interpret, and respond to high-risk interaction patterns... evaluates behavior over time rather than relying on isolated incidents." *Source: §9.7.*

**Aura** — Defined twice, with related but distinct meanings, and never cross-referenced between the two:
1. *(Identity layer, Profile System usage)* — "A more stable identity pattern... Aura evolves gradually and reflects deeper identity," paired with the more fluid concept of Mood. *Source: §5.6.3.*
2. *(Interaction-signal usage, Matchmaking)* — "A broader identity signal that influences how a user is perceived across the platform, shaping visibility, energy, and contextual interpretation." *Source: §6.13, "Spark, Glow & Aura Interaction Engine."*

Also used as a **feed environment name** ("Aura" tab/feed — "the social discovery environment centered on expression, community interaction, and everyday engagement," §4.18) and as a **navigation tab label** (§10.9.1's "Aura (Social Feed / Identity Layer)"). These uses are consistent in spirit across the document but are never explicitly tied together in the text.

## B

**Behavioral Balance Layer** — Trulura's system for "meaningful engagement without encouraging addictive usage patterns." *Source: §4.8.*

**Behavioral Intelligence Layer** — One of six named AI system layers: "Tracks user actions, interaction patterns, and engagement styles to identify habits and preferences." *Source: §11.2.1.*

## C

**Community Climate** — "Represents the overall health, tone, and participation quality of a community environment," with signals including Supportiveness, Participation quality, Conflict levels, Moderation activity, Member satisfaction, Retention patterns. *Source: §4.18.2* (a near-identical "Community Emotional Climate" also appears at §12.8.2, uncited between the two).

**Community Climate Intelligence** — "Evaluates the emotional health and participation quality of communities throughout the Trulura ecosystem." *Source: §11.2.7.*

**Community Worlds** — "Structured... purpose-driven environments centered around shared interests, identities, experiences, and goals." *Source: §4.18.1*, with an explicit editorial note deferring to §19 (Social Ecosystem) for the "full canonical Community Worlds specification." Example World names (Anime, Gaming, Creator, Parenting, Wellness, Travel, Faith, Neurodivergent, Healing, Luxury) appear at §4.18.1, and overlapping-but-not-identical lists reappear uncited at §20.2.3 and §25.14.1.

**Compatibility & Match Intelligence** — One of six named AI system layers: "Analyzes attraction patterns, personality, values, and behavioral consistency to support matchmaking systems." *Source: §11.2.1.*

**Content Intelligence Layer** — One of six named AI system layers: "Evaluates content type, tone, and relevance to influence feed ranking and discovery." *Source: §11.2.1.*

**Context Routing Engine** — "Operational core of the MoodSync system"; consumes Emotional State, Readiness, Social Battery, Atmosphere, Recovery State, Trust State, Participation History, and Preferences, and routes them into ten platform-area outputs. *Source: §12.8.5.*

**Contextual Intelligence Model** — "Combines multiple layers of information before determining system behavior," drawing on Emotional State, Emotional Readiness, Social Battery, Atmosphere State, Recovery State, Trust State, Participation History, User Intent, and Platform Context. *Source: §11.5.5.*

**Conversation Bandwidth Control System** — "Limits the number of active high-engagement conversations a user can maintain simultaneously within certain modes." *Source: §6.4.1.* See also Engineering Gap EG-10 (numeric caps undefined).

**Creator Identity** — Not independently defined as a standalone term; established through **Creator Types** (Lifestyle, Emotional, Entertainment, Educational, Premium/Experience Creators, §13.2) and **Creator Archetypes** (Educator, Storyteller, Entertainer, Community Builder, Mentor, Advocate, Wellness Creator, Lifestyle Creator, Experience Creator, Luxury Creator, §13.2.1).

**Creator Wellness Intelligence** — "Monitors creator participation sustainability and long-term well-being," tracking posting frequency, audience interaction load, live participation volume, monetization pressure, community management demands, creator satisfaction indicators. *Source: §11.2.6* (near-duplicate content also appears at §7.6.1/§7.6.2, uncited).

## D

**Dynamic Aura State System** — Named component ("Emotional tone tracking, Energy level detection, Social openness indicators") but given no prose definition in the source text. *Source: §11.5.2.*

## E

**Effort-Based Progression** — Named cross-reference term used to describe how Section 6 (Spark) integrates with Section 7 (Monetization) — "Monetization (Section 7) for effort-based progression" — but not independently defined beyond this citation. *Source: §6.13.*

**Effort-Gated Escalation System** — "Each interaction begins at a baseline level... Progression to deeper interaction stages requires specific conditions to be met." The core Spark pacing mechanic. *Source: §6.3.* See also Engineering Gap EG-09 (no scoring formula for any escalation condition).

**Emotional Identity** — Not independently defined as a single term; established through the **Emotional Identity Infrastructure** (§1.1.2), which owns the Emotional Type System, Social Persona System, Participation Style Classification, Emotional Energy Indicators, Communication Style Profiles, Relationship Style Profiles, Creator Expression Profiles, and Community Participation Profiles.

**Emotional Intelligence Layer** — One of six named AI system layers: "Interprets mood, tone, and emotional signals to support Aura-based systems and emotional adaptation." *Source: §11.2.1.*

**Emotional Readiness** — "Distinct from emotional state... represents a user's current willingness and capacity to participate." Seven states: Open, Guarded, Exploring, Friendship Focused, Relationship Ready, Healing, Unavailable. *Source: §12.5.*

**Emotional State Engine** — The system the Profile System (§5.4) presents outward-facing signals for; not itself independently defined outside of its restatement as the nine Primary Emotional States (see below).

## F

**Feed Intelligence & Decision Engine** — The system "determining how content is selected, ranked, and delivered across all discovery environments... how decisions are actually made in real time." *Source: §4.4.* See also Engineering Gap EG-04 (the ranking formula this engine is named for is never given).

**For You (feed environment)** — "Acts as the central orchestration layer. It blends content from different environments." *Source: §4.3.1/§4.18.*

## G

**Glow** — "Friendship / Social Intent... used for platonic interaction, ensuring a clear boundary between social and romantic engagement." One of four intent-based interaction actions (with Spark, Follow, Engage). *Source: §2.2, reinforced at §6.14.7.* Restricted to Kids/Teens as the only romantic-adjacent signal available to them ("Kids/Teens → Glow ONLY," §6.14.7).

## I

**Interest-Based Spaces**, **Identity-Based Spaces**, **Emotional & Support Spaces**, **Lifestyle & Experience Spaces** — The four Core Space Types of the Social Ecosystem (Section 19.12): Interest-Based ("shared hobbies, passions, and content engagement"), Identity-Based ("lived experiences and personal identity... higher moderation sensitivity"), Emotional & Support ("high-protection environments where... monetization is restricted or disabled"), and Lifestyle & Experience ("connect digital interaction to real-world experiences," bridging to TruTravel/Events). *Source: §19.12.*

## L

**Layer Priority Rule** — The explicit six-layer feed hierarchy: "Safety → Mode → Emotion → Relevance → Visibility → Monetization... no lower layer can override critical protections." *Source: §4.2.7.* See also Engineering Gap EG-04 (Critical — no scoring values given for this hierarchy).

**Low Energy Mode** — "Provides users with a reduced-intensity interaction environment designed for moments when they want to remain present without engaging fully." *Source: §6.6.1.* Named identically or near-identically at §2.2.1, §10.4.1 — see Engineering Gap EG-10 ("possibly one mechanism described three times... none have numeric thresholds").

## M

**Master Profile ID** — "Global identity anchor" underlying a user's single unified identity, which "dynamically adapts based on intent, environment, and access level." *Source: §1.1.*

**Match rooms** — "Private connection environments" — dedicated, access-gated spaces for deeper matchmaking interaction. *Source: §6.15.*

**Mood** — "The user's current emotional state and is fluid," explicitly distinguished from the more stable Aura. *Source: §5.6.3.* Also independently structured as the **9 Primary Emotional States** at §12.2 (see below) — the two are not explicitly cross-referenced to each other in the text, though they describe the same underlying concept.

**MoodSync** — Trulura's emotional-state operating system (Section 12), described in the text as consuming behavioral/interaction/tone signals and routing them into behavior changes across seven named consuming platform systems: AI Intelligence (§11), Creator Systems (§13), Healing & Recovery (§14), AI Companion (§15), Interface (§20), Safety (§22), and UX Journey (§25) — the explicit "MoodSync System Relationships" block at §12.11.1. Its operational core is the Context Routing Engine (§12.8.5). This is the highest-fan-out system in the Blueprint (see Engineering Gap EG-05 and `TruLura_Dependency_Heat_Map.md`).

## P

**Primary Persona** — "Represents the user's dominant energy or most consistent social presence." *Source: §5.3.*

**Secondary Persona** — "Reflects complementary traits or situational behavior." *Source: §5.3.*

## R

**Recovery Intelligence** — "Identifies situations where users may benefit from reduced participation pressure, lower stimulation, or recovery-oriented experiences." *Source: §11.2.5.*

**Recovery Interfaces** — Specialized UI experiences "for users currently operating within healing, recovery, burnout recovery, grief support, reflection, or reintegration states." *Source: §20.13.4.*

**Recovery State(s)** — Five named states — Healing, Recovering, Reflecting, Rebuilding, Reintegrating — presented in this order across multiple sections (§12.8.4, §14.7.1) but never explicitly stated as a strict, enforced sequence.

## S

**Safety Meter** — "Reflects a combination of trust signals, behavioral patterns, and verification status... intentionally designed to be subtle and non-stigmatizing." *Source: §9.15.*

**Safety Score** — Named twice as an "(internal)" signal, distinct from Trust Score: once at §16.5 (TruTravel eligibility — "Safety score (internal)") and once, in near-identical language, at §6.14.9 ("Safety scoring systems (internal)"). Neither subsection gives a numeric scale or formula. **Conflict/Alias**: Product Decisions register PD-15 cites §16.5's "safety score (internal)" as a fourth independent tier compounding the broader trust/verification naming conflict (see Trust Score, below); this glossary flags §6.14.9 as a likely additional, currently-uncounted instance of the same pattern.

**Social Battery** — "Measures available social energy and participation capacity," distinct from emotional state. Five states: High Energy, Moderate Energy, Low Energy, Recovering, Offline. *Source: §12.7.*

**Social Graph Intelligence** — One of six named AI system layers: "Maps relationships, interaction frequency, and social clusters to distinguish meaningful connections from surface-level interactions." *Source: §11.2.1.*

**Soft Mode** — An accessibility option that "reduces visual stimulation, notification intensity, and interface pressure across the platform experience," named at §6.6.1 as a broader system Low Energy Mode may integrate with, and independently as a Feed Mode ("low-stimulation feed presentation") at §20.12.1. Neither occurrence gives it a full independent specification.

**Spark** — Defined multiple times with a consistent core meaning ("romantic or connection-oriented intent") but used across at least four distinct grammatical roles in the text, none of which cross-reference one another:
1. *(Interaction/intent action)* — one of four intent-based actions (with Glow, Follow, Engage): "romantic interest." *Source: §2.2.*
2. *(Interaction-engine name)* — "Spark is not a swipe-based system. It is a guided progression model that controls: Match exposure, Interaction pacing, Emotional readiness alignment, Feature unlocking." *Source: §6.13.*
3. *(Feed/discovery surface name)* — "Spark" as a Primary Discovery Surface, entered only by user choice. *Source: §4.18.*
4. *(Navigation tab / feed-switching label)* — appears in Section 20.12.2's Feed Switching UI list ("For You / AuraFeed / Spark / Sync / Vent / Trending") alongside "Sync," a separate, unreconciled label. *Source: §20.12.2.*

**Conflict/Alias**: Product Decisions PD-08/PD-09 track the unresolved "Sync" (nav tab label, §10.9.1) vs. "Spark" (system name used everywhere else) naming question — this glossary does not resolve it. **"Spark = Romantic/Dating Intent"** is stated explicitly and unambiguously at §6.14.7, in contrast to **"Glow = Friendship/Social Intent."**

## T

**Trulura Coin** — "Functions as the central economic medium across the platform... not only a transactional tool but also a behavioral signal that reflects support, appreciation, and engagement." *Source: §7.3.*

**TruJourney (System)** — "Provides structured tools that help users build and maintain connections over time" — post-match relationship-continuity tooling. *Source: §6.7.1.* Also referenced as **TruJourney Mode**, a "post-match system" (§16.11, not further defined there).

**TruLuxe** — "A controlled, high-trust environment... a filtered ecosystem where access, visibility, and interaction are governed by trust, behavior, and alignment." *Source: §17.1.* Four founding philosophy pillars: Qualification Over Payment, Privacy Over Visibility, Intentional Interaction Over Volume, Discretion by Design (§17.2). Confirmed Phase 2 for the entire section.

**TruStudio** — "The central control system for all creator activity" — the Creator Platform's dashboard/tooling hub. *Source: §13.3.*

**TruTravel** — "Trulura's real-world extension layer." *Source: §16.1.* Confirmed Phase 2 for the entire section.

**Trust Infrastructure** — "Trust is not merely a safety score... influences access, visibility, discovery quality, participation opportunities, and high-trust experiences throughout the ecosystem." *Source: §1.3.1.*

**Trust Score** (also "internal trust score") — The canonical, single trust score for the platform, explicitly marked as such: **"[Canonical definition. Sections 9.22 and 22.18 consume this score rather than redefining it.]"** *Source: §1.3.* Described as "not a social ranking system — it is a safety intelligence layer," hidden from users by default. See Engineering Gap EG-02 (no numeric scale, per-signal weights, or gating thresholds given). **Conflict/Alias**: Product Decisions PD-01/PD-15 track a broader "four-way trust/verification tier naming conflict" spanning §1.2 (Verification Levels 0–3), §2.1.2 (Unverified/Basic/Advanced/Elite Verified), §9.2.1/§9.2.2 (Unverified/Partially Verified/Verified/High-Trust/Restricted), and §16.5 (Safety score, internal) — this Trust Score entry is the one place the Blueprint text itself explicitly declares a canonical definition; the other three/four schemes remain unreconciled to it in the source text.

## V

**Verification Level 0 (Basic)** — Email or phone verification; limited feature access. *Source: §1.2.*
**Verification Level 1 (Standard)** — Selfie verification; "unlocks messaging and basic interactions." *Source: §1.2.*
**Verification Level 2 (Verified)** — Government ID verification; "unlocks dating, monetization, and higher-trust features." *Source: §1.2.*
**Verification Level 3 (Trusted)** — Optional background check; "grants high-trust badge and premium access credibility." *Source: §1.2.*

**Vent Space** — "A protected emotional environment... where users can express thoughts, feelings, and experiences without the pressure of performance, visibility, or monetization." *Source: §14.1.* Explicitly excluded from monetization systems, algorithmic amplification, and performance-based visibility ranking (Section 14 intro).

## Numbered/Structural Terms (not proper nouns, but formally defined)

**Space Composition (Social Ecosystem)** — Five layers: Feed Layer (content, filtered by relevance/behavior/mood alignment), Live Layer (real-time interaction), Interaction Layer (comments/reactions/threads), Member Layer (roles/permissions), Moderation Layer (safety enforcement). *Source: §19.13.1.*

**Space States (Social Ecosystem)** — Five parallel (not sequential) states: Open (minimal restrictions), Restricted (requires approval/eligibility/behavior-based access), Private (invitation-only), Event-Based (temporary), Premium (subscription/payment-gated). *Source: §19.13.2.*

**Space Roles (Social Ecosystem)** — Four roles: Member (basic access), Contributor (content-creation privileges), Moderator (rule enforcement), Host/Owner (structural control). *Source: §19.16.* No numeric per-role permission set is given — see Engineering Gap EG-23.

**Feed Modes** — Four modes: Immersive Mode (content-first), Interactive Mode, Guided Mode (AI-assisted), Soft Mode (low stimulation). *Source: §20.12.1.*

**Enforcement Escalation Ladder** — Four stages, in order: Warning → Restriction → Suspension → Ban. No per-stage trigger conditions, durations, or thresholds are given. *Source: §22.25.* Product Decisions PD-21 confirms this as the single enforcement mechanism Sections 1.6 and 9.5.4.1 should reference.

**Accessibility Modes** — Four named modes, each with a definition sentence: Neurodivergent Experience Mode (sensory overload/executive-functioning/attention-regulation/cognitive-fatigue support), Epilepsy-Safe Experience Mode (reduces seizure risk/visual overstimulation), Elder-Friendly Experience Mode (usability for older adults), Low-Stimulation Experience Mode (calming environment for anxiety/stress/overwhelm/recovery/grief/burnout). *Source: §20.19.1–.4.* See Engineering Gap EG-25 (no technical spec for what each mode actually changes).

**9 Primary Emotional States** — Open/Social, Flirty/Romantic, Curious/Exploring, Low Energy/Passive, Overwhelmed/Burnt Out, Emotionally Vulnerable, Healing/Reflective, Confident/High Energy, Disconnected/Withdrawn — each paired with a one-sentence system-behavior response. *Source: §12.2.*

## Named But Not Defined

These terms are used throughout the Blueprint as if their meaning is already established, but no subsection anywhere in the document gives them a definition sentence:

- **Soft Mode** — referenced at §6.6.1, §10.12.2, §20.12.1 as an accessibility/low-stimulation feature, never given a full independent specification (see entry above for what is stated).
- **Anonymous Overlay System** — named at §1.1 as a core Identity Core component; never specified (Engineering Gap EG-19).
- **AI Dating Companion Layer** (§6.14.11) — functionally overlaps the canonical AI Companion (§15) but is never cross-referenced to it; not clear whether this is the same system under a different name.
- **Dynamic Aura State System** (§11.5.2) — component list given, no prose definition.

## Cross-References

`docs/02-Product/TruLura_Blueprint.md.md` (sole source) · `docs/02-Product/TruLura_Product-Decisions.md.md` (PD-01, PD-08, PD-09, PD-10, PD-15 — the naming conflicts this glossary flags but does not resolve) · `docs/02-Product/TruLura_Engineering-Gap-Register.md.md` (EG-02, EG-04, EG-05, EG-09, EG-10, EG-19, EG-23, EG-25) · `docs/03-Architecture/TruLura_Blueprint_Cross_Reference.md` (source of the underlying per-subsection extraction) · `docs/03-Architecture/TruLura_Domain_Model.md`.
