-- APPLIED 2026-09-07 as migration `moodsync_foundation`; verified by role.
--
-- Makes mood_states usable as MoodSync's history layer, and removes the dead
-- device-scoped mood tables.
--
-- The split confirmed on 2026-09-07 against the live database:
--
--   user_states   user_id uuid NOT NULL (PK), mood_tag, energy_level,
--                 low_energy_mode, active_mode        -- 2 rows, LIVE
--   mood_states   user_id uuid NULL, mood, intensity  -- 0 rows, no app code
--   moods         device_id text                      -- 0 rows, no app code
--   mood_events   device_id text                      -- 0 rows, no app code
--
-- user_states stays the current-state store it already is; app_provider.dart
-- and user_service.dart read mood_tag from it today and are not touched here.
-- mood_states becomes the history log behind it, which is what Blueprint 5.6.3
-- needs: Aura is a pattern derived from mood over time, and a pattern cannot
-- be derived from a single current-value row.


-- 1. user_id must not be nullable.
--
-- Every mood_states policy scopes on `auth.uid() = user_id`. A NULL user_id
-- matches no one, so such a row is invisible to every caller -- unreadable,
-- undeletable through the API, and silently excluded from any history query.
-- The table is empty, so this cannot fail on existing rows.

alter table public.mood_states alter column user_id set not null;


-- 2. created_at must be timestamptz.
--
-- It is currently `timestamp without time zone`. PostgREST serialises those
-- with no zone suffix, and Dart's DateTime.parse reads an unsuffixed string as
-- device-local while the server writes UTC -- every value comes back shifted by
-- the device's offset. That exact bug was already found and fixed on the client
-- side in ChatService._dateFrom for messages.created_at; fixing the column type
-- here means MoodSync never needs the same workaround.
--
-- `at time zone 'utc'` reinterprets the existing naive values as UTC rather
-- than as server-local. With 0 rows this is a formality, but it is the correct
-- conversion and would matter on a re-run against a populated table.

alter table public.mood_states
  alter column created_at type timestamptz
  using created_at at time zone 'utc';

alter table public.mood_states
  alter column created_at set default now();


-- 3. History reads need an index.
--
-- Every MoodSync query is "this user's moods, newest first" -- both the RLS
-- check and the ORDER BY. Only the pkey on id exists today.

create index if not exists mood_states_user_created_idx
  on public.mood_states (user_id, created_at desc);


-- 4. Deleting a profile must not be blocked by mood history.
--
-- mood_states_user_id_fkey references profiles(id) with no ON DELETE action,
-- so deleting a profile that has mood history would fail on the FK. Every
-- comparable table -- user_states, messages, posts -- already cascades.
-- Emotional history is exactly the data that should not survive the account
-- it belongs to.

alter table public.mood_states drop constraint if exists mood_states_user_id_fkey;
alter table public.mood_states
  add constraint mood_states_user_id_fkey
  foreign key (user_id) references public.profiles(id) on delete cascade;


-- 5. Sanity bound on intensity.
--
-- The Blueprint describes emotional intensity qualitatively (5.6.3, 4.x) but
-- never defines a numeric scale, so this is deliberately NOT the product
-- scale -- it is a guardrail wide enough to accept 1-5, 1-10 or 0-100 while
-- rejecting negatives and absurd values. Narrow it once the scale is decided.
-- NULL is still allowed: intensity is optional, mood alone is a valid entry.

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'mood_states_intensity_range') then
    alter table public.mood_states
      add constraint mood_states_intensity_range
      check (intensity is null or intensity between 0 and 100);
  end if;
end $$;


-- 6. Drop the device-scoped mood tables.
--
-- moods and mood_events are keyed by `device_id text` and predate auth. No Dart
-- file references device_id anywhere in the app, and both tables are empty.
-- They are also two of the members of the supabase_realtime publication, so
-- they consume replication slots to broadcast changes that nothing writes and
-- nothing subscribes to.
--
-- Verified before writing this: 0 rows in each, and no view, matview or other
-- relation depends on either.
--
-- Removed from the publication explicitly first. DROP TABLE would do this
-- implicitly, but doing it in the open keeps the publication change visible in
-- the migration rather than as a side effect.

alter publication supabase_realtime drop table public.moods;
alter publication supabase_realtime drop table public.mood_events;

drop table public.moods;
drop table public.mood_events;

-- NOT dropped: public.device_users. Also device-keyed, also 0 rows, also in
-- the publication -- but it is not part of MoodSync, and removing it is a
-- separate decision about whether pre-auth device identity is coming back.

-- Verified after applying, by role, in a rolled-back transaction:
--   Darcell sees = 3 rows;  targeted read of OTHER user history = 0 (private)
--   test2   sees = 1 rows;  targeted read of DARCELL history    = 0 (private)
--   test2 writing a row as Darcell: blocked (42501)
--   anon sees = 0 rows
--   created_at is timestamptz: true
--   intensity 999: rejected (23514)
--   moods / mood_events remaining: 0
--   supabase_realtime public members: 9 -> 7
