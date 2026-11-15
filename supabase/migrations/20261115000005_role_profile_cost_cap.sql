-- Applied to the live project on 2026-11-15. Run after 20261115000004_access_controls.sql.
-- 1) usersRole cannot be set by clients (no self-promotion to staffAnalyst).
-- 2) A minimal public profile view so users can see each other's name and rating.
-- 3) The cost-share cap (FR3.1) is enforced by the database and is configurable.
begin;

alter table public.users add column if not exists display_name text;

-- usersRole is the enum user_role, which already limits the allowed values.
-- Check its labels first: select enum_range(null::public.user_role);
-- staffAnalyst is assigned by the project owner in the Supabase dashboard (service role);
-- nothing in the app can set it.

-- Remove every client route to usersRole, then re-grant the safe columns.
revoke update on public.users from public, anon, authenticated;
revoke update ("usersRole") on public.users from public, anon, authenticated;
grant update (display_name, "vehiclePlate", "vehicleModel", faculty, residential_area,
    residential_college, vehicle_type, fuel_category, emergency_contact, fcm_token)
    on public.users to authenticated;

-- Commuters switch between passenger, driver and both here. Staff keep their role.
create or replace function public.set_my_role(p_role text)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
begin
    if auth.uid() is null then
        raise exception 'Sign in first';
    end if;
    if p_role not in ('passengers', 'drivers', 'both') then
        raise exception 'Role must be passengers, drivers or both';
    end if;
    -- format %L inserts a quoted literal, which works whether usersRole is text or an enum.
    execute format(
        'update public.users set "usersRole" = %L where "usersId" = $1 and "usersRole"::text <> %L',
        p_role, 'staffAnalyst'
    ) using auth.uid();
end;
$function$;
revoke all on function public.set_my_role(text) from public, anon;
grant execute on function public.set_my_role(text) to authenticated;

-- Raw users rows stay private. This view runs with the owner's rights and exposes
-- only name and rating, for chat and ratings screens.
create or replace view public.public_profiles as
    select "usersId" as user_id, display_name, trust_rating from public.users;
revoke all on public.public_profiles from public, anon, authenticated;
grant select on public.public_profiles to authenticated;

-- Cost-share cap per seat in RM. Change the value in this table to retune it.
create table if not exists public.app_config (
    key text primary key,
    value numeric not null
);
insert into public.app_config (key, value) values ('max_cost_per_seat', 5.00)
    on conflict (key) do nothing;
alter table public.app_config enable row level security;
revoke all on public.app_config from public, anon, authenticated;
grant select on public.app_config to authenticated;
drop policy if exists "Read app config" on public.app_config;
create policy "Read app config" on public.app_config for select to authenticated using (true);

create or replace function public.enforce_cost_cap()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_cap numeric;
begin
    select value into v_cap from public.app_config where key = 'max_cost_per_seat';
    v_cap := coalesce(v_cap, 5.00);
    if new.cost_per_seat < 0 or new.cost_per_seat > v_cap then
        raise exception 'Cost per seat must be between 0 and RM %', v_cap;
    end if;
    return new;
end;
$function$;
drop trigger if exists trip_offers_cost_cap on public.trip_offers;
create trigger trip_offers_cost_cap
    before insert or update of cost_per_seat on public.trip_offers
    for each row execute function public.enforce_cost_cap();

commit;
