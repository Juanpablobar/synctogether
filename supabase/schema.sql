create extension if not exists pgcrypto;
create table if not exists public.profiles(id uuid primary key references auth.users(id) on delete cascade,display_name text,avatar_url text,manual_status text check(manual_status in ('available','busy')),manual_status_until timestamptz,timezone text default 'America/Mexico_City',updated_at timestamptz default now());
create table if not exists public.spaces(id uuid primary key default gen_random_uuid(),name text not null,slug text unique not null default encode(gen_random_bytes(8),'hex'),kind text not null check(kind in ('private','group')) default 'private',created_by uuid not null references auth.users(id),created_at timestamptz default now());
create table if not exists public.space_members(space_id uuid references public.spaces(id) on delete cascade,user_id uuid references auth.users(id) on delete cascade,role text default 'member' check(role in ('owner','member')),joined_at timestamptz default now(),primary key(space_id,user_id));
create table if not exists public.calendar_connections(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,provider text not null check(provider in ('google','microsoft')),provider_account_id text,access_token text,refresh_token text,expires_at timestamptz,scopes text[],created_at timestamptz default now(),unique(user_id,provider));
create table if not exists public.availability_blocks(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,starts_at timestamptz not null,ends_at timestamptz not null,is_busy boolean not null default true,source text not null default 'calendar',updated_at timestamptz default now(),check(ends_at>starts_at));
create index if not exists availability_user_time_idx on public.availability_blocks(user_id,starts_at,ends_at);
create table if not exists public.push_subscriptions(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,endpoint text unique not null,subscription jsonb not null,created_at timestamptz default now());
create table if not exists public.space_invites(id uuid primary key default gen_random_uuid(),space_id uuid not null references public.spaces(id) on delete cascade,token text unique not null default encode(gen_random_bytes(18),'hex'),created_by uuid not null references auth.users(id),expires_at timestamptz default (now()+interval '14 days'),created_at timestamptz default now());

alter table public.profiles enable row level security;alter table public.spaces enable row level security;alter table public.space_members enable row level security;alter table public.calendar_connections enable row level security;alter table public.availability_blocks enable row level security;alter table public.push_subscriptions enable row level security;alter table public.space_invites enable row level security;
create policy "profile owner read/write" on public.profiles for all using(auth.uid()=id) with check(auth.uid()=id);
create policy "members read spaces" on public.spaces for select using(exists(select 1 from public.space_members sm where sm.space_id=id and sm.user_id=auth.uid()));
create policy "creator manages spaces" on public.spaces for insert with check(auth.uid()=created_by);
create or replace function public.is_space_member(target_space uuid) returns boolean language sql stable security definer set search_path=public as $$ select exists(select 1 from public.space_members sm where sm.space_id=target_space and sm.user_id=auth.uid()); $$;
create policy "members see membership" on public.space_members for select using(public.is_space_member(space_id));
create policy "user sees own connections" on public.calendar_connections for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
create policy "users see own availability" on public.availability_blocks for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
create policy "users manage own push" on public.push_subscriptions for all using(auth.uid()=user_id) with check(auth.uid()=user_id);
create policy "members read invites" on public.space_invites for select using(public.is_space_member(space_id));

create or replace function public.create_profile_for_user() returns trigger language plpgsql security definer set search_path=public as $$ begin insert into public.profiles(id,display_name) values(new.id,coalesce(new.raw_user_meta_data->>'full_name',split_part(new.email,'@',1))) on conflict(id) do nothing; return new; end; $$;
drop trigger if exists on_auth_user_created on auth.users;create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.create_profile_for_user();

-- Realtime: enable for profile status and availability if desired in Supabase Dashboard.
