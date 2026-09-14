# TruLura write audit — record, 2026-09-14

Source: live capture against `localhost:8123` (DDC dev build) with a fetch/XHR interceptor on `/rest/v1/profiles` and `/rest/v1/matchmaking_profiles`, plus Supabase edge logs for 02:05–02:12 UTC. Trigger for the capture: identity-mode flip Friendship → Dating → Friendship (net zero; final DB state `active_identity_mode = friendship`).

## 1. `_SafetyVerificationScreenState.build` calls `saveUser`

Confirmed call site in the compiled bundle. A write inside `build` runs on every rebuild. **Decision:** move it to an explicit user action — the handler of the control that changes the fields that screen owns (`showVerificationBadge`, `showTrustIndicator`, `profileVisibility`, `allowScreenshots`, `messageAutoDelete`), or a Save button. `build` reads only.

## 2. `saveUser` persists the whole cached `User`, and `User()` seeds defaults

`User()` constructor defaults: `temperament = oldSoul`, `activeIdentityMode = social`, `trustScore = 70`, `riskLevel = low`, `profileVisibility = public`, `showVerificationBadge = true`, `showTrustIndicator = true`, `allowScreenshots = true`, `verificationLevel = level0`. `fromJson` substitutes the same defaults on read (`temperament ?? oldSoul`, `vibe_status ?? oldSoul`). So "not answered" and "answered with the default" are the same object, both when the user is fresh and when it has been hydrated from a row with nulls.

Callers of `saveUser`: `_ProfileSetupScreenState._finish`, `_OnboardingVibeScreenState._continue`, `_OnboardingIntentScreenState._continue`, `_OnboardingIdentitySetupScreenState._save`, `IdentityService.applyToCachedUser`, `UserService.saveInterests`, `_SafetyVerificationScreenState.build`.

Options considered:

- **A. Refuse to save an unhydrated user.** `hydrated`/`loadedAt` flag set only after a successful Supabase read; `saveUser` no-ops or throws otherwise. Stops the fresh-`User()` path only.
- **B. Write only dirty fields.** Track which fields were set since hydration; `_persistProfile` builds its payload from that set. Stops both the fresh and the hydrated-with-defaults path from *writing* invented values.
- **C. Nullable model fields.** `temperament`, `activeIdentityMode`, `profileVisibility`, `trustScore`, … become `T?`; `fromJson` stops substituting; the UI supplies the display default at render time (`?? oldSoul`). `toJson` omits nulls naturally.
- **D. Server-side guard.** `BEFORE UPDATE` trigger on `profiles` refusing a default value over a null. Catches every client path; hard-codes app defaults in SQL; invisible from Dart. Not adopted.

**Decision (Product Owner, 2026-09-14): B plus A now. C is the real end state, not the expensive option.**
B and A stop the write; they do not stop the app from *believing* the defaults — a hydrated user still carries invented values before anything is saved, because `fromJson` substitutes them on read. C stops the belief. Same class as `_hasVibe` reading `temperament` as `vibe`.

> B and A stop the write. C stops the belief.

**Observed instance (see §4):** `IdentityService.applyToCachedUser` saved the whole cached `User` on a mode tap and re-persisted a stale `moodTags` value over `profiles.vibe`, which the Product Owner had deliberately nulled — three separate times (02:46:13, 02:52:14, 02:52:55 UTC). The write had nothing to do with vibe and overwrote it anyway. Dirty-field tracking would have written only `activeIdentityMode`. This is the case for B, observed rather than argued.

Product Owner, 2026-09-14: "Finding 2 is the whole case for B, observed rather than argued. A mode tap re-persisted `reflective` over a field you deliberately nulled, three separate times, because `applyToCachedUser` saves the whole cached object. The write had nothing to do with vibe and overwrote it anyway."

Product Owner, 2026-09-14, on `profiles.vibe`: "Leave `vibe` as `reflective` for now. Clearing it before B lands just means the next mode tap rewrites it, and you'd be testing the same bug twice."

## 3. The PATCH that 400s on every `saveUser`

Captured body:

```
PATCH /rest/v1/profiles?id=eq.<user>&select=id
{"temperament":"grounded"}
→ 400 {"code":"PGRST204","message":"Could not find the 'temperament' column of 'profiles' in the schema cache"}
```

Then, immediately:

```
PATCH /rest/v1/profiles?id=eq.<user>&select=id
{"vibe_status":"grounded"}
→ 200
```

So the 400 is a **column probe**, not a lost write: `_persistProfile` tries the `temperament` column first, the catch recognises `PGRST204` via `_isMissingColumnError`, and falls back to `vibe_status`. The value does persist — under `vibe_status`. Correction to the earlier note: the six-field "optional" PATCH (`social_preference`, `expression_prompt_answer`, `expression_vibe_tag`, `expression_short_post`, `active_identity_mode`, `anonymous_overlay_enabled`) is a *separate* request and returns 200; nothing in this path has been silently lost.

