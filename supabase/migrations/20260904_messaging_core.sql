-- ############################################################################
-- DO NOT RE-RUN THIS FILE. Replaying it reopens a privilege escalation.
--
-- Section 4 below creates `conversation_members_insert_own` and
-- `conversations_insert_authenticated`. Both were dropped on purpose by
-- 20260907_close_self_join_hole.sql, because `with check (user_id = auth.uid())`
-- restricts WHO you may add but not WHICH conversation you may add them to:
-- any authenticated user who learns a conversation UUID can insert their own
-- membership row and read the entire history. A UUID is not a secret -- it
-- appears in URLs, logs, screenshots and error reports.
--
-- Re-applying this file recreates both policies and silently undoes that fix.
-- Nothing errors; the hole simply comes back.
--
-- Conversation and membership creation is now reachable ONLY through
-- public.start_direct_conversation(uuid), which is SECURITY DEFINER and so is
-- unaffected by the absence of those policies.
--
-- The SQL below is deliberately left as it ran on 2026-09-07 rather than
-- edited to remove the offending statements: this file is the record of what
-- was actually applied, and rewriting it would make the repo misrepresent its
-- own history. Read it as history, not as a runnable script.
--
-- If you need this schema from scratch, apply this file and then immediately
-- apply 20260907_close_self_join_hole.sql, in that order.
-- ############################################################################
--
-- APPLIED 2026-09-07 as migration `messaging_core`; end state verified by role.
--
-- Makes messaging usable end to end. Written against the live schema read on
-- 2026-09-04, not against assumed shape:
--
--   conversations         (id uuid pk, created_at timestamp)
--   conversation_members  (id uuid pk, conversation_id uuid NULL, user_id uuid NULL)
--   messages              (id uuid pk, conversation_id uuid NOT NULL,
--                          sender_id uuid NOT NULL, content text NULL,
--                          created_at timestamp)
--
-- All three tables are empty, so the NOT NULL and CHECK tightenings below
-- cannot fail on existing rows.
--
-- RLS is ALREADY enabled on all three, and the member-scoped SELECT policies
-- already exist and are correct -- messages_select_member in particular
-- already restricts reads to conversation members. This migration does not
-- rewrite them for the sake of rewriting; it repoints them at a shared helper
-- and fills the gaps that make messaging impossible today.
--
-- Verified by role on 2026-09-07 (setup + probes + forced rollback), before
-- any of the changes below. Member A and member B each saw 2 messages and 1
-- conversation; non-member C and anon each saw 0 messages, 0 conversations,
-- 0 member rows; C's attempt to insert a message was blocked (42501). So the
-- "members only" requirement already holds and is not what this fixes.
--
-- The same run proved the three gaps this migration does fix:
--   A create conversation: BLOCKED (42501)  -- no INSERT policy exists
--   A add other as member: BLOCKED (42501)  -- insert policy is self-only
--   A member_rows=1                         -- A cannot see B's membership,
--                                              so the list cannot name B
--
-- NOTE ON REALTIME: conversations, conversation_members and messages are NOT
-- members of the supabase_realtime publication (checked 2026-09-07; its public
-- members are device_users, glow_sessions, mood_events, moods, sparks, vents).
-- A postgres_changes subscription on any of them would never fire, exactly as
-- with posts and post_reactions. This migration deliberately does NOT add
-- them; that is a separate, opt-in change, kept in its own migration.


-- 1. Membership helper.
--
-- Needed because the natural policy for conversation_members -- "I can see
-- members of conversations I belong to" -- must query conversation_members
-- from inside a conversation_members policy. That recurses, and PostgreSQL
-- aborts with "infinite recursion detected in policy for relation".
--
-- SECURITY DEFINER breaks the cycle by running the lookup as the owner, with
-- RLS bypassed. It is safe to expose because it takes no user identity: it
-- only ever answers "is the *calling* user a member of this conversation",
-- and returns a bare boolean. search_path is pinned so a caller cannot shadow
-- public with their own conversation_members.

create or replace function public.is_conversation_member(p_conversation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.conversation_members cm
    where cm.conversation_id = p_conversation_id
      and cm.user_id = auth.uid()
  );
$$;

revoke all on function public.is_conversation_member(uuid) from public, anon;
grant execute on function public.is_conversation_member(uuid) to authenticated;


