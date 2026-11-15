-- Self-cleaning test for migration 20261115000007_trip_lifecycle.sql.
-- Creates two throwaway users, an offer, a booking and walks one trip through the lifecycle.
-- It ALWAYS ends with an exception, so every change is rolled back automatically:
--   "TRIP LIFECYCLE TESTS PASSED (rolled back)"  means everything worked.
--   Any other message names the step that failed.
-- Run it only after applying migration 7. Paste the final message back to the team.
do $test$
declare
    v_driver uuid := gen_random_uuid();
    v_passenger uuid := gen_random_uuid();
    v_offer uuid;
    v_booking uuid;
    v_trip uuid;
    v_count integer;
    v_text text;
begin
    -- Setup as the database owner. The auth trigger creates the profile rows.
    insert into auth.users (id, email) values
        (v_driver, 'zz-test-driver@siswa.um.edu.my'),
        (v_passenger, 'zz-test-passenger@siswa.um.edu.my');
    update public.users set "usersRole" = 'drivers'::public.user_role, "vehiclePlate" = 'TEST1234'
    where "usersId" = v_driver;

    insert into public.trip_offers (
        driver_id, origin_geo, destination_geo, cost_per_seat, available_seats,
        departure_time, origin_zone, destination_zone, distance_km
    ) values (
        v_driver,
        public.st_setsrid(public.st_makepoint(101.6500, 3.1200), 4326)::public.geography,
        public.st_setsrid(public.st_makepoint(101.6600, 3.1300), 4326)::public.geography,
        3.00, 2, now() + interval '1 hour', 'test-origin', 'test-destination', 5.0
    ) returning trip_offer_id into v_offer;

    -- 1. Passenger books one seat
    execute 'set local role authenticated';
    perform set_config('request.jwt.claim.sub', v_passenger::text, true);
    v_booking := public.book_seat_transaction(v_offer, v_passenger, 1, 101.6550, 3.1250);

    -- 2. A passenger cannot start the trip
    begin
        perform public.start_trip(v_offer);
        raise exception 'FAIL step 2: a passenger could start the trip';
    exception when others then
        if sqlerrm not like 'Only the driver%' then raise; end if;
    end;

    -- 3. The driver starts the trip
    perform set_config('request.jwt.claim.sub', v_driver::text, true);
    v_trip := public.start_trip(v_offer);
    reset role;
    select count(*) into v_count from public.bookings where booking_id = v_booking and trip_id = v_trip;
    if v_count <> 1 then raise exception 'FAIL step 3: booking was not linked to the trip'; end if;
    select status::text into v_text from public.trip_offers where trip_offer_id = v_offer;
    if v_text <> 'full' then raise exception 'FAIL step 3: offer should be closed, was %', v_text; end if;
    select status::text into v_text from public.trips where trip_id = v_trip;
    if v_text <> 'in_progress' then raise exception 'FAIL step 3: trip status was %', v_text; end if;

    -- 4. Starting twice fails
    execute 'set local role authenticated';
    begin
        perform public.start_trip(v_offer);
        raise exception 'FAIL step 4: trip started twice';
    exception when others then
        if sqlerrm not like '%already been started%' and sqlerrm not like '%cannot be started%' then raise; end if;
    end;

    -- 5. The driver cannot complete before a passenger confirms
    begin
        perform public.complete_trip(v_trip);
        raise exception 'FAIL step 5: completed with no passenger confirmation';
    exception when others then
        if sqlerrm not like 'At least one passenger%' then raise; end if;
    end;

    -- 6. The passenger confirms, the driver completes
    perform set_config('request.jwt.claim.sub', v_passenger::text, true);
    perform public.confirm_trip_end(v_trip);
    perform set_config('request.jwt.claim.sub', v_driver::text, true);
    v_count := public.complete_trip(v_trip);
    reset role;
    if v_count <> 1 then raise exception 'FAIL step 6: passenger count was %', v_count; end if;
    select status::text into v_text from public.trips where trip_id = v_trip;
    if v_text <> 'completed' then raise exception 'FAIL step 6: trip status was %', v_text; end if;
    select confirmed_passenger_count into v_count from public.trips where trip_id = v_trip;
    if v_count <> 1 then raise exception 'FAIL step 6: stored count was %', v_count; end if;

    raise exception 'TRIP LIFECYCLE TESTS PASSED (rolled back)';
end;
$test$;
