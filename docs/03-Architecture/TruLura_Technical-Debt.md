# TruLura Technical Debt — Architectural View

*The full item-by-item Technical Debt Register (18 items, each with Problem/Evidence/Recommendation/Risk/Migration Strategy/Estimated Effort) lives in `docs/04-Engineering/TruLura_Systems_And_Debt_Review.md` §02. This document does not repeat it — it lists only the items that are architectural in nature (they concern how systems relate to each other, not an individual bug or missing feature), for readers who came here from the Dependency Graph or Repository Architecture rather than the full Engineering register.*

## Architectural Debt Items

| ID | Item | Why it's architectural, not just tactical |
|---|---|---|
| TD-13 | Five sibling providers, no composition root | This is the repository's state *topology* — the shape everything else (identity fragmentation, mood fragmentation) grows out of. See ADR-001. |
| TD-04 | No formal repository layer | A missing architectural boundary between business logic and data access, not a single bad function. See ADR-002. |
| TD-01 | Identity fragmented across 4 independent stores | A direct architectural consequence of TD-13 — no session object exists for identity to live in exactly once. Also a Constitution-level concern (see `TruLura_Repository-Architecture.md`, "Two Constitutional Violations"). |
| TD-02 | MoodSync fragmented into 2 unsynced systems | Same pattern as TD-01, for emotional state. Also a Constitution-level concern. |
| TD-11 | Two inconsistent Supabase client access paths | An architectural inconsistency in how the data layer is reached, even though both paths resolve to the same client. |
| TD-14 | Unused Riverpod dependency wraps the app | A structural artifact of an abandoned or unfinished state-management decision — see ADR-004. |
| TD-09 | A fully-built, unused auth abstraction layer | An architectural layer (interface + adapter) that was built but never connected — distinct from a normal dead-code case because it's a whole pattern, not a function. |

## Not Architectural (Stay in the Engineering Register Only)

TD-03, TD-05 through TD-08, TD-10, TD-12, TD-15 through TD-18 are real debt but concern individual features, duplicated logic, or process gaps rather than system-to-system structure — tracked fully in `docs/04-Engineering/TruLura_Systems_And_Debt_Review.md`.

## Not Yet Defined

Whether any architectural debt item above should become a formal ADR beyond the two already recorded (ADR-001, ADR-002) is a decision for whoever reviews `docs/03-Architecture/ADR/`, not asserted here.
