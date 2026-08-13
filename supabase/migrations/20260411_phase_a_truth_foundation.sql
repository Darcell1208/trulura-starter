alter table public.profiles
  add column if not exists social_preference text,
  add column if not exists expression_prompt_answer text,
  add column if not exists expression_vibe_tag text,
  add column if not exists expression_short_post text,
  add column if not exists active_identity_mode text,
  add column if not exists anonymous_overlay_enabled boolean not null default false;

alter table public.user_settings
  add column if not exists interest_quiz_completed boolean not null default false,
  add column if not exists deeper_quiz_results jsonb not null default '[]'::jsonb;