-- 2. Data integrity.
--
-- conversation_members.conversation_id and user_id are both nullable today,
-- so a membership row pointing at nobody is representable. A NULL user_id
-- would never match auth.uid() and so would be invisible to every policy -- a
-- row that exists but can never be read or cleaned up through the API.
--
-- Explicit `alter column ... set not null` rather than folding these into a
-- column definition: on an existing column, a NOT NULL attached to an
-- `add column if not exists` is silently discarded when the column is already
-- there. These statements cannot be silently skipped that way.

alter table public.conversation_members alter column conversation_id set not null;
alter table public.conversation_members alter column user_id set not null;

-- One membership row per person per conversation. Without this, a double-tap
-- on "start chat" produces duplicate members, and every EXISTS-based policy
-- keeps working while the member list renders the same person twice.
create unique index if not exists conversation_members_conversation_user_key
  on public.conversation_members (conversation_id, user_id);

-- Every RLS check here runs an EXISTS against conversation_members keyed by
-- (conversation_id, user_id) or by user_id alone. Neither had an index --
-- only the pkey on id -- so each policy evaluation was a sequential scan.
create index if not exists conversation_members_user_id_idx
  on public.conversation_members (user_id);

-- The thread reads messages for one conversation in time order, and the chat
-- list takes the newest per conversation. idx_messages_conversation_id covers
-- only the equality half; this covers the sort too.
create index if not exists messages_conversation_created_idx
  on public.messages (conversation_id, created_at desc);

-- content is nullable with no length bound, so a NULL or whitespace-only
-- message is storable and would render as a blank bubble. Note that the CHECK
-- alone could not close this: CHECK passes on NULL, so the NOT NULL is doing
-- real work rather than restating the constraint.
alter table public.messages alter column content set not null;

-- PostgreSQL has no `add constraint if not exists`, so a bare ADD CONSTRAINT
-- makes this migration fail on a re-run rather than being a no-op. Guarded
-- against pg_constraint by name so re-running is safe.
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'messages_content_non_empty'
  ) then
    alter table public.messages
      add constraint messages_content_non_empty
      check (length(btrim(content)) between 1 and 4000);
  end if;
end $$;


-- 3. Duplicate foreign keys.
--
-- messages carries two identical FKs on each column:
--   conversation_id -> conversations(id): messages_conversation_id_fkey
--                                         fk_messages_conversation (ON DELETE CASCADE)
--   sender_id       -> profiles(id):      messages_sender_id_fkey
--                                         fk_messages_sender (ON DELETE CASCADE)
--
-- PostgREST resolves an embed by finding *the* FK between two tables. With
-- two, `select=*,profiles(*)` fails as ambiguous (PGRST201), which is why the
-- thread screen cannot fetch sender display names in one round trip.
--
-- Keep the ON DELETE CASCADE pair and drop the bare duplicates: deleting a
-- conversation should take its messages with it, and the fk_* constraints are
-- the ones that say so.

alter table public.messages drop constraint if exists messages_conversation_id_fkey;
alter table public.messages drop constraint if exists messages_sender_id_fkey;


-- 4. Policies.
--
-- Dropped by their real live names, confirmed against pg_policies. A drop of
-- a name that does not exist is a silent no-op, and because permissive
-- policies are OR-ed together, a stale over-permissive policy left in place
-- would keep granting access underneath the new ones.

drop policy if exists conversation_members_select_own on public.conversation_members;
drop policy if exists conversation_members_insert_own on public.conversation_members;
drop policy if exists conversations_select_member     on public.conversations;
drop policy if exists messages_select_member          on public.messages;
drop policy if exists messages_insert_sender_member   on public.messages;

-- Widened from "my own membership row" to "members of conversations I am in".
-- This is what lets the chat list name the other participant. It does not
-- reach beyond conversations the caller already belongs to.
create policy conversation_members_select_member on public.conversation_members
  for select to authenticated
  using (public.is_conversation_member(conversation_id));

-- Still self-only. Adding somebody else goes through start_direct_conversation
-- below, which is auditable; a policy permitting it directly would let any
-- user insert any other user into any conversation.
create policy conversation_members_insert_own on public.conversation_members
  for insert to authenticated
  with check (user_id = auth.uid());

-- Unchanged in meaning; repointed at the helper.
create policy conversations_select_member on public.conversations
  for select to authenticated
  using (public.is_conversation_member(id));

-- New. There was no INSERT policy on conversations at all, so RLS denied
-- every insert and no conversation could ever be created from a client.
-- Bare `true` is deliberate: a conversation row is an opaque id with no
-- payload, and it is worthless until a membership row exists. The RPC below
-- is what actually creates them; this policy exists so that path is legal.
create policy conversations_insert_authenticated on public.conversations
  for insert to authenticated
  with check (true);

