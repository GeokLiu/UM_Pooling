-- Self-cleaning test for migration 20261115000007_trip_lifecycle.sql.
-- Creates throwaway users and exercises completion, status protection and cancellation.
-- Staging only: rolls back database rows; do not use it to test external push delivery.
-- It ALWAYS ends with an exception, so every change is rolled back automatically:
--   "TRIP LIFECYCLE TESTS PASSED (rolled back)"  means everything worked.
--   Any other message names the step that failed.
-- Run it only after applying migration 7. Paste the final message back to the team.
do $test$
declare
    v_driver uuid := gen_random_uuid();
    v_passenger uuid := gen_random_uuid();
    v_other uuid := gen_random_uuid();
    v_cancel_offer uuid;
    v_cancel_trip uuid;
    v_offer uuid;
    v_booking uuid;
    v_trip uuid;
    v_count integer;
    v_text text;
begin
    -- Setup as the database owner. The auth trigger creates the profile rows.
    insert into auth.users (id, email) values
        (v_driver, 'zz-test-driver@siswa.um.edu.my'),
        (v_passenger, 'zz-test-passenger@siswa.um.edu.my'),
        (v_other, 'zz-test-other@siswa.um.edu.my');
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

    insert into public.trip_offers (
        driver_id, origin_geo, destination_geo, cost_per_seat, available_seats,
        departure_time, origin_zone, destination_zone, distance_km
    ) select driver_id, origin_geo, destination_geo, cost_per_seat, 2,
        departure_time, origin_zone, destination_zone, distance_km
      from public.trip_offers where trip_offer_id = v_offer
    returning trip_offer_id into v_cancel_offer;

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

    -- Regression: the driver must not reopen an active offer, even with seats left.
    execute 'set local role authenticated';
    begin
        update public.trip_offers set status = 'open'::public.offer_status
        where trip_offer_id = v_offer;
        raise exception 'FAIL status protection: driver reopened an active offer';
    exception when insufficient_privilege then
        null;
    end;
    -- Harmless offer edits remain available to its driver.
    update public.trip_offers set origin_zone = 'test-origin-edited'
    where trip_offer_id = v_offer;
    if not found then raise exception 'FAIL status protection: safe driver edit was blocked'; end if;
    perform set_config('request.jwt.claim.sub', v_other::text, true);
    begin
        perform public.book_seat_transaction(v_offer, v_other, 1, 101.6550, 3.1250);
        raise exception 'FAIL status protection: new booking on active trip';
    exception when others then
        if sqlerrm <> 'Trip offer is not open' then raise; end if;
    end;
    begin
        perform public.confirm_trip_end(v_trip);
        raise exception 'FAIL identity: outsider confirmed a trip';
    exception when others then
        if sqlerrm <> 'You have no unconfirmed booking on this trip' then raise; end if;
    end;
    perform set_config('request.jwt.claim.sub', v_passenger::text, true);
    begin
        perform public.complete_trip(v_trip);
        raise exception 'FAIL identity: passenger completed a trip';
    exception when others then
        if sqlerrm <> 'Only the driver can complete this trip' then raise; end if;
    end;
    begin
        perform public.cancel_trip(v_trip);
        raise exception 'FAIL identity: passenger cancelled a trip';
    exception when others then
        if sqlerrm <> 'Only the driver can cancel this trip' then raise; end if;
    end;
    perform set_config('request.jwt.claim.sub', v_driver::text, true);

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

    -- Completed trips cannot be reopened or cancelled through the driver account.
    execute 'set local role authenticated';
    begin
        update public.trip_offers set status = 'open'::public.offer_status
        where trip_offer_id = v_offer;
        raise exception 'FAIL status protection: driver reopened a completed offer';
    exception when insufficient_privilege then null;
    end;
    begin
        perform public.cancel_trip(v_trip);
        raise exception 'FAIL cancellation: completed trip was cancelled';
    exception when others then
        if sqlerrm <> 'Only a trip in progress can be cancelled' then raise; end if;
    end;

    -- Cancellation covers both an end-confirmed and an unconfirmed passenger.
    perform set_config('request.jwt.claim.sub', v_passenger::text, true);
    perform public.book_seat_transaction(v_cancel_offer, v_passenger, 1, 101.6550, 3.1250);
    perform set_config('request.jwt.claim.sub', v_other::text, true);
    perform public.book_seat_transaction(v_cancel_offer, v_other, 1, 101.6550, 3.1250);
    perform set_config('request.jwt.claim.sub', v_driver::text, true);
    v_cancel_trip := public.start_trip(v_cancel_offer);
    perform set_config('request.jwt.claim.sub', v_passenger::text, true);
    perform public.confirm_trip_end(v_cancel_trip);
    perform set_config('request.jwt.claim.sub', v_driver::text, true);
    perform public.cancel_trip(v_cancel_trip);
    begin
        perform public.cancel_trip(v_cancel_trip);
        raise exception 'FAIL cancellation: trip cancelled twice';
    exception when others then
        if sqlerrm <> 'Only a trip in progress can be cancelled' then raise; end if;
    end;
    begin
        update public.trip_offers set status = 'open'::public.offer_status
        where trip_offer_id = v_cancel_offer;
        raise exception 'FAIL status protection: driver reopened a cancelled offer';
    exception when insufficient_privilege then null;
    end;
    perform set_config('request.jwt.claim.sub', v_other::text, true);
    begin
        perform public.confirm_trip_end(v_cancel_trip);
        raise exception 'FAIL cancellation: passenger confirmed after cancellation';
    exception when others then
        if sqlerrm <> 'This trip is not in progress' then raise; end if;
    end;
    reset role;
    select count(*) into v_count from public.bookings
    where trip_id = v_cancel_trip and status = 'cancelled';
    if v_count <> 2 then raise exception 'FAIL cancellation: not all bookings cancelled'; end if;
    select status::text into v_text from public.trips where trip_id = v_cancel_trip;
    if v_text <> 'cancelled' then raise exception 'FAIL cancellation: trip not cancelled'; end if;
    select status::text into v_text from public.trip_offers where trip_offer_id = v_cancel_offer;
    if v_text <> 'cancelled' then raise exception 'FAIL cancellation: offer not cancelled'; end if;
    select available_seats into v_count from public.trip_offers where trip_offer_id = v_cancel_offer;
    if v_count <> 0 then raise exception 'FAIL cancellation: terminal offer seats unexpectedly changed'; end if;

    raise exception 'TRIP LIFECYCLE TESTS PASSED (rolled back)';
end;
$test$;
