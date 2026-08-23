# TruLura Dependency Heat Map

*v2 — rebuilt at subsection-level detail from `TruLura_Blueprint_Cross_Reference.md`, superseding the v1 section-level count that was derived from `TruLura_Dependency-Graph.md.md` alone. This document's own v1 text flagged this rebuild as pending ("a subsection-level heat map... awaits Task 1's Cross-Reference Index") — that index is now complete, so this is that rebuild.*

## Method

Every explicit, numbered "Section N" citation found anywhere in the Cross-Reference Index was treated as one directed edge (citing section → cited section). Edges come from two kinds of statement in the Blueprint's own text: (a) a section's own "Consumes" / "Primary Dependencies" declaration (e.g., §7.16's explicit dependency list), and (b) a *reciprocal* statement made by the cited section about who depends on it (e.g., §12.11.1's "Connected Systems" list, which names sections 20 and 22 as consumers of MoodSync even though neither Section 20 nor Section 22 states that relationship in its own text). Where both directions are independently stated for the same pair of sections (e.g., §6.13 states Section 6 draws on Section 7's monetization framing, while §6.14.1 separately states Section 7 is triggered by Section 6's Spark-stage events), both edges are counted — a bidirectional relationship is not the same as a single edge counted twice. Named-but-unnumbered references ("the Mood System," "the AI system") are excluded, exactly as they were excluded from the Cross-Reference Index itself. This is a manual edge-by-edge count against ~90 citations across 26 sections; it is thorough and independently auditable against the Cross-Reference Index's citations, but is not machine-verified — treat exact counts as accurate to within one or two edges, not as a guaranteed-exact figure.

## Incoming Dependencies (highest fan-in — most foundational / highest blast radius)

| Rank | Section | Incoming Count | Cited By |
|---|---|---|---|
| **1** | **12 — MoodSync** | **13** | 6, 7, 11, 13, 14, 15, 16, 17, 18, 19, 20, 22, 25 |
| **2** | **11 — AI Intelligence** | **11** | 2, 6, 7, 13, 14, 15, 16, 17, 18, 19, 25 |
| **3** | **20 — Interface Systems** | **8** | 7, 13, 14, 15, 16, 17, 18, 25 |
| **4** | **25 — Journey Systems** | **7** | 7, 13, 14, 15, 16, 17, 18 |
| 5 (tie) | **6 — Matchmaking** | 6 | 3, 7, 8, 9, 11, 19 |
| 5 (tie) | **7 — Monetization** | 6 | 2, 3, 6, 8, 13, 19 |
| 7 | **18 — Progression System** | 5 | 4, 6, 7, 13, 14 |
| 8 | **4 — Discovery** | 3 | 2, 3, 5 |
| 8 | **13 — Creator Platform** | 3 | 7, 16, 18 |
| 8 | **14 — Vent Space** | 3 | 3, 15, 18 |
| 8 | **16 — TruTravel** | 3 | 3, 15, 17 |
| 12 | **9 — Safety, Trust, Privacy & Compliance** | 2 | 2, 3 |
| 12 | **1 — Identity & Trust** | 2 | 9 (via 9.22), 22 (via 22.18) |
| 12 | **15 — AI Companion** | 2 | 11, 17 |
| 12 | **22 — Security/Compliance** | 2 | 2, 9 |
| 16 | **3 — Experience Modes (behavioral layer)** | 1 | 4 |
| 16 | **19 — Orchestration/Social Ecosystem** | 1 | 4 |
| 16 | **21 — Integrations** | 1 | 9 |
| 16 | **24 — Governance** | 1 | 2 |
| — | **2, 5, 8, 10, 17, 21, 23, 26** | 0–1 | No section explicitly cites these by number as a dependency (does not mean nothing depends on them in practice — see "What This Changes" below) |

**MoodSync (Section 12) is confirmed as the single most-cited-by-others section, at subsection granularity — 13 distinct sections name it as an explicit dependency**, either in their own text or via Section 12's own reciprocal "Connected Systems" statement (§12.11.1). This corroborates the v1 heat map's section-level finding but with a materially higher count once subsection-level citations (§6.13, §7.15, §11.2.3, §11.14.1, §14.7, §15.5, §16.6, §17.12/17.14, §19.21) are counted individually rather than only the nine formal "Dependencies" closing blocks.

