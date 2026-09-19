-- APPLIED 2026-09-19 to project wzcuxarslnbvaosuqduu, after Product Owner
-- review, as migration `message_expiry_with_report_hold`.
--
-- SAFE TO REPLAY, with one caveat. Every statement is idempotent:
-- `add column if not exists`, `create index if not exists`, and
-- `create or replace function`. Re-running changes nothing and destroys
-- nothing. The caveat is the usual one for `add column if not exists`: if some
-- other session has since altered expires_at's type or given it a default,
-- this file will report success and silently leave that alteration in place.
-- Verify with the read-back query in section 3 rather than trusting the exit
-- status.
--
-- VERIFIED AFTER APPLYING, against the live database:
--   * expires_at exists as timestamptz, nullable, no default
--   * purge_expired_messages() exists and is SECURITY DEFINER
--   * EXECUTE is granted to none of public, anon, authenticated
--   * messages_expires_at_idx exists
--   * purge_expired_messages() was executed for real and returned 0, with all
--     6 existing rows carrying a null expiry. Null means never-expires, proven
--     on live data rather than argued from the predicate.
--
-- STILL NOT DONE: nothing calls this function on a schedule. pg_cron is not
-- installed on this project. Until a schedule exists, expiry remains unbuilt
-- and the UI must not promise it. See the ordering note at the bottom.
--
-- WHY THIS EXISTS
--
-- Ephemeral messaging promises disappearance and delivers nothing. Measured
-- against the live database on 2026-09-19:
--
--   * public.messages has columns id, conversation_id, sender_id, content,
--     created_at. There is NO expires_at column.
--   * The client computes an expiry when sending
--     (chat_thread_screen.dart:297-299) but chat_service.dart:646-650 inserts
--     only conversation_id, sender_id and content. The expiry is never sent.
--   * Message.fromJson therefore always reads expiresAt as null, so the
--     client-side hide at chat_service.dart:599 can never fire -- and that
--     branch is inside the local-stub path anyway, never the remote one.
--   * pg_cron is not installed, messages has no triggers, and no routine with
--     'expir' in its name exists. Nothing deletes anything, ever.
--
-- So sensitive content persists indefinitely behind a control that says it
-- will not. That is the failure this migration addresses.
--
-- PRODUCT OWNER RULING, 2026-09-19: "Reported content is held. Expiry deletes
-- for everyone else; a report places a hold and the content is retained until
-- review closes. The schema already takes this position -- it prevents
-- deleting reported messages -- so expiry is what has to accommodate it, not
-- the reverse."
--
-- The schema position referred to is real and deliberate:
-- 20260908_reports_targets_and_status.sql leaves ON DELETE at NO ACTION for
-- reports.target_message_id, so a reported message cannot be hard-deleted
-- while its report stands. A purge that ignored reports would not quietly
-- win -- it would raise a foreign key violation and abort the whole sweep,
-- taking unrelated expired messages with it. Excluding held messages is
-- therefore required for correctness, not only for policy.


-- 1. Store the expiry.
--
-- timestamptz, not `timestamp without time zone`. messages.created_at is
-- naive, which chat_service.dart:640-645 documents as a hazard it works around
-- by never sending created_at. A new column should not inherit that problem:
-- an expiry compared against now() must be unambiguous about its zone.
--
-- Nullable with no default: null means "this message does not expire", which is
-- the setting being off. A default would silently opt every existing and
-- future message into deletion.
alter table public.messages
  add column if not exists expires_at timestamptz;

-- `add column if not exists` skips the WHOLE clause when the column already
-- exists. If a concurrent session added expires_at with a different type or a
-- default, this statement reports success and changes nothing. Read the column
-- back after applying (see the verification block at the end) rather than
-- trusting the exit status.

create index if not exists messages_expires_at_idx
  on public.messages (expires_at)
  where expires_at is not null;


-- 2. The purge, with the report hold.
--
-- SECURITY DEFINER because public.messages has RLS enabled with only
-- messages_insert_sender_member (INSERT) and messages_select_member (SELECT).
-- There is no DELETE policy, so no client role can delete a message at all.
-- That is deliberate and is NOT changed here: adding a client DELETE policy
-- would let a participant destroy evidence, which is the opposite of the
-- ruling. Deletion stays a privileged, scheduled operation.
--
-- The hold: a message is retained while any report naming it is still open.
-- reports_status_enum allows queued, reviewing, actionTaken, dismissed.
-- Open  = queued, reviewing        -> hold, do not delete
-- Closed = actionTaken, dismissed  -> release, may delete once expired
--
-- Note what this does NOT do: it does not delete a held message at the moment
-- its review closes. It deletes it on the next sweep after closure, because
-- expires_at is already in the past by then. A message held through review is
-- therefore retained slightly longer than its TTL, which is the intended
-- behaviour rather than an accident.
create or replace function public.purge_expired_messages()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  deleted_count integer;
begin
  with doomed as (
    delete from public.messages m
    where m.expires_at is not null
      and m.expires_at <= now()
      and not exists (
        select 1
        from public.reports r
        where r.target_message_id = m.id
          and r.status in ('queued', 'reviewing')
      )
      -- A report naming the whole conversation holds its messages too. A
      -- reviewer reading a reported thread needs the thread, not the surviving
      -- half of it.
      and not exists (
        select 1
        from public.reports r
        where r.target_conversation_id = m.conversation_id
          and r.status in ('queued', 'reviewing')
      )
    returning 1
  )
  select count(*) into deleted_count from doomed;
  return deleted_count;
end;
$$;

revoke all on function public.purge_expired_messages() from public;
revoke all on function public.purge_expired_messages() from anon;
revoke all on function public.purge_expired_messages() from authenticated;

comment on function public.purge_expired_messages() is
  'Deletes expired messages except those held by an open report (queued or '
  'reviewing) on the message or its conversation. Privileged: messages has no '
  'DELETE policy by design. Returns the number of rows deleted.';


-- 3. VERIFY AFTER APPLYING -- do not trust the exit status.
--
--   select column_name, data_type, is_nullable, column_default
--   from information_schema.columns
--   where table_schema='public' and table_name='messages'
--     and column_name='expires_at';
--   -- expect: timestamptz, YES, null
--
--   begin;
--     -- nothing should be deleted while a report is open
--     select public.purge_expired_messages();
--   rollback;


-- ORDERING -- READ BEFORE APPLYING
--
-- 1. Apply this migration FIRST. Until expires_at exists, a client that sends
--    it gets a PostgREST error on an unknown column and the send fails.
-- 2. Only then ship the client change that sends expires_at on insert and
--    filters expired rows on read.
-- 3. The UI copy must not promise disappearance until steps 1 and 2 are live.
--    Stating "disappears for everyone, retained if reported until review
--    closes" while nothing expires would replace one false promise with a
--    more detailed false promise.
--
-- STILL REQUIRED, AND NOT DONE BY THIS FILE: something must CALL
-- purge_expired_messages() on a schedule. pg_cron is not installed on this
-- project (verified 2026-09-19). Until a schedule exists, this function is
-- correct and never runs, and the deletion promise remains unkept. See the
-- database-admin steps recorded alongside this migration.
