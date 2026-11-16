-- Run this first; nothing in this file changes data.
select c.relname as relation_name, c.relkind as relation_kind,
       c.relrowsecurity as rls_enabled,
       jsonb_agg(jsonb_build_object('column',a.attname,
           'type',format_type(a.atttypid,a.atttypmod),
           'not_null',a.attnotnull) order by a.attnum) as columns
from pg_class c
join pg_namespace n on n.oid=c.relnamespace
join pg_attribute a on a.attrelid=c.oid and a.attnum>0 and not a.attisdropped
where n.nspname='public'
  and c.relname in ('users','impact_stats','user_impact_stats')
group by c.oid,c.relname,c.relkind,c.relrowsecurity;

-- A nonzero result requires data repair before relying on one-target chat policies.
select count(*) as messages_with_both_targets
from public.messages where trip_id is not null and booking_id is not null;

-- Existing triggers must be reviewed to avoid decrementing seats twice or
-- duplicating profile creation. This lists trigger definitions, not secrets.
select n.nspname as schema_name, c.relname as table_name,
       t.tgname as trigger_name, pg_get_triggerdef(t.oid) as trigger_definition
from pg_trigger t join pg_class c on c.oid=t.tgrelid
join pg_namespace n on n.oid=c.relnamespace
where not t.tgisinternal and (
    (n.nspname='public' and c.relname in ('bookings','trip_offers','trips','users'))
    or (n.nspname='auth' and c.relname='users')
);

-- Existing table/column grants can survive changes to RLS. Inspect both.
select * from information_schema.role_table_grants
where table_schema='public' and table_name in (
    'users','bookings','trips','messages','trip_offers',
    'user_impact_stats','impact_aggregates','anonymised_impact_dashboard'
);
select * from information_schema.role_column_grants
where table_schema='public' and table_name in ('users','bookings','trips','trip_offers','messages');