**AI Intelligence (Section 11) moves to a clear #2 at subsection granularity** — a materially different result from the v1 heat map, which did not surface Section 11 among the top incoming-dependency sections at all (v1's Dependency Graph source counted it among "Mid-Layer Systems" with only 5 incoming citations). The difference comes from crediting each of the nine "Dependencies" closing-subsection blocks (§7.16, §13.12, §14.14, §15.14, §16.14, §17.15, §18.21, §25.20 — eight of the nine — all separately name Section 11) plus §2.7, §6.14.1, §6.11.3.3(§11.3.3), and §19.22.

**Interface Systems (Section 20) drops from a tied #1 (v1) to #3 (v2)** once the count is done at subsection granularity rather than only counting the section-level Dependency Graph's aggregate figure. Section 20 remains structurally significant — still the third-highest incoming count in the Blueprint, and still carries PD-14 (Critical, the navigation contradiction) — but MoodSync and AI Intelligence are now shown to have *more* explicit citations once every subsection-level reference is counted individually, not just the section-level "Dependencies" blocks.

## Outgoing Dependencies (highest fan-out — most prerequisites before "ready")

| Rank | Section | Outgoing Count | Depends On |
|---|---|---|---|
| **1** | **7 — Monetization** | **7** | 6, 11, 12, 13, 18, 20, 25 |
| 2 (tie) | **13 — Creator Platform** | 6 | 7, 11, 12, 18, 20, 25 |
| 2 (tie) | **15 — AI Companion** | 6 | 11, 12, 14, 16, 20, 25 |
| 2 (tie) | **17 — TruLuxe** | 6 | 11, 12, 15, 16, 20, 25 |
| 2 (tie) | **18 — Progression System** | 6 | 11, 12, 13, 14, 20, 25 |
| 2 (tie) | **2 — Experience Modes (architecture layer)** | 6 | 4, 7, 9, 11, 22, 24 |
| 2 (tie) | **3 — Experience Modes (behavioral layer)** | 6 | 4, 6, 7, 9, 14, 16 |
| 8 | **16 — TruTravel** | 5 | 11, 12, 13, 20, 25 |
| 9 (tie) | **6 — Matchmaking** | 4 | 7, 11, 12, 18 |
| 9 (tie) | **9 — Safety, Trust, Privacy & Compliance** | 4 | 1, 6, 21, 22 |
| 9 (tie) | **14 — Vent Space** | 4 | 11, 12, 20, 25 |
| 9 (tie) | **19 — Orchestration/Social Ecosystem** | 4 | 6, 7, 11, 12 |
| 13 | **4 — Discovery** | 3 | 3, 18, 19 |
| 13 | **11 — AI Intelligence** | 3 | 6, 12, 15 |
| 13 | **25 — Journey Systems** | 3 | 11, 12, 20 |
| 16 | **8 — Monetization (non-canonical duplicate)** | 2 | 6, 7 |
| 16 | **22 — Security/Compliance** | 2 | 1, 12 |
| 18 | **5 — Profile System** | 1 | 4 |
| 18 | **20 — Interface Systems** | 1 | 12 (reciprocal only — see note) |
| — | **1, 10, 12, 21, 23, 24, 26** | 0 | Zero-outgoing per own text — see below |

**Monetization (Section 7) has the single highest outgoing-dependency count at subsection granularity (7)** — a new #1 finding not surfaced in v1, driven by including the bidirectional edge §6.14.1 states (Section 7 is triggered by Section 6's Spark-stage progression) alongside §7.16's six-item "Primary Dependencies" block. **Note the internal document inconsistency this surfaces**: §7.16's own "Primary Dependencies" list does not include Section 6, even though §6.14.1 explicitly states Section 7 is triggered by Spark-stage events — this is a genuine gap in the Blueprint's own self-documentation, not a counting error in this heat map, and is logged as a documentation anomaly (see Cross-Reference Index and the Engineering Gap Register's EG-17 update, below).

**Section 20's outgoing edge is a special case.** Section 20 states no outgoing dependency anywhere in its own text (confirmed by full read — see Cross-Reference Index). The single outgoing edge credited to it here (20→12) comes entirely from Section 12's reciprocal statement (§12.11.1 lists Section 20 as a consuming system) — Section 20 has never itself stated that it depends on MoodSync. This is the same documentation gap flagged throughout this engagement (EG-26/EG-31): the single most-depended-upon section in the Blueprint is also one of the least self-documented.

## Zero-Outgoing Nodes (boundary / substrate — confirmed at subsection level)

