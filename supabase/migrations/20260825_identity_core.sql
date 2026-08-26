-- identity_core stores only the user's persistent identity
-- profile. It is NOT the full Blueprint "Identity Core System"
-- (§1.1), which also covers verification, elevation, and other
-- identity-governance components maintained separately.
create table if not exists public.identity_core (
  user_id uuid primary key references auth.users (id) on delete cascade,
  communication_style text,
  core_values text[],
  relationship_preferences text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.identity_core enable row level security;

create policy "Users can view their own identity core"
  on public.identity_core for select
  using (auth.uid() = user_id);

create policy "Users can insert their own identity core"
  on public.identity_core for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own identity core"
  on public.identity_core for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
