import AsyncStorage from '@react-native-async-storage/async-storage';
import { createClient } from '@supabase/supabase-js';
import 'react-native-url-polyfill/auto';

// READ THIS BEFORE RUNNING THIS APP.
//
// This Expo app is an earlier prototype, superseded by the Flutter app in
// `lib/`. It is kept for reference, not developed: `src/` has two commits in
// its whole history, and the later one only deleted dead code. It nonetheless
// owns the repo's root `package.json`, so plain `npm start` runs *this*, which
// is the trap — the URL and anon key below used to be hardcoded, pointing a
// throwaway prototype straight at the production Supabase project.
//
// They now come from the environment, matching `./supabase.js`, so a clone
// without a `.env` fails loudly here instead of silently reaching production.
// The previous literals remain in git history; the anon key is publishable by
// design, so this is about where the app points, not about a leaked secret.
//
// It cannot currently read or write anything regardless. This file's client is
// the only one holding a session (AsyncStorage, below), but the data screens
// — GlowScreen, VentScreen, ExploreScreen, CreatorScreen — import the separate
// client in `./supabase.js`, which has no session storage and therefore calls
// the API as `anon`. Every policy on glow_posts, glow_sessions, sparks and
// vent_posts is scoped to `authenticated`, with no anon policy at all, so anon
// sees zero rows and every anon insert is refused. Verified by role against the
// live database on 2026-09-09; all four tables are empty, having never been
// written. Do not "fix" that by widening the policies.
const SUPABASE_URL = process.env.EXPO_PUBLIC_SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  console.error(
    'Missing EXPO_PUBLIC_SUPABASE_URL or EXPO_PUBLIC_SUPABASE_ANON_KEY. Check your .env file.'
  );
}

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});
