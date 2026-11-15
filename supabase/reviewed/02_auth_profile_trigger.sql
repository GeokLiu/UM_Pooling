-- Replaces scripts 3 and the trigger portion of script 5.
begin;
create or replace function public.handle_new_um_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_email text := lower(btrim(new.email));
    v_domain text;
begin
    v_domain := split_part(v_email, '@', 2);
    if v_email is null
       or v_email !~ '^[^@[:space:]]+@[^@[:space:]]+$'
       or v_domain not in ('siswa.um.edu.my', 'um.edu.my') then
        raise exception 'Registration requires a UM email address';
    end if;

    insert into public.users ("usersId", "usersEmail", "usersRole")
    values (new.id, v_email, 'passengers')
    on conflict ("usersId") do nothing;
    return new;
end;
$function$;

-- AFTER ensures the referenced auth.users row exists before creating its profile.
-- An exception still rolls back the Auth insert and profile together.
-- Export confirms this second trigger calls handle_new_user() and also creates
-- the same profile. Remove the trigger, but preserve its function for audit.
drop trigger if exists on_auth_user_created on auth.users;
drop trigger if exists enforce_email_domain on auth.users;
drop trigger if exists on_auth_user_created_um on auth.users;
create trigger on_auth_user_created_um
    after insert on auth.users
    for each row execute function public.handle_new_um_user();

revoke all on function public.handle_new_um_user() from public, anon, authenticated;
-- Trigger execution does not require granting API callers direct RPC execution.
commit;
