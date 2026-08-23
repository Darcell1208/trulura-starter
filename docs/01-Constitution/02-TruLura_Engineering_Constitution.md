# TruLura Engineering Constitution

*Extracted from the Blueprint. This document covers only what the Blueprint itself states about how systems must relate to each other and be built — not the current Flutter repository's specific architecture (see `docs/03-Architecture`) and not implementation workflow (see `docs/05-Development`). Where the Blueprint is silent, no rule is stated here.*

## The System Hierarchy Is a Hard Constraint, Not a Suggestion

Section 19.1.1 defines a strict execution order that governs how systems must resolve conflicts:

1. Safety & Consent Systems (Highest Priority)
2. State & Mode Logic
3. AI Interpretation Layer
4. Experience Systems (Feed, Matchmaking, Creator Tools)

Any architecture — current or future — that lets a lower layer override a higher one (e.g., a personalization feature bypassing a safety check, or an AI recommendation contradicting mode/state logic) violates this hierarchy. This is the single most load-bearing engineering constraint in the Blueprint: nearly every gated feature in the product depends on it (see the Product Knowledge System's Engineering Gap Register, EG-01).

## No System Owns What It Only Consumes

The Blueprint is explicit, section by section, about ownership boundaries — several sections carry a "does not own" list alongside their "owns" list (e.g., §14 Vent Space "does NOT own: Recovery States, MoodSync, Interface Rendering, Journey Routing"; §15 AI Companion "does NOT own: Core AI infra, Mood states, Clinical support, Interface rendering, Journey routing"). The engineering implication: a consuming system must call into the owning system's interface, never re-implement or fork the owned behavior locally. Where this rule is violated in the current codebase (e.g., mood/color logic duplicated outside MoodSync's intended ownership), it is a Blueprint-alignment defect, not just a style issue.

## Integrations Are Governed, Never Structurally Privileged

"External systems must never override Trulura's internal governance, safety layers, or trust systems" (§21). Any third-party integration (payment processor, identity verification, future AI providers) must be architected so it can be swapped or removed without touching the systems it feeds — connection, not embedding.

## Infrastructure Is Deliberately Stack-Agnostic

Section 23 (Infrastructure) names no required technology stack. This is a stated design choice, not an oversight — the Blueprint governs product behavior and system relationships, not implementation technology. Engineering is free to choose and change infrastructure (the current repository's Flutter + Supabase choice is one valid instantiation) as long as the product-level behavior and system hierarchy above are preserved.

## Security Is Zero-Trust by Stated Philosophy

Section 22.1 names its governing model directly: "Security Philosophy & Zero-Trust Model." Nothing in the current repository should be built assuming implicit trust between systems, clients, or services — every access decision should be explicit and verified, consistent with §22's framing.

## Log What's Undecided — Never Invent It

This is not a single Blueprint quote but the working method the entire Product Knowledge System was built with, stated in the Project Completion Summary: every action taken during the Blueprint's modernization was one of three types — "(1) a mechanical structural fix... (2) a canonical-system merge that preserved all unique content from both sources, or (3) a logged, unresolved question sent to Product/Legal/Trust & Safety rather than answered by assumption." Engineering inherits this same discipline: an underspecified system (see the Engineering Gap Register) gets a logged gap and, where needed, an escalated Product Decision — never a guessed implementation that quietly becomes the de facto spec.

## Provenance

Compiled from direct Blueprint sections 9, 19, 21, 22, 23, plus the Project Completion Summary's stated working method. Re-derive from the Blueprint if it changes, rather than editing this document independently.
