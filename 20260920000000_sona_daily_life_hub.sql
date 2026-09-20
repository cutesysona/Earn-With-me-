-- SONA DAILY LIFE HUB — Supabase database setup
-- Run this in Supabase Dashboard -> SQL Editor.
-- RLS is enabled so an authenticated user can only access rows where user_id/id = auth.uid().

create extension if not exists pgcrypto;

create sequence if not exists public.sona_member_id_seq start 1;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  member_id text unique not null default ('SONA' || lpad(nextval('public.sona_member_id_seq')::text, 3, '0')),
  sponsor_id text,
  sponsor_name text,
  full_name text,
  date_of_joining date,
  mobile text,
  email text,
  account_holder text,
  bank_account text,
  account_type text default 'Savings',
  bank_name text,
  bank_branch text,
  ifsc text,
  pan text,
  wallet_address text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists profiles_sponsor_id_idx on public.profiles(sponsor_id);

create table if not exists public.payment_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null check (type in ('Deposit','Withdrawal')),
  amount numeric(14,2) not null check (amount > 0),
  status text not null default 'Pending / Checking',
  reference text,
  created_at timestamptz not null default now()
);

create index if not exists payment_history_user_id_idx
  on public.payment_history(user_id, created_at desc);

create table if not exists public.creator_media (
  user_id uuid primary key references auth.users(id) on delete cascade,
  youtube_url text,
  youtube_video_id text,
  youtube_playlist_id text,
  instagram_reel_url text,
  kick_username text,
  updated_at timestamptz not null default now()
);

-- Create a profile automatically when Supabase Auth creates a user.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id, full_name, mobile, sponsor_id, sponsor_name, email
  )
  values (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'mobile',
    case
      when exists (select 1 from public.profiles p where upper(p.member_id) = upper(new.raw_user_meta_data->>'sponsor_id'))
      then upper(new.raw_user_meta_data->>'sponsor_id')
      else null
    end,
    case
      when exists (select 1 from public.profiles p where upper(p.member_id) = upper(new.raw_user_meta_data->>'sponsor_id'))
      then new.raw_user_meta_data->>'sponsor_name'
      else null
    end,
    new.email
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- RLS
alter table public.profiles enable row level security;
alter table public.payment_history enable row level security;
alter table public.creator_media enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own"
on public.profiles for select to authenticated
using (id = auth.uid());

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own"
on public.profiles for insert to authenticated
with check (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own"
on public.profiles for update to authenticated
using (id = auth.uid())
with check (id = auth.uid());

drop policy if exists "profiles_delete_own" on public.profiles;
create policy "profiles_delete_own"
on public.profiles for delete to authenticated
using (id = auth.uid());

drop policy if exists "payment_select_own" on public.payment_history;
create policy "payment_select_own"
on public.payment_history for select to authenticated
using (user_id = auth.uid());

drop policy if exists "payment_insert_own" on public.payment_history;
create policy "payment_insert_own"
on public.payment_history for insert to authenticated
with check (user_id = auth.uid());

drop policy if exists "payment_update_own" on public.payment_history;
create policy "payment_update_own"
on public.payment_history for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "payment_delete_own" on public.payment_history;
create policy "payment_delete_own"
on public.payment_history for delete to authenticated
using (user_id = auth.uid());

drop policy if exists "creator_media_select_own" on public.creator_media;
create policy "creator_media_select_own"
on public.creator_media for select to authenticated
using (user_id = auth.uid());

drop policy if exists "creator_media_insert_own" on public.creator_media;
create policy "creator_media_insert_own"
on public.creator_media for insert to authenticated
with check (user_id = auth.uid());

drop policy if exists "creator_media_update_own" on public.creator_media;
create policy "creator_media_update_own"
on public.creator_media for update to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

drop policy if exists "creator_media_delete_own" on public.creator_media;
create policy "creator_media_delete_own"
on public.creator_media for delete to authenticated
using (user_id = auth.uid());

-- IMPORTANT:
-- Do not create policies for anonymous users that expose profiles/payment data.
-- Do not put a service_role/secret key in frontend code.
