# TruLura Documentation Constitution

*Unlike the other Constitution documents, this one is not extracted from the Blueprint's product content — it codifies the governance rules already established by the Product Knowledge System's own folder structure (`docs/*/README.md`) and by the working method used to build it (the Project Completion Summary). Both are already-authoritative sources; this document consolidates them rather than inventing new rules.*

## Authority Order

Stated in the top-level `docs/README.md`:

1. Product Constitution
2. Engineering Constitution
3. Product Knowledge System
4. Repository Architecture
5. Engineering Standards
6. Development Playbook

**When conflicts occur, higher-level documents take precedence.** A folder's own README is explicit that content within it must remain consistent with what's above it, never the reverse (e.g., `03-Architecture` "translates `02-Product`'s content into build order," not the other way around; `04-Engineering` "should never introduce a product decision on its own").

## Product Decisions Belong in One Place

The single most important rule found across the folder READMEs, stated independently in at least three of them (`04-Engineering`, `06-Design`, `08-Business`): if a gap can't be closed without a product-level decision, it is logged in `02-Product`'s Product Decisions Register and referenced from wherever it was found — never answered locally by inference, and never duplicated into a second, competing register. This applies to every downstream folder equally, including engineering.

## Never Invent — Log Instead

The Blueprint Modernization Project's own stated method (Project Completion Summary): every action taken was one of exactly three types — a mechanical structural fix, a canonical-system merge preserving all original content, or a logged, unresolved question sent to Product/Legal/Trust & Safety. No fourth category ("assumed answer") is permitted. This rule extends to every document built on top of the Blueprint: architecture reviews, engineering registers, and this Constitution set alike.

## Documents Are Living, and Superseding Is Explicit

Documents in `02-Product` through `08-Business` are living and expected to update as decisions resolve and sections are added — but the mechanism is explicit versioning and cross-referencing (e.g., `TruLura_Blueprint_v2` explicitly supersedes the original `Trulura_File_rebuild.docx`, now archived in `09-Archive`), never silent overwriting. `09-Archive` exists specifically so superseded material stays traceable rather than disappearing.

## Nothing Is Authoritative by Default

Several folders (`03-Architecture` through `08-Business`) explicitly state they currently have "no authoritative documents" until their content is actually drafted as standalone specs — a folder's existence in the structure is not itself a claim that it contains settled guidance. Check each document's own stated status before treating it as settled.

## Provenance

Compiled from `docs/README.md` and the nine per-folder README files (`01-Constitution` through `09-Archive`), plus the Blueprint Project Completion Summary's stated working method. This document should be revised if the folder structure or its stated authority rules change.
