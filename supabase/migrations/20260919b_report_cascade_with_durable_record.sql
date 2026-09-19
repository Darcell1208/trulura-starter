-- APPLIED 2026-09-19 to project wzcuxarslnbvaosuqduu as
-- `report_cascade_with_durable_record`.
--
-- SAFE TO REPLAY. Every statement is idempotent: `add column if not exists`,
-- `drop constraint if exists` before re-adding, `create or replace function`,
-- and `drop trigger if exists` before re-creating. The backfill is a bounded
-- UPDATE guarded by `is null`, so re-running rewrites nothing.
--
-- PRODUCT OWNER RULING, 2026-09-19 (option four):
--
--   "Cascade the report, write a contentless durable record to
--    moderation_events first -- that a report existed, against whom, and how
--    it closed. No content retained anywhere.
--
--    One addition: capture the author on the report at file time in its own
--    column, populated from messages.sender_id. Not a target, so it doesn't
--    collide with reports_exactly_one_target. Without it the durable record
--    can't name who was reported.
--
--    No snapshotting. It turns a bounded hold into indefinite retention of the
--    content we promised would vanish, in a table with no expiry of its own."
--
-- WHY CASCADE IS NOW SAFE, WHEN 20260908 REJECTED IT
--
-- That migration rejected CASCADE because it "would destroy the report when
-- the reported content is deleted, which is exactly when the report matters
-- most." That reasoning held while nothing survived the deletion. It no longer
-- does: the BEFORE DELETE trigger below writes a contentless record to
-- moderation_events first, so what survives is the fact of the report, who it
-- named, and how it closed -- everything except the content the user was
-- promised would disappear.
--
-- The hold is unchanged. purge_expired_messages() still refuses to delete a
-- message whose report is queued or reviewing. CASCADE only applies once a
-- report has closed (actionTaken or dismissed), which is the point at which
-- the ruling says the hold releases.


-- 1. Capture the author at file time.
--
-- Deliberately NOT a target column: reports_exactly_one_target counts the four
-- target_* columns, and this is attribution, not a target. A message report
-- currently carries target_user_id NULL, so the author of a reported message
-- is knowable only by joining to messages.sender_id -- which fails the moment
-- the message is gone. Build Status known issue 37.
--
-- ON DELETE SET NULL, not NO ACTION: an author deleting their account must not
-- be blocked by an open report against them, and must not silently fail. The
-- durable copy in moderation_events carries no foreign key at all, so the
-- author id survives there even when the profile row does not.
alter table public.reports
  add column if not exists target_message_author_id uuid
    references public.profiles (id) on delete set null;

create index if not exists reports_target_message_author_id_idx
  on public.reports (target_message_author_id)
  where target_message_author_id is not null;

-- Backfill any existing message reports. Guarded by `is null` so replay is a
-- no-op. (There are 0 reports at time of writing; this is for correctness, not
-- for the current data.)
update public.reports r
   set target_message_author_id = m.sender_id
  from public.messages m
 where r.target_message_id = m.id
   and r.target_message_author_id is null;


-- 2. Populate it automatically, so a client cannot forget.
--
-- A trigger rather than client code: reporting_service.dart is one caller
-- today, but the column has to be right for every future caller and for rows
-- inserted from the dashboard. SECURITY DEFINER so the lookup against messages
-- is not blocked by that table's RLS (messages_select_member would otherwise
-- hide a message the reporter can see but the executing role cannot).
create or replace function public.reports_capture_message_author()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.target_message_id is not null
     and new.target_message_author_id is null then
    select m.sender_id
      into new.target_message_author_id
      from public.messages m
     where m.id = new.target_message_id;
  end if;
  return new;
end;
$$;

drop trigger if exists reports_capture_message_author_trg on public.reports;
create trigger reports_capture_message_author_trg
  before insert or update of target_message_id on public.reports
  for each row execute function public.reports_capture_message_author();


-- 3. The durable record, written BEFORE the report row disappears.
--
-- Contentless by construction: it can only write the author id, the report's
-- reason enum, its status at deletion, and the report id. There is no column
-- here that could hold message text even by accident -- moderation_events is
-- (id, user_id, action, reason, created_at) and nothing more.
--
-- This fires on EVERY delete of a report, not only the expiry cascade. That is
-- deliberate: reports.reported_by_user_id is ON DELETE CASCADE, so a reporter
-- deleting their account destroys their own open reports (Build Status known
-- issue 36). This trigger means the fact of the report now survives that too.
create or replace function public.record_report_removal()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.moderation_events (id, user_id, action, reason, created_at)
  values (
    gen_random_uuid(),
    coalesce(old.target_message_author_id, old.target_user_id),
    'report_removed:' || coalesce(old.status, 'unknown'),
    'reason=' || coalesce(old.reason, 'unknown')
      || ' report_id=' || old.id::text
      || ' had_message_target=' || (old.target_message_id is not null)::text,
    (now() at time zone 'utc')
  );
  return old;
end;
$$;

drop trigger if exists record_report_removal_trg on public.reports;
create trigger record_report_removal_trg
  before delete on public.reports
  for each row execute function public.record_report_removal();


-- 4. Release the hold when the report closes.
--
-- NO ACTION -> CASCADE. Until now a closed report still referenced its
-- message, so the purge would fail the foreign key and roll back the whole
-- sweep -- deleting nothing, silently, for everyone. Build Status known issue
-- 35 records that the abort deletes nothing rather than destroying anything.
alter table public.reports
  drop constraint if exists reports_target_message_id_fkey;

alter table public.reports
  add constraint reports_target_message_id_fkey
    foreign key (target_message_id)
    references public.messages (id)
    on delete cascade;

revoke all on function public.reports_capture_message_author() from public;
revoke all on function public.reports_capture_message_author() from anon;
revoke all on function public.reports_capture_message_author() from authenticated;
revoke all on function public.record_report_removal() from public;
revoke all on function public.record_report_removal() from anon;
revoke all on function public.record_report_removal() from authenticated;

comment on column public.reports.target_message_author_id is
  'Author of the reported message, captured at file time from messages.sender_id '
  'by trigger. Not a target: reports_exactly_one_target does not count it. '
  'Exists so a report can name who was reported after the message is gone.';


-- VERIFY AFTER APPLYING -- do not trust the exit status.
--
--   -- the FK must now be CASCADE
--   select conname, confdeltype from pg_constraint
--    where conname = 'reports_target_message_id_fkey';   -- expect 'c'
--
--   -- end to end, rolled back:
--   begin;
--     insert into reports (reported_by_user_id, target_message_id, reason, status)
--       values (<a profile id>, <a message id>, 'other', 'dismissed');
--     -- author must be populated by the trigger, not by the insert
--     select target_message_author_id from reports order by created_at desc limit 1;
--     delete from messages where id = <that message id>;
--     -- the report is gone, and a contentless record remains
--     select count(*) from reports where target_message_id = <that message id>;
--     select user_id, action, reason from moderation_events
--      order by created_at desc limit 1;
--   rollback;
