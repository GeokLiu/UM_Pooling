-- For the exported current schema, not for an empty project.
-- Preserve public.users' quoted legacy names until Kotlin/webhooks migrate together.
begin;

alter table public.users
    alter column "usersRole" set default 'passengers',
    add column if not exists faculty text,
    add column if not exists residential_area text,
    add column if not exists residential_college text,
    add column if not exists vehicle_type text,
    add column if not exists fuel_category text,
    add column if not exists trust_rating numeric(3,2),
    add column if not exists emergency_contact jsonb,
    add column if not exists fcm_token text;

-- Unrated users should not automatically receive a five-star trust score.
-- This preserves existing scores; recalculation from valid reviews is separate.
alter table public.users alter column trust_rating drop default;

alter table public.saved_routes
    add column if not exists preferred_time time,
    add column if not exists origin_zone text,
    add column if not exists destination_zone text;

alter table public.trip_offers
    add column if not exists origin_zone text,
    add column if not exists destination_zone text,
    add column if not exists distance_km numeric(8,2);
-- Preserve the existing offer_status enum; IF NOT EXISTS is not type validation.

alter table public.ride_requests
    alter column trip_offer_id drop not null,
    add column if not exists destination_geo public.geography(Point,4326),
    add column if not exists preferred_time timestamptz;

alter table public.trips
    add column if not exists origin_zone text,
    add column if not exists destination_zone text,
    add column if not exists distance_km numeric(8,2),
    add column if not exists confirmed_passenger_count integer default 0,
    add column if not exists co2_saved_kg numeric(8,2) default 0,
    add column if not exists vehicle_plate_snapshot text;

-- bookings and message target columns already exist: do not recreate/drop them.
-- Keep user_impact_stats from the original script; do not drop impact_stats or data.
create table if not exists public.user_impact_stats (
    user_id uuid primary key references public.users("usersId") on delete cascade,
    total_trips integer not null default 0 check (total_trips >= 0),
    total_distance_km numeric(10,2) not null default 0 check (total_distance_km >= 0),
    total_co2_saved_kg numeric(10,2) not null default 0 check (total_co2_saved_kg >= 0),
    updated_at timestamptz not null default now()
);

-- Existing tables are deliberately not silently reshaped by CREATE IF NOT EXISTS.
-- Inspect any pre-existing user_impact_stats definition before running this file.
alter table public.user_impact_stats enable row level security;
revoke all on public.user_impact_stats from public, anon, authenticated;
grant select on public.user_impact_stats to authenticated;
drop policy if exists "Read own impact totals" on public.user_impact_stats;
create policy "Read own impact totals" on public.user_impact_stats
    for select to authenticated using (user_id = (select auth.uid()));

alter table public.impact_aggregates
    add column if not exists residential_college text;
-- Leave the existing dashboard definition unchanged. College grouping, distinct
-- contributor counts, aggregate updates and staff access need a separate design.
commit;