**Ruling (PO):** this is the half-finished `vibe_status → temperament` rename — the Dart side was renamed, the migration never ran. Not a new decision; a finished one.

**Done 2026-09-14 ~03:00 UTC:** migration `rename_profiles_vibe_status_to_temperament` applied — `alter table public.profiles rename column vibe_status to temperament` + PostgREST schema reload. Verified: `profiles.temperament` exists, `vibe_status` gone. No views, functions, or policies referenced the old name; every Dart reader tries `temperament` first, so nothing goes blind. The probe in `_persistProfile`/`_persistTemperament` (the `["temperament","vibe_status"]` list and the "neither column exists" branch) is now dead code — **delete it in the repo.**

Full per-save sequence as captured (7 requests):

1. `POST /profiles` upsert — `id, username, display_name, bio, about_me, profile_photo_url` (200)
2. `PATCH /profiles` `{"temperament":…}` (400, PGRST204)
3. `PATCH /profiles` `{"vibe_status":…}` (200)
4. `PATCH /profiles` optional six-field payload (200)
5. `PATCH /matchmaking_profiles` `{"active":true,"preferences":{"interests":[…]},"intent":"Friendship"}` (200)
6. `PATCH /profiles` `{"vibe":"reflective","updated_at":…}` (204)
7. `PUT /auth/v1/user` metadata (200)

Two side observations from the capture, not yet decided:

- `matchmaking_profiles.intent` stayed `"Friendship"` when the mode flipped to Dating — intent does not follow identity mode.
- `vibe` written as `"reflective"` while hub mood was Calm — **not a bug.** Vibe and mood are separate by ruling (Mood is a short-lived input to Aura State). `vibe=reflective` alongside `mood=calm` is the expected shape.

## 4. `profiles.vibe` nulled by hand, came back as `reflective`

Only writer: `_persistVibe(userId, moodTags)` → `vibe = _firstNonEmpty(moodTags)`, i.e. the first entry of the `User.moodTags` list. Edge logs for the last 24 h show no `profiles` writer other than the app's `saveUser` sequence; the `vibe` PATCH is in every burst (02:08:05, :06, :07, :13; 02:46:13; 02:52:14; 02:52:55 UTC — the last three are this session's identity-mode taps).

`IdentityService.applyToCachedUser` takes the **SharedPreferences-cached** `User`, sets the mode, and calls `saveUser` on the whole object. That cached user still had `moodTags = [reflective, …]`, so the mode switch wrote `vibe = reflective` back over the null. **This is section 2's mechanism, observed:** a stale cached value re-persisted by a whole-object save that had nothing to do with vibe. B (dirty-fields only) would have prevented it — the mode switch dirties `activeIdentityMode`, not `moodTags`.

## 5. `matchmaking_profiles.intent` did not follow the mode flip

`_persistMatchmaking` sets `intent = _firstNonEmpty(user.intents)` — the onboarding "I joined TruLura to:" list — not `activeIdentityMode`. Independent **by construction**, not by ruling: nothing in the code links identity mode to matchmaking intent. Whether Dating mode should imply a dating intent (or whether the two are meant to stay separate — one master identity, modes as lenses) is a Product Owner decision that hasn't been made. Logged as open (Class C).

Product Owner, 2026-09-14: "Not a missed write — no link at all. `intent` comes from onboarding and never consults `activeIdentityMode`. So someone in Dating mode can carry a Friendship intent indefinitely, and matchmaking reads the intent. That's a real product question: are modes lenses over one identity with intent separate, or does mode imply intent?"

## Status of repo-side work (as of this record)

Not yet done — needs the Claude Code session with repo access:
1. Delete the dead probe in `_persistTemperament` (the `["temperament","vibe_status"]` list and the "neither column exists" branch). Unreachable since the migration.
2. B plus A on `saveUser` (dirty-field payloads; refuse to save an unhydrated user).
3. Move the `saveUser` call out of `_SafetyVerificationScreenState.build` to an explicit user action.
4. Three `debugPrint`s for the Aura blank: `HomeFeedScreen.initState`, `HomeFeedScreen.dispose`, top of `HomeHubScreen.build`.

Done in this session (database only): the `vibe_status → temperament` rename migration.

## Also open

- Aura blank screen: not reproducible from a fresh load via Aura → Vent → back, Aura ↔ Sync, Aura ↔ Explore, Identity → Worlds, Connect → Worlds. The observed blank had HomeHub state reset (mood pill Calm → Reflective) with no `HomeFeedScreen._loadInitialPosts` log. Trace to add: `debugPrint` in `HomeFeedScreen.initState`/`dispose` and at the top of `HomeHubScreen.build`. Separate bug seen: `Sync._load` calls `setState` after dispose.
- `spark_interactions`: two rows created 02:07:37–38 UTC by stray clicks (to `test2`, `test3`); table already empty when deletion was attempted.
