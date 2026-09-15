> **HISTORICAL — NOT CURRENT.** Archived 2026-09-14 by Product Owner ruling (DR-5 in `docs/TruLura_PO_Decision_Record_2026-09-14.md`).
>
> This document describes a repository state that no longer holds. It was preserved rather than patched, so that the change in its governing basis stays inspectable. The current Constitution is `docs/01-Constitution/05-TruLura_Constitution.md`.
>
> The text below the line is the original of 2026-08-23 (`f45fbf9`), unchanged. A correction to its "Product Decisions Belong in One Place" section was committed on 2026-09-14 (`3e19271`) and is not carried here; the rule it recorded is in `docs/DOCUMENTATION-STANDARDS.md`, standard 4.
>
> **Claims that do not verify against the repository (checked 2026-09-14):**
>
> - That it codifies rules "established by the Product Knowledge System's own folder structure (`docs/*/README.md`)". The eight folder READMEs were committed empty in `f45fbf9`, and `09-Archive` has no README.
> - Authority-order entries "Engineering Standards" and "Development Playbook". No document by either name exists.
> - The quotations from the `03-Architecture` and `04-Engineering` READMEs. That text was never in those files.
> - That the one-register rule is "stated independently in at least three" folder READMEs, and that product decisions are logged in the Product Decisions Register. The READMEs never held it, and the register holds open questions, not decisions.
> - That `Trulura_File_rebuild.docx` is "now archived in `09-Archive`". It is not in the repository.
> - That folders `03-Architecture` through `08-Business` "explicitly state they currently have 'no authoritative documents'". The phrase appears nowhere, and several of those folders hold documents.
> - That it was "compiled from ... the nine per-folder README files (`01-Constitution` through `09-Archive`)". Eight exist, all empty until 2026-09-14; there is no ninth.
> - **Unverifiable:** the authority-order entry "Product Knowledge System" as a single document.
>
> **Verified:** the authority order and precedence rule as stated in `docs/README.md`; the Product Constitution, Engineering Constitution and Repository Architecture documents; the Project Completion Summary and its three action types; Blueprint v2's statement that it supersedes `Trulura_File_rebuild.docx`; `09-Archive` holding the superseded Blueprint v2.

---

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