| Section | Note |
|---|---|
| **1 — Identity & Trust** | Confirmed zero outgoing at subsection level — the most upstream section in the Blueprint, exactly as v1 found. |
| **12 — MoodSync** | Confirmed zero outgoing — the second most upstream section, and (per the incoming table above) also the single highest fan-out target. This combination — zero dependencies, highest incoming count — is the clearest possible textual signal of foundational status anywhere in the Blueprint. |
| **10 — Navigation/Session State** | No explicit numbered cross-reference exists anywhere in Section 10's own text (confirmed — this is the same silence that makes the PD-14 contradiction with Section 20 undetected in the source itself). |
| **21 — Integrations** | Boundary layer by design — "external systems must never override internal governance." |
| **23 — Infrastructure** | Substrate layer by design, deliberately stack-agnostic. |
| **24 — Governance** | No explicit outgoing citation in its own text, despite being cited BY Section 2 (2.12). |
| **26 — Future Expansion** | Depends on nothing — a planning document, not a runtime system. |

## What This Changes from v1

1. **MoodSync (12) retains its #1 incoming rank, but the margin over #2 widens materially** once subsection-level citations are counted (13 vs. 11, rather than v1's coarser "9+" qualitative estimate).
2. **AI Intelligence (11) is the single largest change from v1** — it did not appear in v1's top-ranked incoming sections at all, and is now a clear #2. This matters for sequencing: nearly every "Dependencies" closing subsection in Sections 13–18 and 25 lists Section 11 alongside Section 12, meaning AI Intelligence is exactly as foundational a blocker as MoodSync for those seven downstream systems, not a secondary concern.
3. **Interface Systems (20) drops from a tied #1 to a clear #3.** It remains structurally significant (still carries the Critical-priority PD-14 navigation contradiction) but is no longer the single most-cited section once every subsection-level reference across the document is counted individually rather than only the nine formal "Dependencies" blocks.
4. **Monetization (7) emerges as the new #1 outgoing/most-dependent section**, a result v1 did not surface (v1 had TruLuxe/Progression/Creator tied at #1 outgoing). This is driven by the bidirectional Section 6 ↔ Section 7 relationship (§6.13 and §6.14.1 combined) plus §7.16's six-item Primary Dependencies list.
5. **A genuine Blueprint self-documentation inconsistency was surfaced by this recount**: Section 7's own "Primary Dependencies" declaration (§7.16) omits Section 6, despite §6.14.1 explicitly stating Section 7 is triggered by Section 6's Spark-stage progression events. This is not a heat-map artifact — it is evidence the Blueprint's nine "Dependencies" closing subsections were not cross-checked against each other's bodies at the time of writing. Logged against EG-17 below.

## Recommended Build-Order Implication (updated)

The v1 recommendation — Section 1 and Section 12 first, Section 20's contradiction resolved second, Sections 2/3/4/5/9/10 as the second tier — is **strengthened, not overturned**, by this recount, with one addition: **Section 11 (AI Intelligence) should be sequenced alongside Section 12, not after it.** Both are zero- or near-zero-outgoing, both are named as an explicit dependency by nearly every mid-to-late-stage system in the Blueprint (13, 14, 15, 16, 17, 18, 25 all cite both 11 and 12 together in their own "Primary Dependencies" blocks), and neither can be meaningfully deferred without blocking the same downstream set. Treating "MoodSync + AI Intelligence" as one foundational pair, ahead of the Section 20 navigation resolution, is the single clearest sequencing change this subsection-level recount produces relative to v1.

## Not Yet Defined

Exact numeric counts for Security/Compliance (22) and any section's "depended on by nearly all sections"-style qualitative claims from the original Dependency Graph are not re-derived here beyond what the Cross-Reference Index's explicit citations support — this document does not convert a qualitative Blueprint statement into an invented number where the Cross-Reference Index found no specific numbered citation. This is a manual count, not a machine-verified one; a second independent pass against the Cross-Reference Index's ~90 citations would be worth doing before treating any single rank as final, though the top-4 incoming ranking (12, 11, 20, 25) is stable under reasonable counting-method variation, since each of those four is named by at least seven independent "Dependencies" closing subsections.

## Cross-References

`docs/03-Architecture/TruLura_Blueprint_Cross_Reference.md` (sole source for every count above) · `docs/02-Product/TruLura_Dependency-Graph.md.md` (v1 source, now superseded at subsection granularity by this document, retained as the section-level reference) · `docs/02-Product/TruLura_Engineering-Gap-Register.md.md` (EG-17, updated below, for the §7.16/§6.14.1 self-documentation inconsistency this recount surfaced) · `docs/02-Product/TruLura_Implementation-Roadmap.md.md`.
