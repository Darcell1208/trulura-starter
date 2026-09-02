<!-- .github/copilot-instructions.md -->

# Copilot / AI Agent Quick Guide for this repo

This file captures the immediately useful knowledge for an AI coding agent to be productive in this project.

- **Project type:** Expo React Native app (managed workflow). Entry: `App.js`.
- **Run / dev:** `npm install` then `npx expo start` (use `-c` to clear cache).
- **Lint / format:** `npm run lint`, `npm run lint:fix`, `npm run format`.

## Big picture

- Single React Native app with React Navigation and Supabase backend.
- Auth flow: `src/context/AuthContext.js` manages Supabase auth session and loads the `profiles` row. `AppNavigator` (in `src/navigation/AppNavigator.js`) chooses auth vs main app screens and forces `ProfileSetup` if the profile lacks `display_name`.
- Live data: each screen queries Supabase directly — `ExploreScreen` and `CreatorScreen` read `glow_sessions`/`sparks`/`vents`/`moods`, `GlowScreen` reads `glow_posts`, `VentScreen` reads `vent_posts`. `src/hooks/useRealtimeCounts.js` holds the realtime subscriptions. Tables used: `glow_posts`, `glow_sessions`, `sparks`, `vents`, `vent_posts`, `moods`, `profiles`.
- There is no `glows` table. "Glows" is a UI label: `glow_sessions` backs the counts and Explore/Creator feeds, `glow_posts` backs the Glow feed.

## Supabase setup / important nuance

- There are two Supabase client files with different purposes:
  - `src/lib/supabaseClient.js` — used by `AuthContext`. It configures Supabase with `AsyncStorage` and (in this repo) contains a hard-coded URL/anon key. This client supports `auth` persistence for the mobile app.
  - `src/lib/supabase.js` — used by the data screens (`ExploreScreen`, `CreatorScreen`, `GlowScreen`, `VentScreen`) and `useRealtimeCounts`. It expects `process.env.EXPO_PUBLIC_SUPABASE_URL` and `EXPO_PUBLIC_SUPABASE_ANON_KEY` (the `.env` workflow). It prints a console error if the env vars are missing.
- When making changes to auth or realtime flows, be careful which client the code imports.

## Key patterns and conventions

- Data normalization: screens read snake_case columns (`created_at`) straight from Supabase. `VentScreen` is the exception and maps to `createdAt` locally; follow the local-mapping pattern rather than adding a global normalizer.
- Realtime updates: `src/hooks/useRealtimeCounts.js` subscribes to `postgres_changes` and calls `supabase.removeChannel(...)` on cleanup. Match that subscribe/unsubscribe pattern when adding channels.
- Ordering columns differ per table: `glow_sessions` has `started_at`/`completed_at` and **no** `created_at`, so order it by `started_at`. `glow_posts`, `sparks`, `vents`, `vent_posts` and `moods` all have `created_at`.
- UI structure: screens live in `src/screens/*`, components in `src/components/*`, theme in `src/theme/*` and `constants/theme.ts`.

## Developer workflows and gotchas

- Starting the app (recommended):
  - `npm install`
  - `npx expo start -c`
- The README references `npm run reset-project` but `package.json` does not define that script. To run the reset tool, call `node scripts/reset-project.js` manually. The script moves existing starter code into `app-example` and scaffolds `app/`.
- Use `npm run lint` and `npm run format` before submitting PRs.

## Where to look for common tasks (examples)

- Add authentication-related changes: `src/context/AuthContext.js`, `src/lib/supabaseClient.js`.
- Add new realtime table handling: `src/hooks/useRealtimeCounts.js` (see the subscription setup).
- Add screens or navigation: `src/navigation/*`, `src/screens/*`, `App.js`.
- Update Supabase env keys: prefer `src/lib/supabase.js` and `.env` variables (`EXPO_PUBLIC_SUPABASE_*`) for non-committed secrets; avoid changing the hard-coded key in `supabaseClient.js` without consent.

## How the UI expects data

- Screens read `created_at` directly; only `VentScreen` maps it to `createdAt`, and it does so locally.
- Lists are ordered newest-first — `created_at` descending on most tables, `started_at` descending on `glow_sessions`.

## Row Level Security (affects every write)

- RLS is enabled on all public tables, and policies are permissive, meaning they are **OR-ed** together. Adding a `using (true)` policy therefore widens access for everyone; it never narrows it.
- `glow_posts`, `glow_sessions`, `sparks`, `vents` and `moods` are **device-scoped, not user-scoped**. They have a `device_id` column and no `user_id`. Their policies check `exists (select 1 from device_users du where du.device_id = <table>.device_id and du.id = auth.uid())`.
- Because of that, **any insert into those tables must set `device_id`** to the current user's `device_users` row. Omitting it makes the check fail and the insert is denied.
- `posts`, `vent_posts` and `profiles` are user-scoped and keyed on `user_id` (or `id` for `profiles`).

### Always drop policies by their verified live name

Before writing `drop policy`, query the real names:

```sql
select policyname, cmd, roles::text, qual
from pg_policies where schemaname = 'public' and tablename = '<table>';
```

`drop policy if exists` on a name that does not exist is a silent no-op. Two separate migrations in this repo were written against invented, prose-style policy names (`"Users can read their own posts"`) when the live policies were named `posts_read_visible`, `posts_select_public`, and so on. Because the drops matched nothing, the over-permissive policy survived and the new policies were merely OR-ed on top of it. **Both migrations would have appeared to succeed and changed nothing.**

This is the failure mode to watch for: since permissive policies only ever widen access, a migration that means to *restrict* access is doing nothing unless it drops the exact policy that grants too much. Verify by role afterwards rather than trusting the policy list:

```sql
begin; set local role anon; select count(*) from public.<table>; rollback;
```
- `profiles` is readable by any signed-in user (`profiles_select_authenticated`) but **not** by anonymous callers. Do not add a policy granting `select` to the `public` or `anon` role — the anon key ships inside the app, so that exposes every profile row, including `email`, to anyone who extracts it.

## Security / commit guidance for agents

- Do not commit private keys. If you need to change secrets, prefer environment variables and document how to set them (use `EXPO_PUBLIC_SUPABASE_URL` and `EXPO_PUBLIC_SUPABASE_ANON_KEY`).

## Useful search tokens for an agent

- `AuthContext`, `supabaseClient`, `useRealtimeCounts`, `EXPO_PUBLIC_SUPABASE`, `device_users`, `device_id`, `created_at`.

---

If any section is unclear or you want me to expand examples (e.g., show how to add a new realtime listener or add a new screen), tell me which area to expand. I can iterate on this file.