-- Unchanged in meaning; repointed at the helper.
create policy messages_select_member on public.messages
  for select to authenticated
  using (public.is_conversation_member(conversation_id));

-- Unchanged in meaning; repointed at the helper. Both halves matter: you must
-- be the sender you claim to be, and a member of the conversation.
create policy messages_insert_sender_member on public.messages
  for insert to authenticated
  with check (
    sender_id = auth.uid()
    and public.is_conversation_member(conversation_id)
  );

-- No UPDATE or DELETE policies on any of the three tables, so RLS denies edit
-- and delete for anon and authenticated alike. That is deliberate for a first
-- cut: message editing and deletion are product decisions, not schema gaps.


-- 5. Conversation creation.
--
-- A direct conversation needs three rows (one conversation, two members) and
-- is only meaningful if all three land. Doing it client-side means partial
-- state on failure -- a conversation with one member, invisible to the person
-- it was meant for -- and requires an INSERT policy loose enough to add other
-- people, which is exactly what section 4 avoids.
--
-- SECURITY DEFINER, but it derives the caller from auth.uid() and never
-- accepts it as an argument, so a caller can only ever add themselves plus one
-- named counterpart.

create or replace function public.start_direct_conversation(p_other_user_id uuid)
returns uuid
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_me uuid := auth.uid();
  v_conversation_id uuid;
begin
  if v_me is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  if p_other_user_id is null or p_other_user_id = v_me then
    raise exception 'a direct conversation needs a second, different participant'
      using errcode = '22023';
  end if;

  if not exists (select 1 from public.profiles p where p.id = p_other_user_id) then
    raise exception 'no profile with id %', p_other_user_id using errcode = '23503';
  end if;

  -- Reuse an existing 1:1 rather than stacking duplicates. Matches on the
  -- exact member set, so a group conversation that happens to contain both
  -- people is not mistaken for the DM.
  select cm.conversation_id
    into v_conversation_id
  from public.conversation_members cm
  group by cm.conversation_id
  having array_agg(cm.user_id order by cm.user_id)
       = array[least(v_me, p_other_user_id), greatest(v_me, p_other_user_id)]::uuid[]
  limit 1;

  if v_conversation_id is not null then
    return v_conversation_id;
  end if;

  insert into public.conversations default values returning id into v_conversation_id;

  insert into public.conversation_members (conversation_id, user_id)
  values (v_conversation_id, v_me),
         (v_conversation_id, p_other_user_id);

  return v_conversation_id;
end;
$$;

revoke all on function public.start_direct_conversation(uuid) from public, anon;
grant execute on function public.start_direct_conversation(uuid) to authenticated;


-- 6. Chat list source.
--
-- conversations has no last_message_at, so ordering the list by recency
-- otherwise means fetching every conversation plus its newest message and
-- sorting client-side. A denormalised column would need a trigger to stay
-- true; this derives the same thing and cannot drift.
--
-- security_invoker = true (PG15+; this project is on 17) makes the view run
-- under the *caller's* permissions, so the RLS policies above apply through
-- it. Without it the view would run as owner and expose every conversation to
-- everyone -- the exact opposite of the intent.

create or replace view public.conversation_list
with (security_invoker = true) as
select
  c.id          as conversation_id,
  c.created_at  as created_at,
  lm.content    as last_message,
  lm.created_at as last_message_at,
  lm.sender_id  as last_sender_id
from public.conversations c
left join lateral (
  select m.content, m.created_at, m.sender_id
  from public.messages m
  where m.conversation_id = c.id
  order by m.created_at desc, m.id desc
  limit 1
) lm on true;

grant select on public.conversation_list to authenticated;


-- 7. Close anon out.
--
-- anon holds SELECT/INSERT/UPDATE/DELETE on all three tables. RLS already
-- denies it in practice -- no policy names anon, and RLS default-denies -- so
-- this is defence in depth rather than an open leak being closed. It matters
-- if a permissive policy is ever added later without a role clause: a policy
-- written `to public` would pick anon up instantly.

revoke all on public.conversations        from anon;
revoke all on public.conversation_members from anon;
revoke all on public.messages             from anon;


-- 8. Realtime publication.
--
-- Client subscriptions only fire for tables that are members of the
-- supabase_realtime publication. Keep this idempotent so it is safe whether a
-- table was added manually between review and application.

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'conversations'
  ) then
    alter publication supabase_realtime add table public.conversations;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'conversation_members'
  ) then
    alter publication supabase_realtime add table public.conversation_members;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;
