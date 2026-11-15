-- Review in staging: this intentionally limits raw user rows to their owner,
-- makes booking/trip writes server-only, and disables dashboard client access
-- until staff authorisation is implemented. See README before running.
begin;

-- Avoid silently combining these policies with a newer, unknown permissive rule.
do $check$
begin
    if exists (
        select 1 from pg_policies where schemaname = 'public'
        and tablename in ('users','messages','bookings','trips')
        and policyname not in (
            'Allow authenticated view users', 'Allow user update own profile',
            'Trip and booking chat access', 'Read own private profile',
            'Update own profile fields', 'Read participant bookings',
            'Read participant trips', 'Read participant messages',
            'Send participant messages'
        )
    ) then
        raise exception 'Unexpected policies found: review them before applying access changes';
    end if;
end;
$check$;

-- These helpers avoid circular RLS queries between trips and bookings.
-- They expose only whether the current caller participates, never another user's data.
create or replace function public.is_booking_participant(p_booking_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $function$
    select auth.uid() is not null and exists (
        select 1 from public.bookings b
        left join public.trip_offers o on o.trip_offer_id = b.trip_offer_id
        left join public.trips t on t.trip_id = b.trip_id
        where b.booking_id = p_booking_id
          and (b.passenger_id = auth.uid() or o.driver_id = auth.uid() or t.driver_id = auth.uid())
    );
$function$;

create or replace function public.is_trip_participant(p_trip_id uuid)
returns boolean language sql stable security definer set search_path = ''
as $function$
    select auth.uid() is not null and exists (
        select 1 from public.trips t where t.trip_id = p_trip_id
          and (t.driver_id = auth.uid() or exists (
              select 1 from public.bookings b
              where b.trip_id = t.trip_id and b.passenger_id = auth.uid()
          ))
    );
$function$;
revoke all on function public.is_booking_participant(uuid) from public, anon;
revoke all on function public.is_trip_participant(uuid) from public, anon;
grant execute on function public.is_booking_participant(uuid) to authenticated;
grant execute on function public.is_trip_participant(uuid) to authenticated;

alter table public.users enable row level security;
drop policy if exists "Allow authenticated view users" on public.users;
drop policy if exists "Allow user update own profile" on public.users;
drop policy if exists "Read own private profile" on public.users;
drop policy if exists "Update own profile fields" on public.users;
create policy "Read own private profile" on public.users for select to authenticated
    using ("usersId" = (select auth.uid()));
create policy "Update own profile fields" on public.users for update to authenticated
    using ("usersId" = (select auth.uid()))
    with check ("usersId" = (select auth.uid()));

-- RLS alone does not prevent changing a computed trust_rating on one's own row.
revoke all on public.users from public, anon, authenticated;
-- Also remove column-level UPDATE grants, which table-level REVOKE does not remove.
revoke update ("usersId", "usersEmail", "usersRole", "vehiclePlate", "vehicleModel",
    "createdTime", faculty, residential_area, residential_college, vehicle_type,
    fuel_category, trust_rating, emergency_contact, fcm_token)
    on public.users from public, anon, authenticated;
grant select on public.users to authenticated;
grant update ("vehiclePlate", "vehicleModel", faculty,
    residential_area, residential_college, vehicle_type, fuel_category,
    emergency_contact, fcm_token) on public.users to authenticated;
-- usersRole is NOT client-writable: a user could otherwise make themselves staffAnalyst.
-- Commuter role changes go through public.set_my_role() in 20261115000005_role_profile_cost_cap.sql.

alter table public.bookings enable row level security;
alter table public.trips enable row level security;
revoke all on public.bookings, public.trips from public, anon, authenticated;
grant select on public.bookings, public.trips to authenticated;
drop policy if exists "Read participant bookings" on public.bookings;
create policy "Read participant bookings" on public.bookings for select to authenticated
    using (public.is_booking_participant(booking_id));
drop policy if exists "Read participant trips" on public.trips;
create policy "Read participant trips" on public.trips for select to authenticated
    using (public.is_trip_participant(trip_id));
-- Client writes go through authenticated, validated lifecycle RPCs, not table writes.

-- Seat availability is updated by the booking RPC, not direct driver updates.
revoke update, delete on public.trip_offers from public, anon, authenticated;
revoke update (available_seats) on public.trip_offers from public, anon, authenticated;
grant update (origin_geo, destination_geo, cost_per_seat, status, departure_time,
    origin_zone, destination_zone, distance_km) on public.trip_offers to authenticated;
-- The existing driver-ownership RLS policy still applies to permitted updates.

alter table public.messages enable row level security;
drop policy if exists "Trip and booking chat access" on public.messages;
drop policy if exists "Read participant messages" on public.messages;
drop policy if exists "Send participant messages" on public.messages;
revoke all on public.messages from public, anon, authenticated;
grant select, insert on public.messages to authenticated;
create policy "Read participant messages" on public.messages for select to authenticated
    using (
        (booking_id is not null and trip_id is null and public.is_booking_participant(booking_id))
        or (trip_id is not null and booking_id is null and public.is_trip_participant(trip_id))
    );
create policy "Send participant messages" on public.messages for insert to authenticated
    with check (
        sender_id = (select auth.uid()) and (
            (booking_id is not null and trip_id is null and public.is_booking_participant(booking_id))
            or (trip_id is not null and booking_id is null and public.is_trip_participant(trip_id))
        )
    );
-- Updating/deleting messages is intentionally not granted in this baseline.

-- The current view filters small groups, but staff authorisation and counting
-- correctness are not established. Do not expose the underlying aggregate table.
alter table public.impact_aggregates enable row level security;
revoke all on public.impact_aggregates, public.anonymised_impact_dashboard
    from public, anon, authenticated;
commit;
