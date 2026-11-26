-- FR2.2: Notify drivers with overlapping saved routes or open trip offers
-- when a passenger posts a ride request.
-- Uses Member 2's public.notify_push() webhook -> supabase/functions/swift-worker.

begin;

-- Spatial overlap lookup used by swift-worker for ride_requests (FR2.2).
-- Matches drivers whose saved_routes or open trip_offers fall within:
--   * p_origin_radius_m (default 500 m) of pickup_geo
--   * p_dest_radius_m   (default 300 m) of destination_geo (when provided)
--   * p_window_minutes  (default +/- 15 min) of preferred_time (for open trip_offers)
create or replace function public.find_overlapping_drivers_for_request(
    p_pickup_geo geography,
    p_destination_geo geography default null,
    p_preferred_time timestamptz default null,
    p_requester_id uuid default null,
    p_origin_radius_m double precision default 500.0,
    p_dest_radius_m double precision default 300.0,
    p_window_minutes integer default 15
)
returns table (
    driver_id uuid,
    available_seats integer,
    departure_time timestamptz,
    distance_km double precision
)
language sql
stable
security definer
set search_path = ''
as $function$
    with matching_offers as (
        select
            o.driver_id,
            o.available_seats,
            o.departure_time,
            coalesce(
                o.distance_km,
                case
                    when p_destination_geo is not null
                    then (extensions.st_distance(p_pickup_geo, p_destination_geo) / 1000.0) * 1.3
                    else 5.0
                end
            ) as distance_km
        from public.trip_offers o
        where o.status = 'open'::public.offer_status
          and o.available_seats > 0
          and o.departure_time >= now()
          and (p_requester_id is null or o.driver_id <> p_requester_id)
          and extensions.st_dwithin(o.origin_geo, p_pickup_geo, p_origin_radius_m)
          and (
              p_destination_geo is null
              or extensions.st_dwithin(o.destination_geo, p_destination_geo, p_dest_radius_m)
          )
          and (
              p_preferred_time is null
              or abs(extract(epoch from (o.departure_time - p_preferred_time))) <= (p_window_minutes * 60)
          )
    ),
    matching_saved_routes as (
        select
            sr.user_id as driver_id,
            3 as available_seats,
            coalesce(p_preferred_time, now()) as departure_time,
            case
                when p_destination_geo is not null
                then (extensions.st_distance(p_pickup_geo, p_destination_geo) / 1000.0) * 1.3
                else 5.0
            end as distance_km
        from public.saved_routes sr
        join public.users u on u."usersId" = sr.user_id
        where u."usersRole" in ('drivers', 'both')
          and (p_requester_id is null or sr.user_id <> p_requester_id)
          and extensions.st_dwithin(sr.origin_geo, p_pickup_geo, p_origin_radius_m)
          and (
              p_destination_geo is null
              or extensions.st_dwithin(sr.destination_geo, p_destination_geo, p_dest_radius_m)
          )
    ),
    combined as (
        select * from matching_offers
        union all
        select * from matching_saved_routes
    )
    select distinct on (c.driver_id)
        c.driver_id,
        c.available_seats,
        c.departure_time,
        c.distance_km
    from combined c
    order by c.driver_id, c.departure_time asc;
$function$;

revoke all on function public.find_overlapping_drivers_for_request(
    geography, geography, timestamptz, uuid, double precision, double precision, integer
) from public, anon, authenticated;
grant execute on function public.find_overlapping_drivers_for_request(
    geography, geography, timestamptz, uuid, double precision, double precision, integer
) to service_role;

drop trigger if exists notify_ride_request on public.ride_requests;
create trigger notify_ride_request after insert on public.ride_requests
    for each row execute function public.notify_push();

commit;
