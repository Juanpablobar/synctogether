-- SyncTogether security and collaboration migration
-- Apply after supabase/schema.sql in the Supabase SQL Editor.
begin;

-- Calendar credentials must never be readable from the browser-facing Data API.
revoke all on table public.calendar_connections from anon, authenticated;
grant all on table public.calendar_connections to service_role;

-- Replace direct client writes with narrow, membership-checked RPCs.
create or replace function public.create_space(p_name text, p_kind text default 'private')
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  new_space_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if length(trim(coalesce(p_name, ''))) not between 1 and 80 then
    raise exception 'Space name must contain 1-80 characters';
  end if;
  if p_kind not in ('private', 'group') then raise exception 'Invalid space type'; end if;

  insert into public.spaces(name, kind, created_by)
  values (trim(p_name), p_kind, auth.uid())
  returning id into new_space_id;

  insert into public.space_members(space_id, user_id, role)
  values (new_space_id, auth.uid(), 'owner');

  return new_space_id;
end;
$$;

create or replace function public.create_space_invite(p_space_id uuid)
returns table(invite_token text, invite_expires_at timestamptz)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null or not public.is_space_member(p_space_id) then
    raise exception 'Not authorized';
  end if;
  return query
    insert into public.space_invites(space_id, created_by)
    values (p_space_id, auth.uid())
    returning token, expires_at;
end;
$$;

create or replace function public.redeem_space_invite(p_token text)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  target_space uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  select si.space_id into target_space
  from public.space_invites si
  where si.token = p_token and si.expires_at > now()
  limit 1;

  if target_space is null then raise exception 'Invite is invalid or expired'; end if;

  insert into public.space_members(space_id, user_id, role)
  values (target_space, auth.uid(), 'member')
  on conflict (space_id, user_id) do nothing;

  return target_space;
end;
$$;

-- Return only busy/free time blocks to members of the same space.
-- No event titles, locations, attendees, calendar IDs or descriptions are exposed.
create or replace function public.get_space_availability(
  p_space_id uuid,
  p_from timestamptz,
  p_to timestamptz
)
returns table(member_id uuid, starts_at timestamptz, ends_at timestamptz, is_busy boolean)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null or not public.is_space_member(p_space_id) then
    raise exception 'Not authorized';
  end if;
  if p_to <= p_from or p_to - p_from > interval '45 days' then
    raise exception 'Invalid time range (maximum 45 days)';
  end if;

  return query
    select ab.user_id, greatest(ab.starts_at, p_from), least(ab.ends_at, p_to), ab.is_busy
    from public.availability_blocks ab
    join public.space_members sm on sm.user_id = ab.user_id
    where sm.space_id = p_space_id
      and ab.starts_at < p_to
      and ab.ends_at > p_from
    order by ab.starts_at;
end;
$$;

-- Safe, limited member directory/presence data.
create or replace function public.get_space_members(p_space_id uuid)
returns table(member_id uuid, display_name text, avatar_url text, manual_status text, manual_status_until timestamptz)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if auth.uid() is null or not public.is_space_member(p_space_id) then
    raise exception 'Not authorized';
  end if;
  return query
    select p.id, p.display_name, p.avatar_url, p.manual_status, p.manual_status_until
    from public.space_members sm
    join public.profiles p on p.id = sm.user_id
    where sm.space_id = p_space_id;
end;
$$;

grant execute on function public.create_space(text, text) to authenticated;
grant execute on function public.create_space_invite(uuid) to authenticated;
grant execute on function public.redeem_space_invite(text) to authenticated;
grant execute on function public.get_space_availability(uuid, timestamptz, timestamptz) to authenticated;
grant execute on function public.get_space_members(uuid) to authenticated;

commit;
