<!-- .github/copilot-instructions.md -->

# Copilot / AI Agent Quick Guide for this repo

This file captures the immediately useful knowledge for an AI coding agent to be productive in this project.

- **Project type:** Expo React Native app (managed workflow). Entry: `App.js`.
- **Run / dev:** `npm install` then `npx expo start` (use `-c` to clear cache).
- **Lint / format:** `npm run lint`, `npm run lint:fix`, `npm run format`.

## Big picture

- Single React Native app with React Navigation and Supabase backend.
- Auth flow: `src/context/AuthContext.js` manages Supabase auth session and loads the `profiles` row. `AppNavigator` (in `src/navigation/AppNavigator.js`) chooses auth vs main app screens and forces `ProfileSetup` if the profile lacks `display_name`.
- Live data: `src/context/TruluraDataProvider.js` fetches `glows`, `sparks`, and `vents` and subscribes to Postgres realtime changes via Supabase channels. Tables used: `glows`, `sparks`, `vents`, `profiles`.

## Supabase setup / important nuance

- There are two Supabase client files with different purposes:
  - `src/lib/supabaseClient.js` — used by `AuthContext`. It configures Supabase with `AsyncStorage` and (in this repo) contains a hard-coded URL/anon key. This client supports `auth` persistence for the mobile app.
  - `src/lib/supabase.js` — used by `TruluraDataProvider`. It expects `process.env.EXPO_PUBLIC_SUPABASE_URL` and `EXPO_PUBLIC_SUPABASE_ANON_KEY` (the `.env` workflow). It prints a console error if the env vars are missing.
- When making changes to auth or realtime flows, be careful which client the code imports.

## Key patterns and conventions

- Data normalization: `TruluraDataProvider.normalizeRow` maps `created_at` → `createdAt` for UI code. Follow this pattern when reading/writing rows.
- Realtime updates: `TruluraDataProvider` creates a single channel `trulura-live` and subscribes to `postgres_changes` for each table; it calls `supabase.removeChannel(channelRef)` on cleanup. Match this subscribe/unsubscribe pattern when adding channels.
- State updates: add/insert handlers (e.g., `addSpark`, `addVent`) update local state immediately and rely on realtime to reconcile changes.
- UI structure: screens live in `src/screens/*`, components in `src/components/*`, theme in `src/theme/*` and `constants/theme.ts`.

## Developer workflows and gotchas

- Starting the app (recommended):
  - `npm install`
  - `npx expo start -c`
- The README references `npm run reset-project` but `package.json` does not define that script. To run the reset tool, call `node scripts/reset-project.js` manually. The script moves existing starter code into `app-example` and scaffolds `app/`.
- Use `npm run lint` and `npm run format` before submitting PRs.

## Where to look for common tasks (examples)

- Add authentication-related changes: `src/context/AuthContext.js`, `src/lib/supabaseClient.js`.
- Add new realtime table handling: `src/context/TruluraDataProvider.js` (see `applyChange` and subscription setup).
- Add screens or navigation: `src/navigation/*`, `src/screens/*`, `App.js`.
- Update Supabase env keys: prefer `src/lib/supabase.js` and `.env` variables (`EXPO_PUBLIC_SUPABASE_*`) for non-committed secrets; avoid changing the hard-coded key in `supabaseClient.js` without consent.

## How the UI expects data

- Many screens expect `createdAt` instead of `created_at`. Use `normalizeRow` or return rows with `createdAt` for compatibility.
- Data arrays are ordered by `created_at` descending in provider queries — UI lists assume newest-first.

## Security / commit guidance for agents

- Do not commit private keys. If you need to change secrets, prefer environment variables and document how to set them (use `EXPO_PUBLIC_SUPABASE_URL` and `EXPO_PUBLIC_SUPABASE_ANON_KEY`).

## Useful search tokens for an agent

- `TruluraDataProvider`, `useTruluraData`, `AuthContext`, `supabaseClient`, `EXPO_PUBLIC_SUPABASE`, `trulura-live`, `createdAt`.

---

If any section is unclear or you want me to expand examples (e.g., show how to add a new realtime listener or add a new screen), tell me which area to expand. I can iterate on this file.
