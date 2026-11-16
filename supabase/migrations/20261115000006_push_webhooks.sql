-- Applied to the live project on 2026-11-15.
-- Replaces the three webhook triggers (bookings, new-message, sos-alert) that embedded the
-- service-role key. The new trigger reads a webhook secret from Supabase Vault and sends it
-- in the x-webhook-secret header, which supabase/functions/swift-worker checks.
--
-- Before running:
--   1. Create the secret in Vault:  select vault.create_secret('<random value>', 'webhook_secret');
--   2. Add the same value as the Edge Function secret WEBHOOK_SECRET.
--   3. Deploy supabase/functions/swift-worker with "Verify JWT" off.
-- Never save the secret value in this file.
begin;

create or replace function public.notify_push()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_secret text;
begin
    select decrypted_secret into v_secret
    from vault.decrypted_secrets where name = 'webhook_secret';

    -- Asynchronous: the insert never waits for, or fails because of, the push call.
    perform net.http_post(
        url := 'https://trzzdcsfpsdlxxwvuufx.supabase.co/functions/v1/swift-worker',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'x-webhook-secret', coalesce(v_secret, '')
        ),
        body := jsonb_build_object('table', tg_table_name, 'record', to_jsonb(new)),
        timeout_milliseconds := 5000
    );
    return new;
exception when others then
    raise warning 'push webhook failed: %', sqlerrm;
    return new;
end;
$function$;
revoke all on function public.notify_push() from public, anon, authenticated;

drop trigger if exists "bookings" on public.bookings;
drop trigger if exists "new-message" on public.messages;
drop trigger if exists "sos-alert" on public.sos_alerts;

drop trigger if exists notify_booking on public.bookings;
create trigger notify_booking after insert on public.bookings
    for each row execute function public.notify_push();
drop trigger if exists notify_message on public.messages;
create trigger notify_message after insert on public.messages
    for each row execute function public.notify_push();
drop trigger if exists notify_sos on public.sos_alerts;
create trigger notify_sos after insert on public.sos_alerts
    for each row execute function public.notify_push();

commit;
