# TruLura Backend Readiness

*Merges the code-level cut already in `TruLura_Systems_And_Debt_Review.md` §05 with the real Beta Readiness Checklist now available at `docs/02-Product/TruLura_Beta-Readiness-Checklist.md.md`. This is the first time both views exist side by side — do not read this as a new audit, it is a synthesis of the two.*

## What's Genuinely Backend-Supported Today

| Feature area | Backend reality (code) | Beta status (Blueprint) |
|---|---|---|
| Auth / Session | Real — Supabase Auth, fully wired | N/A (Session isn't a numbered Blueprint section; see Glossary) |
| Profile / Identity | Real — 3 tables (`profiles`, `matchmaking_profiles`, `user_states`) | Core Beta 🟡 (PD-04, inferred not confirmed) |
| Posts / Feed | Real — `posts`, `post_reactions` tables | Core Beta (base) ✅ |
| Quiz / Compatibility | Partial — writes to `user_settings`; most of the engine is local computation | Split ✅/🟡 (PD-06 exact line) |
| Chat / Messaging | **None** — fully local, hardcoded seed data | No matching Blueprint section found (EQ-01) |
| Sync / Matchmaking (Spark) | **None** — fully local | Core Beta (base) ✅ — confirmed required, not optional |
| Notifications | **None** — fully fabricated demo data | Referenced (§10.13), Medium-priority gap (EG-18) |
| Companion | **None** — not even local persistence | Split 🟡 (PD-11 proposed, not confirmed) |
| Creator Platform | **None** — gating flags exist, UI shell exists, no tables | Split ✅/🟡 — early monetization confirmed Core Beta |
| Safety / Trust | Partial, local-first by design | Core Beta 🟡 (PD-05), blocked by PD-12 (crisis detection) |

## The Five Real Beta Blockers (from the Blueprint, not from code)

Per the Beta Readiness Checklist's own final summary — **none of these are engineering problems**, and no amount of Flutter/Supabase work resolves them:

1. PD-14 — Navigation contradiction (blocks the app shell itself)
2. PD-12 — Crisis detection mechanism (needs Trust & Safety, not engineering)
3. PD-01/PD-15 — Four-way trust/verification tier naming
4. PD-19 — Payment/identity-verification vendor selection (procurement)
5. PD-20 — Data retention policy (needs Legal)

## What This Means for Sequencing

Building out Chat/Sync (ENG-002), Notifications (ENG-006), or Creator Platform (ENG-013) backend work can proceed in parallel with the five blockers above — they don't share a dependency. But Identity/Trust work (ENG-001) and Safety-adjacent work should not be considered "done" until PD-01/PD-15 and PD-12 resolve, since the underlying tier model and crisis-detection mechanism they'd be built against are still open.

## Not Yet Defined

Whether any of the "None" rows above will use Supabase Realtime (currently unused anywhere in `lib/`) is not decided — that's an implementation choice for whoever builds ENG-002/ENG-006, not specified by the Blueprint or the current repository.

## Cross-References

`TruLura_Systems_And_Debt_Review.md` §05 · `docs/02-Product/TruLura_Beta-Readiness-Checklist.md.md` · `docs/03-Architecture/ADR/ADR-005.md` (Backend Strategy) · `TruLura_Engineering-Backlog.md` ENG-002, ENG-006, ENG-013.
