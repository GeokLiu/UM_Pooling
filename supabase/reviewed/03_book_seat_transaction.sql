begin;
create or replace function public.book_seat_transaction(
    p_trip_offer_id uuid,
    p_passenger_id uuid,
    p_seats integer,
    p_pickup_lng double precision,
    p_pickup_lat double precision
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_user_id uuid := auth.uid();
    v_offer public.trip_offers%rowtype;
    v_booking_id uuid;
begin
    if v_user_id is null then
        raise exception 'Sign in before booking';
    end if;
    if p_passenger_id is distinct from v_user_id then
        raise exception 'You cannot book for another user';
    end if;
    if p_trip_offer_id is null then
        raise exception 'Trip offer is required';
    end if;
    if p_seats is null or p_seats <= 0 then
        raise exception 'Seats must be a positive integer';
    end if;
    if p_pickup_lng is null or not (p_pickup_lng between -180 and 180)
       or p_pickup_lat is null or not (p_pickup_lat between -90 and 90) then
        raise exception 'Valid pickup coordinates are required';
    end if;

    select * into v_offer from public.trip_offers
    where trip_offer_id = p_trip_offer_id for update;
    if not found then
        raise exception 'Trip offer not found';
    end if;
    if v_offer.driver_id = v_user_id then
        raise exception 'Drivers cannot book their own offer';
    end if;
    if v_offer.status::text is distinct from 'open' then
        raise exception 'Trip offer is not open';
    end if;
    if v_offer.departure_time <= now() then
        raise exception 'Trip offer has already departed';
    end if;
    if v_offer.available_seats < p_seats then
        raise exception 'Not enough seats available';
    end if;

    insert into public.bookings (
        trip_offer_id, passenger_id, seats_booked, pickup_geo, status
    ) values (
        p_trip_offer_id, v_user_id, p_seats,
        public.st_setsrid(public.st_makepoint(p_pickup_lng, p_pickup_lat),4326)::public.geography,
        'confirmed'
    ) returning booking_id into v_booking_id;

    update public.trip_offers
    set available_seats = available_seats - p_seats,
        status = (case when available_seats - p_seats = 0 then 'full' else 'open' end)::public.offer_status
    where trip_offer_id = p_trip_offer_id;
    return v_booking_id;
end;
$function$;

revoke all on function public.book_seat_transaction(uuid,uuid,integer,double precision,double precision)
    from public, anon;
grant execute on function public.book_seat_transaction(uuid,uuid,integer,double precision,double precision)
    to authenticated;
commit;
