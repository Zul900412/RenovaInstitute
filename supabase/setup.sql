-- Setup:
-- 1. In Supabase Authentication, create and confirm your owner user, then disable public sign-ups.
-- 2. Replace the email placeholder at the bottom with that user's email in the SQL Editor.
-- 3. Run this script. Keep the email in the SQL Editor; do not commit it to GitHub.
-- The web app uses the public publishable key. Row-level security below protects patient data.

create table if not exists public.renova_workspace_owners (
    user_id uuid primary key references auth.users (id) on delete cascade,
    created_at timestamptz not null default now()
);

alter table public.renova_workspace_owners enable row level security;
revoke all on public.renova_workspace_owners from anon, authenticated;

create or replace function public.is_renova_workspace_owner()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.renova_workspace_owners
        where user_id = (select auth.uid())
    );
$$;

revoke all on function public.is_renova_workspace_owner() from public;
grant execute on function public.is_renova_workspace_owner() to authenticated;

create table if not exists public.renova_patient_state (
    owner_id uuid primary key references auth.users (id) on delete cascade,
    state jsonb not null,
    updated_at timestamptz not null default now()
);

alter table public.renova_patient_state enable row level security;
revoke all on public.renova_patient_state from anon, authenticated;
grant select, insert, update, delete on public.renova_patient_state to authenticated;

drop policy if exists "Owner can access patient state" on public.renova_patient_state;
create policy "Owner can access patient state"
on public.renova_patient_state
for all
to authenticated
using (
    owner_id = (select auth.uid())
    and (select public.is_renova_workspace_owner())
)
with check (
    owner_id = (select auth.uid())
    and (select public.is_renova_workspace_owner())
);

create table if not exists public.renova_store_catalog (
    id smallint primary key check (id = 1),
    owner_id uuid not null references auth.users (id) on delete cascade,
    products jsonb not null default '[]'::jsonb check (jsonb_typeof(products) = 'array'),
    updated_at timestamptz not null default now()
);

create table if not exists public.renova_private_store_resources (
    owner_id uuid primary key references auth.users (id) on delete cascade,
    resources jsonb not null default '{}'::jsonb check (jsonb_typeof(resources) = 'object'),
    updated_at timestamptz not null default now()
);

alter table public.renova_private_store_resources enable row level security;
revoke all on public.renova_private_store_resources from anon, authenticated;
grant select, insert, update on public.renova_private_store_resources to authenticated;

drop policy if exists "Only workspace owner can manage private store resources" on public.renova_private_store_resources;
create policy "Only workspace owner can manage private store resources"
on public.renova_private_store_resources
for all
to authenticated
using (
    owner_id = (select auth.uid())
    and (select public.is_renova_workspace_owner())
)
with check (
    owner_id = (select auth.uid())
    and (select public.is_renova_workspace_owner())
);

alter table public.renova_store_catalog enable row level security;
revoke all on public.renova_store_catalog from anon, authenticated;
grant select on public.renova_store_catalog to anon, authenticated;
grant insert, update, delete on public.renova_store_catalog to authenticated;

drop policy if exists "Anyone can view the public store catalog" on public.renova_store_catalog;
create policy "Anyone can view the public store catalog"
on public.renova_store_catalog
for select
to anon, authenticated
using (true);

drop policy if exists "Only workspace owner can add catalog" on public.renova_store_catalog;
create policy "Only workspace owner can add catalog"
on public.renova_store_catalog
for insert
to authenticated
with check (
    owner_id = (select auth.uid())
    and (select public.is_renova_workspace_owner())
);

drop policy if exists "Only workspace owner can update catalog" on public.renova_store_catalog;
create policy "Only workspace owner can update catalog"
on public.renova_store_catalog
for update
to authenticated
using (
    owner_id = (select auth.uid())
    and (select public.is_renova_workspace_owner())
)
with check (
    owner_id = (select auth.uid())
    and (select public.is_renova_workspace_owner())
);

drop policy if exists "Only workspace owner can delete catalog" on public.renova_store_catalog;
create policy "Only workspace owner can delete catalog"
on public.renova_store_catalog
for delete
to authenticated
using (
    owner_id = (select auth.uid())
    and (select public.is_renova_workspace_owner())
);

create or replace function public.set_renova_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists renova_patient_state_updated_at on public.renova_patient_state;
create trigger renova_patient_state_updated_at
before update on public.renova_patient_state
for each row execute function public.set_renova_updated_at();

drop trigger if exists renova_store_catalog_updated_at on public.renova_store_catalog;
create trigger renova_store_catalog_updated_at
before update on public.renova_store_catalog
for each row execute function public.set_renova_updated_at();

drop trigger if exists renova_private_store_resources_updated_at on public.renova_private_store_resources;
create trigger renova_private_store_resources_updated_at
before update on public.renova_private_store_resources
for each row execute function public.set_renova_updated_at();

-- Create your user first in Supabase Authentication, then replace the email below.
insert into public.renova_workspace_owners (user_id)
select id
from auth.users
where email = 'zulmafuertes@gmail.com'
on conflict (user_id) do nothing;

notify pgrst, 'reload schema';
