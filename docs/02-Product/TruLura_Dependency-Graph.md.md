# TruLura Blueprint — Living Dependency Graph

*Based on explicit "owns/consumes" language found in Sections 1–15 (strongest source: 2.3–2.12, 11.14.1, 12.11.1, 13.12, 14.14, 15.14). Updated after each Ecosystem Review. Arrows read "depends on."*

## Core Foundation Layer (everything else depends on these)

```
Identity & Trust (1) ─┬─→ Profile (5)
                       ├─→ Mode/Experience (2/3) [confirmed = Section 10 Active State]
                       ├─→ Discovery/Aura (4)
                       ├─→ Matchmaking/Spark (6)
                       ├─→ Monetization (7/8)
                       ├─→ Safety (9)
                       └─→ Navigation state (10)

MoodSync (12) ─────────┬─→ AI Intelligence (11)
  [highest fan-out —   ├─→ Creator Platform (13)
   7 confirmed          ├─→ Vent Space (14)
   consumers]           ├─→ AI Companion (15)
                        ├─→ Interface/UI (20, not yet reviewed)
                        ├─→ Safety (22, not yet reviewed)
                        └─→ Journey/UX (25, not yet reviewed)
```

## Mid-Layer Systems

```
Mode/Experience (2/3) ─┬─→ Discovery (4) [visibility/eligibility rules]
                        ├─→ Matchmaking (6) [Romantic Mode gates Spark]
                        ├─→ Monetization (7/8) [Creator Mode enables, Vent Mode restricts]
                        ├─→ Safety (9) [mode-specific safety requirements]
                        └─→ Governance (22/24, not yet reviewed)

AI Intelligence (11) ──┬─→ Mode recommendations (2/3)
                        ├─→ Feed ranking signals (4)
                        ├─→ Compatibility intelligence (6)
                        ├─→ Monetization timing (7/8) [constrained — does not control]
                        └─→ AI Companion (15) [11.7.4 now a pointer to 15]

Profile (5) ────────────┬─→ Discovery (4) [5.3.1: explicit "Profile → Discovery" link]
                        └─→ Matchmaking (6) [Attraction Mapping feeds compatibility]
```

## Consumer/Leaf Systems

```
Creator Platform (13) ──→ depends on: Monetization (7), AI (11), MoodSync (12), UI (20), Journey (25)
Vent Space (14) ────────→ depends on: AI (11), MoodSync (12), UI (20), Journey (25)
                          explicitly does NOT own: Recovery States, MoodSync, Interface Rendering, Journey Routing
AI Companion (15) ───────→ depends on: AI (11), MoodSync (12), Vent Space (14), TruTravel (16, not yet reviewed), UI (20), Journey (25)
                          explicitly does NOT own: Core AI infra, Mood states, Clinical support, Interface rendering, Journey routing
```

## Cross-Cutting Shared Dependencies (referenced by many systems, no single formula owner yet)

- **Permission Resolution** (Mode + Trust + Verification + Emotional State → access decision): referenced by Sections 1, 2/3, 6, 9, 10 — home is Section 10.5.1, logic undefined (EG-01).
- **Crisis Detection**: referenced identically by Sections 9, 14, 15 — no shared owner yet (EG-06 / PD-12).
- **Progression Ladders**: same gap shape in Sections 4.18.4 (Community), 6.14.12 (Spark), 13.10.2 (Creator) — no shared owner yet (EG-11).

## Confirmed Equivalences (not separate systems, despite different names)

- Section 10.2 "Active State" = Section 2/3 "Mode" (resolved, Sections 6–10 Ecosystem Review)
- Section 11.7.4 "AI Companion" (short form) = pointer to Section 15 "AI Companion" (canonical) — merge executed

## Still-Open Equivalence Questions (not assumed, pending Product confirmation)

- Section 1.1.4 "Identity States" vs. Mode (2/3) / Active State (10) — PD-10
- Section 1.2 verification tiers vs. Section 2.1.2 tiers vs. Section 9.2.1/9.2.2 tiers — PD-01

## Batch Update: Sections 16–20

