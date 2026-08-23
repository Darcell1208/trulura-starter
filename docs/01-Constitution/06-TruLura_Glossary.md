# TruLura Glossary

*Canonical terms as used in the Blueprint, with the section(s) where each is defined. Definitions are kept to what establishes the term's meaning and boundaries — not its full feature specification, which lives in the cited Blueprint section. Where the Blueprint itself has not yet resolved a naming question, that is stated rather than resolved here.*

**Aura** — Used in two related but distinct ways in the Blueprint: (1) the Discovery/Social Feed environment, "Aura (Social Feed / Identity Layer)" (§10.9.1); (2) a broader identity/interaction signal that "functions as a broader identity signal that influences how a user is perceived across the platform, shaping visibility, energy, and contextual interpretation" (§6.13).

**Spark** — The romantic/dating interaction signal and system: "romantic or connection-oriented intent... used when a user is expressing interest in exploring a deeper or potentially romantic interaction" (§6.13); also the name of Section 6 itself, "Matchmaking/Spark." **Naming note:** Section 10.8/10.9.1 uses "Sync (Matchmaking / Dating Mode)" for what appears to be this same system — the Blueprint does not resolve which label is canonical (open Product Decision PD-08).

**Glow** — The safe/friendly, non-romantic interaction signal: "safe, friendly, or non-romantic engagement... especially important in youth spaces, friendship discovery, and community-based interaction" (§6.13).

**MoodSync** — The platform's emotional-state operating system (§12). The Blueprint's highest-fan-out dependency: 9+ other sections (AI, Creator Platform, Vent Space, AI Companion, Interface, Safety, Journey, Orchestration, Social Ecosystem) consume its output. Owns emotional state; does not own AI decision logic, which only consumes its signals (§11.14.1).

**Vent Space** — An isolated, protected emotional-support feed space (§14). Explicitly does not own MoodSync, Recovery States, Interface Rendering, or Journey Routing — it consumes them.

**AI Companion** — A chat/support surface distinct from the general AI Intelligence layer (§15). "Not task-focused — it is emotionally aware, behaviorally adaptive, and context-driven" and explicitly "does not replace human relationships" (§15.4/§15).

**Creator Platform / TruStudio** — The creator tools and dashboard system (§13), split between a Core Beta "early monetization" scope and a Phase 2 "expansion" scope (per the Beta Readiness Checklist).

**TruTravel** — Real-world travel/experience matching system (§16). Phase 2, explicitly out of Core Beta scope.

**TruLuxe** — A gated premium tier, "not simply a paid upgrade... a filtered ecosystem where access, visibility, and interaction are governed by trust, behavior, and alignment" (§17.2). Phase 2, explicitly out of Core Beta scope.

**Community Worlds / Social Ecosystem** — Interest- and identity-based community spaces (§19.11–19.23), operating "as interconnected worlds rather than isolated groups" (§20.2.3). Canonical home for what earlier sections (§4.18) referred to as Community layers.

**Active State** — Confirmed equivalent to Mode (§2/3) per the Dependency Graph; the term used in Section 10's navigation/state model for a user's current mode.

**Anonymous Overlay** — Named as a core component of the Identity Core System (§1.1) but not yet specified anywhere in Section 1 — an acknowledged Engineering Gap (EG-19), not a defined mechanism.

**AuraShield** — The platform's behavioral-trust evaluation system, distinct from incident-based moderation: it "evaluates behavior over time rather than relying on isolated incidents... analyzes communication tone, interaction consistency, escalation patterns, and discrepancies between stated intent and actual behavior" (§9).

**Master Identity / Master Profile** — "Each user has one master identity" (§1.1) that branches into contextual layers by mode/environment without losing continuity. The underlying data model has no defined schema yet (Engineering Gap EG-03).

## Provenance

Every entry above cites the Blueprint section that defines it and was verified by direct search of `docs/02-Product/TruLura_Blueprint.md.md`. Terms not yet clearly defined in the Blueprint (e.g., a precise scope for "Glow" beyond §6.13's interaction-signal description) are not included rather than guessed.
