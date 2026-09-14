-- APPLIED 2026-09-14 as migration `handle_new_user_null_username` (version 20260914132443).
-- Idempotent: `create or replace function` can be re-run safely.
--
-- ============================================================================
-- THE BUG
-- ============================================================================
--
-- handle_new_user (trigger on_auth_user_created, AFTER INSERT ON auth.users)
-- wrote split_part(new.email, '@', 1) into public.profiles.username, which is
-- UNIQUE (profiles_username_key). `on conflict (id) do nothing` guards
-- duplicate ids, not duplicate usernames. So the second address with the same
-- local part -- alex@ at two domains -- raised unique_violation inside the
-- trigger, and the whole signup transaction rolled back. GoTrue answers 500
-- "Database error saving new user", which the client labels retryable.
--
-- Reproduced before fixing, 2026-09-14, by inserting two auth.users rows with
-- the same local part in a rolled-back transaction:
--   ERROR 23505: duplicate key value violates unique constraint
--   "profiles_username_key"  Key (username)=(zzprobe-collide) already exists.
--
-- ============================================================================
-- THE FIX
-- ============================================================================
--
-- New profiles get username = NULL. UNIQUE allows many NULLs.
-- display_name stays email-derived until the display_name naming decision
-- (IC-4 in TruLura_Build_Status.md).
--
-- Two client changes ship in the same commit. Both are required; without
-- either, the collision comes back by another route.
--
--   1. UserService._persistProfile writes NULL, not '', for an empty username.
--      '' is a value, and UNIQUE allows it once. Without this, the collision
--      moves from signup to the second new account's first profile save.
--
--   2. UserService.getCurrentUser takes username from the fetched profiles row
--      only, empty included. It used to fall back to the device-global
--      current_user cache. Product Owner, 2026-09-14: without this "a new
--      account on a shared device inherits a cached username and saves it
--      back -- the same collision by another route."
--
-- ============================================================================
-- WHAT THIS DOES NOT DO
-- ============================================================================
--
-- - Existing usernames are untouched: 3 rows, none NULL.
-- - display_name remains email-derived, and it is readable by other signed-in
--   users through public.profiles_public (20260914_profiles_scope_reads.sql).
-- - AppProvider's hydrate still falls back to the auth metadata username
--   (app_provider.dart). That is decided with the IC-4 row clearing, not here.
-- - Clients built from code before this change still write '' for an empty
--   username. For accounts created from now on, the second such save fails,
--   and saveUser swallows the error, until those clients are rebuilt.


create or replace function public.handle_new_user()
 returns trigger
 language plpgsql
 security definer
 set search_path to 'public'
as $function$
begin
  insert into public.profiles (id, username, display_name, avatar_url, created_at, updated_at)
  values (
    new.id,
    null,
    split_part(new.email, '@', 1),
    null,
    now(),
    now()
  )
  on conflict (id) do nothing;

  insert into public.user_states (user_id, active_mode, mood_tag, energy_level, low_energy_mode, updated_at)
  values (new.id, 'social', null, null, false, now())
  on conflict (user_id) do nothing;

  insert into public.privacy_settings (user_id, allow_messages, allow_matching, anonymous_mode, screenshot_protection)
  values (new.id, true, true, false, false)
  on conflict (user_id) do nothing;

  return new;
end;
$function$;


-- VERIFIED 2026-09-14, after applying, against the live function. The probe
-- inserted two auth.users rows sharing a local part and was rolled back, so no
-- accounts were created:
--
--   profiles created:            2
--   with username NULL:          2
--   display_name email-derived:  2
--   no unique_violation
--
--   pg_get_functiondef(handle_new_user) now inserts null for username.
--   Existing rows: 3, none with a NULL username.
