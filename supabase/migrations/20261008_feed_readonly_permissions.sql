-- Focused repair based on the user-exported live schema, 2026-10-08.
-- CHANGES permissions; does not delete content or replace view definitions.
-- Applied manually by the owner on 2026-10-08; returned all three views read=true/write=false.
-- Recorded here for reproducibility. No CLI migration-history reconciliation performed.
begin;

-- These owner-executed projections are read interfaces, never write APIs.
revoke insert, update, delete, truncate, references, trigger
on public.posts_feed, public.vent_feed, public.profiles_public
from public, anon, authenticated;

-- Remove any explicit column-level write grants as well as table grants.
do $$
declare v record;
begin
  for v in
    select c.relname, string_agg(quote_ident(a.attname), ', ' order by a.attnum) as cols
    from pg_class c join pg_namespace n on n.oid = c.relnamespace
    join pg_attribute a on a.attrelid = c.oid
    where n.nspname = 'public'
      and c.relname in ('posts_feed','vent_feed','profiles_public')
      and c.relkind = 'v' and a.attnum > 0 and not a.attisdropped
    group by c.relname
  loop
    execute format('revoke insert (%s), update (%s), references (%s) on public.%I from public, anon, authenticated',
                   v.cols, v.cols, v.cols, v.relname);
  end loop;
end $$;

-- Normal application operations do not need these whole-table privileges.
revoke truncate, references, trigger
on public.blocks, public.comments, public.conversation_members,
   public.conversations, public.messages, public.post_reactions,
   public.posts, public.profiles
from public, anon, authenticated;

-- Verify effective feed write permissions, including inherited/column grants.
-- Any unexpected remaining access aborts the entire transaction.
do $$
declare target_view text; target_role text; target_priv text; col record;
begin
  foreach target_view in array array['posts_feed','vent_feed','profiles_public'] loop
    foreach target_role in array array['anon','authenticated'] loop
      foreach target_priv in array array['INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER'] loop
        if has_table_privilege(target_role, 'public.' || target_view, target_priv) then
          raise exception 'Unexpected remaining privilege: % % %', target_role, target_view, target_priv;
        end if;
      end loop;
      for col in select attname from pg_attribute
        where attrelid = to_regclass('public.' || target_view)
          and attnum > 0 and not attisdropped loop
        if has_column_privilege(target_role, 'public.' || target_view, col.attname, 'INSERT,UPDATE,REFERENCES') then
          raise exception 'Unexpected remaining column write: % %.%', target_role, target_view, col.attname;
        end if;
      end loop;
    end loop;
    if not has_table_privilege('authenticated', 'public.' || target_view, 'SELECT') then
      raise exception 'Authenticated feed read missing: %', target_view;
    end if;
  end loop;
end $$;

commit;

select name as view_name,
       has_table_privilege('authenticated', 'public.' || name, 'SELECT') as can_read,
       has_table_privilege('authenticated', 'public.' || name, 'INSERT,UPDATE,DELETE') as can_write
from unnest(array['posts_feed','vent_feed','profiles_public']) as names(name);
-- Expected: three rows, can_read=true, can_write=false.
-- Security-definer advisor alerts may remain; this fixes unsafe write grants,
-- not the separate age boundaries, blocks, profile privacy, or view architecture.
