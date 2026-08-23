# TruLura API Inventory

*Existing APIs only — nothing below is invented or anticipated. Full inventory detail (including per-file usage) lives in `TruLura_Systems_And_Debt_Review.md` §06 in this folder; this document is the dedicated, focused version of that section.*

## APIs That Exist in the Repository Today

| API | Client | Used by | Notes |
|---|---|---|---|
| Supabase (REST + Auth) | `supabase_flutter` SDK, via `DatabaseService`/`SupabaseConfig` | ~8 files (see `TruLura_Backend-Readiness.md` for the table list) | 6 tables in use, zero `.rpc()` calls anywhere in `lib/`, no realtime channel subscriptions found |
| OpenAI (via a custom proxy) | Raw `http.post`, no SDK — `lib/openai/openai_config.dart` | `trulura_ai_suggestions_sheet.dart` (feed reply suggestions), `matchroom_screen.dart` (concierge tips) | Model `gpt-4o-mini`, JSON-mode responses, gated behind `OPENAI_PROXY_API_KEY`/`OPENAI_PROXY_ENDPOINT` env vars — throws if unconfigured, no defined fallback UI (Technical Debt TD-16) |

That is the complete set. No other external API call exists anywhere in `lib/`.

## Named in the Blueprint but Not Yet Selected — Not Yet Defined

The Blueprint (§21, Integrations) requires a payment processor and an identity-verification vendor, and Product Decision **PD-19** (`docs/02-Product/TruLura_Product-Decisions.md.md`) is explicitly open on which vendors. No vendor name, SDK, or endpoint is invented here — this section exists only to record that the Blueprint anticipates these integrations, not to specify them.

## Cross-References

`docs/04-Engineering/TruLura_Systems_And_Debt_Review.md` §06, §07 (Supabase Inventory) · `docs/02-Product/TruLura_Product-Decisions.md.md` PD-19 · `docs/02-Product/TruLura_Engineering-Gap-Register.md.md` EG-27 (vendor selection precedes any artifact) · `docs/04-Engineering/TruLura_Engineering-Backlog.md` ENG-016.
