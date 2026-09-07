-- APPLIED 2026-09-07 as migration `messaging_realtime`. Live chat is ON.
--
-- Deliberately separate from 20260904_pending_messaging_core.sql. Messaging
-- works without this: the screens load on open, refresh on pull, and refetch
-- after a send. This migration is what turns on push.
--
-- Checked 2026-09-07: the supabase_realtime publication contains exactly
-- device_users, glow_sessions, mood_events, moods, sparks and vents in the
-- public schema. messages is NOT in it -- like posts and post_reactions,
-- whose subscriptions have therefore never fired once. Adding a
-- postgres_changes subscription to the app without this migration would
-- reproduce that bug: a subscribe() that silently never delivers.
--
-- Only messages is added. conversations and conversation_members change on
-- conversation creation, which is already a user-initiated action the client
-- knows the outcome of; subscribing to them would spend a connection to learn
-- something the RPC's return value already said.


-- 1. Publication membership.
--
-- Guarded: `alter publication ... add table` errors if the table is already a
-- member, which would make a re-run fail rather than no-op.

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;


-- 2. Replica identity.
--
-- messages is currently relreplident = 'd' (default), so an UPDATE or DELETE
-- puts only the primary key in the WAL for the old row. Realtime evaluates
-- RLS against the row it is about to deliver; with only an id it cannot tell
-- whether the subscriber was a member of that conversation, so it withholds
-- the event. INSERTs are unaffected -- they carry the whole new row -- so a
-- chat that only ever appends would appear to work while deletes silently
-- never arrive.
--
-- FULL makes the complete old row available. The cost is WAL volume, which is
-- proportional to row size; messages rows are small (a uuid pair, a short
-- text, a timestamp), so this is cheap here.

alter table public.messages replica identity full;


-- 3. Privilege probe.
--
-- Realtime decides deliverability by re-running a visibility check as the
-- subscriber's role. That check fails at the privilege layer, before RLS is
-- consulted, if the role has no SELECT on the table -- the failure mode
-- documented at length in 20260904_revoke_posts_direct_select.sql.
--
-- authenticated already holds table-level SELECT on public.messages, so the
-- probe passes and messages_select_member then restricts delivery to
-- conversation members. Nothing to grant; this comment exists so a future
-- reader who revokes that SELECT knows it will also silence live chat.
--
-- anon holds no SELECT after the core migration's section 7, so anonymous
-- subscribers receive nothing, which is correct.
