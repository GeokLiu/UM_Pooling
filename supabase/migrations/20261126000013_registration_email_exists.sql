-- Product requirement: show an explicit login prompt for registered UM emails.
-- Deliberately reveals only registration existence, not IDs, verification state,
-- profiles or credentials. This replaces signup's account-enumeration masking.
-- Keep signup CAPTCHA/rate limits enabled; this RPC is also publicly callable.
begin;
create or replace function public.registration_email_exists(p_email text)
returns boolean
language plpgsql stable security definer set search_path = ''
as $function$
declare v_email text := lower(btrim(p_email));
begin
    if v_email is null or length(v_email) > 254
       or v_email !~ '^[^@[:space:]]+@(siswa[.]um[.]edu[.]my|um[.]edu[.]my)$' then
        return false;
    end if;
    return exists (select 1 from auth.users u where lower(u.email) = v_email);
end;
$function$;
revoke all on function public.registration_email_exists(text) from public;
grant execute on function public.registration_email_exists(text) to anon, authenticated;
commit;
