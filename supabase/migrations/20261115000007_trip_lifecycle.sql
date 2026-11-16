-- Trip lifecycle: start, passenger confirmation, completion, cancellation.
-- Not applied to the shared database. Apply in staging, then run
-- supabase/checks/01_trip_lifecycle_test.sql.
--
-- Flow
--   1. Passengers book an offer (book_seat_transaction): booking status 'confirmed', trip_id empty.
--   2. The driver calls start_trip(offer): a trips row is created as in_progress, the confirmed
--      bookings are linked to it, and the offer is closed to new bookings (status 'full').
--   3. Each passenger calls confirm_trip_end(trip): their booking becomes 'completed'.
--   4. The driver calls complete_trip(trip): needs at least one confirmed passenger. Passengers who
--      did not confirm become 'no_show'. The trip becomes 'completed' and stores the passenger
--      count (sum of seats on confirmed bookings). Distance was copied from the offer at start.
--      The CO2 and tier calculation (Member 4) hooks onto trips going to 'completed'.
--   5. The driver may call cancel_trip(trip) while the trip is in progress.
--
-- Only these functions change trips, and clients cannot write the tables directly (migration 4).
-- Counting rules (distance, daily cap) belong to the CO2 trigger, not here.
begin;

-- Migration 4 allowed drivers to edit status directly. That could reopen an
-- in-progress offer and accept bookings with no trip_id. Only lifecycle RPCs
-- may change status; keep both table-level and legacy column-level grants closed.
revoke update on public.trip_offers from public, anon, authenticated;
revoke update (status, available_seats) on public.trip_offers from public, anon, authenticated;
grant update (origin_geo, destination_geo, cost_per_seat, departure_time,
    origin_zone, destination_zone, distance_km) on public.trip_offers to authenticated;

create or replace function public.start_trip(p_trip_offer_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_user uuid := auth.uid();
    v_offer public.trip_offers%rowtype;
    v_trip_id uuid;
    v_plate text;
    v_bookings integer;
begin
    if v_user is null then
        raise exception 'Sign in first';
    end if;

    select * into v_offer from public.trip_offers
    where trip_offer_id = p_trip_offer_id for update;
    if not found then
        raise exception 'Trip offer not found';
    end if;
    if v_offer.driver_id is distinct from v_user then
        raise exception 'Only the driver can start this trip';
    end if;
    if v_offer.status::text not in ('open', 'full') then
        raise exception 'This offer cannot be started';
    end if;
    if exists (
        select 1 from public.trips t
        where t.trip_offer_id = p_trip_offer_id and t.status::text <> 'cancelled'
    ) then
        raise exception 'This trip has already been started';
    end if;
    -- A trip may be started up to 2 hours before its departure time.
    if now() < v_offer.departure_time - interval '2 hours' then
        raise exception 'Too early to start this trip';
    end if;

    select count(*) into v_bookings from public.bookings b
    where b.trip_offer_id = p_trip_offer_id and b.status = 'confirmed' and b.trip_id is null;
    if v_bookings = 0 then
        raise exception 'There are no confirmed bookings to start';
    end if;

    select "vehiclePlate" into v_plate from public.users where "usersId" = v_user;

    insert into public.trips (
        trip_offer_id, driver_id, status, start_time,
        origin_zone, destination_zone, distance_km, vehicle_plate_snapshot
    ) values (
        p_trip_offer_id, v_user, 'in_progress'::public.trip_status, now(),
        v_offer.origin_zone, v_offer.destination_zone, v_offer.distance_km, v_plate
    ) returning trip_id into v_trip_id;

    update public.bookings set trip_id = v_trip_id
    where trip_offer_id = p_trip_offer_id and status = 'confirmed' and trip_id is null;

    -- 'full' stops further bookings, because book_seat_transaction only accepts open offers.
    update public.trip_offers set status = 'full'::public.offer_status
    where trip_offer_id = p_trip_offer_id;

    return v_trip_id;
end;
$function$;

create or replace function public.confirm_trip_end(p_trip_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_user uuid := auth.uid();
    v_status text;
begin
    if v_user is null then
        raise exception 'Sign in first';
    end if;

    select t.status::text into v_status from public.trips t
    where t.trip_id = p_trip_id for update;
    if not found then
        raise exception 'Trip not found';
    end if;
    if v_status <> 'in_progress' then
        raise exception 'This trip is not in progress';
    end if;

    update public.bookings set status = 'completed'
    where trip_id = p_trip_id and passenger_id = v_user and status = 'confirmed';
    if not found then
        raise exception 'You have no unconfirmed booking on this trip';
    end if;
end;
$function$;

create or replace function public.complete_trip(p_trip_id uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_user uuid := auth.uid();
    v_trip public.trips%rowtype;
    v_passengers integer;
begin
    if v_user is null then
        raise exception 'Sign in first';
    end if;

    select * into v_trip from public.trips where trip_id = p_trip_id for update;
    if not found then
        raise exception 'Trip not found';
    end if;
    if v_trip.driver_id is distinct from v_user then
        raise exception 'Only the driver can complete this trip';
    end if;
    if v_trip.status::text <> 'in_progress' then
        raise exception 'This trip is not in progress';
    end if;

    select coalesce(sum(seats_booked), 0) into v_passengers from public.bookings
    where trip_id = p_trip_id and status = 'completed';
    if v_passengers < 1 then
        raise exception 'At least one passenger must confirm the trip end first';
    end if;

    update public.bookings set status = 'no_show'
    where trip_id = p_trip_id and status = 'confirmed';

    update public.trips
    set status = 'completed'::public.trip_status,
        end_time = now(),
        confirmed_passenger_count = v_passengers
    where trip_id = p_trip_id;

    update public.trip_offers set status = 'completed'::public.offer_status
    where trip_offer_id = v_trip.trip_offer_id;

    return v_passengers;
end;
$function$;

create or replace function public.cancel_trip(p_trip_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_user uuid := auth.uid();
    v_trip public.trips%rowtype;
begin
    if v_user is null then
        raise exception 'Sign in first';
    end if;

    select * into v_trip from public.trips where trip_id = p_trip_id for update;
    if not found then
        raise exception 'Trip not found';
    end if;
    if v_trip.driver_id is distinct from v_user then
        raise exception 'Only the driver can cancel this trip';
    end if;
    if v_trip.status::text <> 'in_progress' then
        raise exception 'Only a trip in progress can be cancelled';
    end if;

    update public.bookings set status = 'cancelled'
    where trip_id = p_trip_id and status in ('confirmed', 'completed');

    update public.trips
    set status = 'cancelled'::public.trip_status, end_time = now()
    where trip_id = p_trip_id;

    update public.trip_offers set status = 'cancelled'::public.offer_status
    where trip_offer_id = v_trip.trip_offer_id;
end;
$function$;

revoke all on function public.start_trip(uuid) from public, anon;
revoke all on function public.confirm_trip_end(uuid) from public, anon;
revoke all on function public.complete_trip(uuid) from public, anon;
revoke all on function public.cancel_trip(uuid) from public, anon;
grant execute on function public.start_trip(uuid) to authenticated;
grant execute on function public.confirm_trip_end(uuid) to authenticated;
grant execute on function public.complete_trip(uuid) to authenticated;
grant execute on function public.cancel_trip(uuid) to authenticated;

commit;