```
TruTravel (16) ─────→ depends on: AI (11), MoodSync (12), Creator Platform (13), UI (20), Journey (25)
                       does NOT own: Mood States, Trust Scores, Interface Rendering, Journey Routing, Creator Monetization

TruLuxe (17) ────────→ depends on: AI (11), MoodSync (12), AI Companion (15), TruTravel (16), UI (20), Journey (25)
                       does NOT own: Mood States, Core Trust Scoring, Interface Rendering, Creator Monetization, Journey Routing

Gamification (18) ───→ depends on: AI (11), MoodSync (12), Creator Platform (13), Vent Space (14), UI (20), Journey (25)
                       [NEW: now the canonical progression owner — Community (4.18.4), Spark (6.14.12), and
                        Creator (13.10.2) progression all depend on 18.3, not the reverse]

Orchestration (19.1–19.10) ─→ sits ABOVE all other systems as sequencing/conflict-resolution layer
                                [NEW: 19.1.1 establishes coarse priority — Safety > Mode/State > AI > Experience]

Social Ecosystem (19.11–19.23) ─→ depends on: MoodSync (12), AI (11), Spark (6), Monetization (7), TruTravel (16)
                                    [MERGED: canonical for Community Worlds — Section 4.18 now points here]

Interface/UI (20) ───→ depended on by: 11, 12, 13, 14, 15, 16, 17, 18, 19 (highest fan-in of any section so far)
                       [CONTRADICTION: Section 20.2 Navigation ≠ Section 10.9 Navigation — see PD-14]
```

## Not Yet Mapped (sections 21–26 pending review)

Integrations (21), Security/Compliance (22), Infrastructure (23), Governance (24), UX Journey (25), Future Expansion (26).

*Graph will be updated after the final Ecosystem Review.*

## Batch Update: Sections 21–26 (Final)

```
Integrations (21) ──────→ boundary layer, no internal dependencies; feeds vendor
                           requirements into: Identity (1.2), Monetization (7/8)

Security/Compliance (22) → cross-cutting, depended on by nearly all sections;
                           [MERGED: canonical for data security — 9.12.1.1/.2/.3 now point here;
                            9.12.1 Virality Suppression preserved as unique Safety content]
                           enforcement ladder (22.25) now the reference for Sections 1.6, 9.5.4.1

Infrastructure (23) ─────→ substrate layer beneath all sections; no named tech stack (by design)

Governance (24) ─────────→ relates to (not merged with): Orchestration (19.1.1, execution priority),
                           Security (22.25, enforcement mechanism) — three distinct "authority" layers
                           that compose: 24 sets rules → 19.1.1 sequences execution → 22.25 enforces

UX Journey (25) ─────────→ depends on: AI (11), MoodSync (12), Interface (20)
                           [transitively blocked by PD-14 via its Section 20 dependency]

Future Expansion (26) ───→ depended on by ALL sections' Beta Classification; depends on nothing
                           [FIXED: duplication resolved — this is now a single, complete section]
```

## FINAL ARCHITECTURE SUMMARY (all 26 sections)

**Foundation layer (everything depends on these):** Identity & Trust (1), Mode/Experience (2/3), MoodSync (12), Security/Compliance (22).

**Highest fan-out node:** MoodSync (12) — 9+ confirmed dependent sections.

**Highest fan-in / most depended-upon-by-others:** Interface/UI (20) — 9 sections list it as a dependency, yet it currently contains the project's most severe unresolved contradiction (PD-14).

**Cross-cutting layers with no single "owner" feature module:** Permission Resolution (spans 1, 2/3, 6, 9, 10, 19), Crisis Detection (spans 9, 14, 15), Progression (unified under 18.3), Authority/Enforcement (spans 19.1.1, 22.25, 24 — related, not merged).

**Roadmap dependency:** Section 26 sits structurally "above" every other section's Beta Classification despite having no functional dependents — it's a planning document, not a runtime system, but the whole project's phase-tagging traces back to it.

*Dependency Graph is now complete for all 26 sections (v1 of the Product Knowledge System).*
