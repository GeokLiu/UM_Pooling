-- Rollback-only check, run on an isolated database after migration 13.
begin;
insert into auth.users(id,email) values
    ('63000000-0000-0000-0000-000000000001','signup-existing@siswa.um.edu.my');
set local role anon;
do $test$
begin
    if not public.registration_email_exists('  SIGNUP-EXISTING@SISWA.UM.EDU.MY ') then
        raise exception 'Existing registration must be detected after normalization';
    end if;
    if public.registration_email_exists('signup-new@siswa.um.edu.my') then
        raise exception 'New address must not be reported as registered';
    end if;
    if public.registration_email_exists(null) or public.registration_email_exists('x@gmail.com')
       or public.registration_email_exists('a@siswa.um.edu.my.evil.com') then
        raise exception 'Invalid/non-UM inputs must return false';
    end if;
end;
$test$;
rollback;
