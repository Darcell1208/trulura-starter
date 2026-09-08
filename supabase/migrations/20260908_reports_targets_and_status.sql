-- APPLIED 2026-09-08 as migration `reports_targets_and_status`. Every
-- statement here is `add column` / `add constraint` without IF NOT EXISTS, so
-- a replay fails loudly on the first duplicate rather than half-applying.
--
-- Feature 5, phase 1 of 3: give `reports` the two target types the app can
-- already produce, a categorised reason, and an internal triage status.
--
-- Written against the live schema read on 2026-09-08. Before this migration
-- the table was: id, reported_by_user_id, target_user_id, target_post_id,
-- reason_text, created_at. RLS on, two policies, both TO authenticated:
-- reports_insert_self (with check reported_by_user_id = auth.uid()) and
-- reports_select_own (same predicate). No UPDATE or DELETE policy, so a report
-- cannot be edited or withdrawn once filed. That stays true here.
--
-- The gap being closed: lib/services/reporting_service.dart declares
-- TruSafetyTargetType { user, post, message, chat }, and the UI already emits
-- all four -- chat_thread_screen.dart:839 pushes the report route with
-- type=chat, trulura_profile_preview_sheet.dart:223 with type=user -- while
-- the table had columns for only two of them. A chat report had nowhere to go.


-- 1. Targets: four typed columns, not a polymorphic pair.
--
-- The alternative considered was replacing all four with target_type +
-- target_id. Rejected because a polymorphic uuid cannot carry a foreign key:
-- by construction it accepts any value, including one that references nothing.
-- A report is evidence in a moderation decision, so a target that silently
-- points at a deleted row makes the report unreviewable, and the database
-- would not object at write time. That is the same failure shape as a
-- statement that succeeds without doing what it says.
--
-- Cost accepted deliberately: a fifth target type will require a migration
-- here. That is the same trade user_states_mood_tag_enum took -- a migration
-- that fails loudly beats a value that silently never resolves.
--
-- ON DELETE is left at NO ACTION, matching the two existing target FKs rather
-- than the CASCADE used on reported_by_user_id. The asymmetry is intentional:
-- CASCADE would destroy the report when the reported content is deleted, which
-- is exactly when the report matters most. SET NULL is not available either --
-- it would leave a row with zero targets and violate the check below. So a
-- reported message cannot be hard-deleted while its report stands. Nothing in
-- the app deletes messages or conversations today, so this blocks no existing
-- path; if one is added later it must resolve the report first, which is the
-- correct order of operations anyway.

alter table public.reports
  add column target_message_id uuid references public.messages (id),
  add column target_conversation_id uuid references public.conversations (id);

create index if not exists reports_target_message_id_idx
  on public.reports (target_message_id);
create index if not exists reports_target_conversation_id_idx
  on public.reports (target_conversation_id);


-- 2. Exactly one target.
--
-- Without this a report can name four things at once, or -- the case that
-- exists today -- nothing at all: both target columns were nullable with no
-- constraint, so an insert naming no target has always been accepted. The
-- boolean-to-int sum is the readable way to say "exactly one" across four
-- columns.

alter table public.reports
  add constraint reports_exactly_one_target
  check (
    (target_user_id         is not null)::int
  + (target_post_id         is not null)::int
  + (target_message_id      is not null)::int
  + (target_conversation_id is not null)::int
    = 1
  );


-- 3. A categorised reason, alongside the free text that was already here.
--
-- reason_text stays as the user's own words ("Details (optional)" in
-- report_screen.dart). `reason` is the category chosen from the dropdown.
-- Values are TruReportReason.name verbatim -- camelCase, stored as the Dart
-- enum spells it, so no mapping layer can drift out of sync. This follows the
-- precedent set for user_states.mood_tag, which stores Mood.name.
--
-- NOT NULL is set as its own statement rather than inline. `add column ... not
-- null` is fine on an empty table, but this repo has already been bitten by
-- DDL that silently skips part of what it reads like, so the constraint is
-- applied and verified separately.

alter table public.reports add column reason text;

alter table public.reports
  add constraint reports_reason_enum
  check (reason in ('harassment', 'hate', 'sexualContent', 'scamOrFraud',
                    'selfHarm', 'impersonation', 'underage', 'other'));

alter table public.reports alter column reason set not null;


-- 4. Status: internal triage only, never rendered.
--
-- Product decision by Darcell, 2026-09-08: add the column, never show it in
-- the UI, and leave reports_select_own in place. The reporter can therefore
-- read the status of their own report through the API, but the app will not
-- display it. That is deliberate -- until there is a human doing triage, a
-- visible status would promise follow-up that nobody is performing, and a
-- report stuck on 'queued' forever reads worse than no status at all.
--
-- No UPDATE policy exists on this table, so no authenticated user can move a
-- report between states. Only service_role, which bypasses RLS, can. That is
-- the correct writer for a moderation decision.
--
-- Values are TruModerationStatus.name verbatim, same reasoning as `reason`.

alter table public.reports
  add column status text not null default 'queued';

alter table public.reports
  add constraint reports_status_enum
  check (status in ('queued', 'reviewing', 'actionTaken', 'dismissed'));


-- Deliberately NOT included:
--
-- * A generated target_type discriminator. The client derives the type from
--   which column is non-null; a stored copy is one more thing that can
--   disagree with the data it describes.
-- * A check that reported_by_user_id <> target_user_id. Self-reporting is
--   harmless and occasionally meaningful (reporting your own post to get it
--   removed), so there is nothing to prevent.
-- * Any change to the two existing policies. Insert-own and select-own were
--   already correct for this feature.
