-- RLS coverage for live core tables that were missed by the earlier pass.
--
-- This migration is intentionally idempotent and column-aware because these
-- tables exist in multiple schema vintages. It enables RLS for every known live
-- table, adds owner-scoped writes wherever `user_id` or profile `id` exists,
-- and keeps Vent Space reads scoped until product decides whether vents are
-- global, circle-scoped, or private.

alter table if exists public.vents enable row level security;
alter table if exists public.vent_posts enable row level security;
alter table if exists public.profiles enable row level security;
alter table if exists public.posts enable row level security;
alter table if exists public.sparks enable row level security;
alter table if exists public.glow_posts enable row level security;
alter table if exists public.glow_sessions enable row level security;
alter table if exists public.glows enable row level security;
alter table if exists public.moods enable row level security;

do $$
begin
  if to_regclass('public.profiles') is not null then
    drop policy if exists "profiles_authenticated_read" on public.profiles;
    drop policy if exists "profiles_insert_own" on public.profiles;
    drop policy if exists "profiles_update_own" on public.profiles;
    drop policy if exists "profiles_delete_own" on public.profiles;

    create policy "profiles_authenticated_read"
      on public.profiles for select
      to authenticated
      using (true);

    if exists (
      select 1 from information_schema.columns
      where table_schema = 'public' and table_name = 'profiles' and column_name = 'id'
    ) then
      create policy "profiles_insert_own"
        on public.profiles for insert
        to authenticated
        with check (auth.uid()::text = id::text);

      create policy "profiles_update_own"
        on public.profiles for update
        to authenticated
        using (auth.uid()::text = id::text)
        with check (auth.uid()::text = id::text);

      create policy "profiles_delete_own"
        on public.profiles for delete
        to authenticated
        using (auth.uid()::text = id::text);
    end if;
  end if;
end $$;

do $$
declare
  target_table text;
begin
  foreach target_table in array array[
    'posts',
    'sparks',
    'glow_posts',
    'glow_sessions',
    'glows',
    'moods'
  ] loop
    if to_regclass(format('public.%I', target_table)) is not null then
      execute format('drop policy if exists "%s_authenticated_read" on public.%I', target_table, target_table);
      execute format('drop policy if exists "%s_insert_own" on public.%I', target_table, target_table);
      execute format('drop policy if exists "%s_insert_authenticated" on public.%I', target_table, target_table);
      execute format('drop policy if exists "%s_update_own" on public.%I', target_table, target_table);
      execute format('drop policy if exists "%s_update_authenticated" on public.%I', target_table, target_table);
      execute format('drop policy if exists "%s_delete_own" on public.%I', target_table, target_table);
      execute format('drop policy if exists "%s_delete_authenticated" on public.%I', target_table, target_table);

      execute format(
        'create policy "%s_authenticated_read" on public.%I for select to authenticated using (true)',
        target_table,
        target_table
      );

      if exists (
        select 1 from information_schema.columns c
        where c.table_schema = 'public'
          and c.table_name = target_table
          and c.column_name = 'user_id'
      ) then
        execute format(
          'create policy "%s_insert_own" on public.%I for insert to authenticated with check (auth.uid()::text = user_id::text)',
          target_table,
          target_table
        );
        execute format(
          'create policy "%s_update_own" on public.%I for update to authenticated using (auth.uid()::text = user_id::text) with check (auth.uid()::text = user_id::text)',
          target_table,
          target_table
        );
        execute format(
          'create policy "%s_delete_own" on public.%I for delete to authenticated using (auth.uid()::text = user_id::text)',
          target_table,
          target_table
        );
      else
        execute format(
          'create policy "%s_insert_authenticated" on public.%I for insert to authenticated with check (true)',
          target_table,
          target_table
        );
      end if;
    end if;
  end loop;
end $$;

do $$
declare
  target_table text;
begin
  foreach target_table in array array['vents', 'vent_posts'] loop
    if to_regclass(format('public.%I', target_table)) is not null then
      execute format('drop policy if exists "%s_read_own" on public.%I', target_table, target_table);
      execute format('drop policy if exists "%s_insert_own" on public.%I', target_table, target_table);
      execute format('drop policy if exists "%s_update_own" on public.%I', target_table, target_table);
      execute format('drop policy if exists "%s_delete_own" on public.%I', target_table, target_table);

      if exists (
        select 1 from information_schema.columns c
        where c.table_schema = 'public'
          and c.table_name = target_table
          and c.column_name = 'user_id'
      ) then
        execute format(
          'create policy "%s_read_own" on public.%I for select to authenticated using (auth.uid()::text = user_id::text)',
          target_table,
          target_table
        );
        execute format(
          'create policy "%s_insert_own" on public.%I for insert to authenticated with check (auth.uid()::text = user_id::text)',
          target_table,
          target_table
        );
        execute format(
          'create policy "%s_update_own" on public.%I for update to authenticated using (auth.uid()::text = user_id::text) with check (auth.uid()::text = user_id::text)',
          target_table,
          target_table
        );
        execute format(
          'create policy "%s_delete_own" on public.%I for delete to authenticated using (auth.uid()::text = user_id::text)',
          target_table,
          target_table
        );
      end if;
    end if;
  end loop;
end $$;
