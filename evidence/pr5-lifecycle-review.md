# PR #5 lifecycle review fix — 2026-11-16

Reviewed base: `5d00e9407070cf2ce437cfb67e4f7c4e413d1638`
(`josephineding-2025/UMPooling:fix/main-cleanup`).

## Problem and change

Migration 4 granted drivers column-level UPDATE of offer status. After start_trip
set an offer to full, its driver could set it back to open. With a future departure
and spare seats, the booking RPC would accept an additional booking without a
trip_id. Migration 7 now removes direct client status updates, including inherited
PUBLIC table grants and legacy column grants, while preserving ordinary driver
field edits. Lifecycle RPCs retain the trusted owner's ability to update status.

No already-applied migration was rewritten for this fix; migration 7 is still
reported as unapplied to the shared project. Confirm that before applying it.

## Local execution results

Executed against an isolated, network-disabled Docker PostgreSQL 16/PostGIS 3.5
instance with tables/constraints/initial policies reconstructed from the supplied
Supabase schema exports. Applied repository migrations 1–5, then the original 7.
Supabase auth.uid()/auth.role() were represented by local test functions using
request claims, and anon/authenticated roles were created locally. Request enum
labels cover both the older export's pending default and documented newer labels;
ride-request behaviour was not part of this test.

Migration 6 / Vault / pg_net / push webhooks were deliberately not installed.
This is an export-derived fixture, not an exact Supabase staging clone.

1. Expanded test against original migration 7 failed with:
   `FAIL status protection: driver reopened an active offer`.
2. Applied corrected migration 7 and reran the same test. It reached:
   `TRIP LIFECYCLE TESTS PASSED (rolled back)`.
3. A separate query confirmed zero zz-test-* Auth rows remained after rollback.
4. SQL/PLpgSQL parsing and git diff --check passed.

Covered: normal booking/start/end confirmation/completion, duplicate start,
completion before confirmation, outsider confirmation, passenger completion/
cancellation rejection, direct reopen attempts on active/completed/cancelled
offers, post-start booking rejection, allowed driver field edit, cancelling both
confirmed and end-confirmed bookings, repeated cancellation, and confirmation
after cancellation.

## Limits and handoff

- Run migration 7 and the rollback-based test in an actual development/staging
  copy next. Confirm schema/enums/privileges match and existing triggers do not
  duplicate lifecycle updates. Do not apply it to the shared project for review.
- The test ends with the exact deliberate exception shown above. Any other error
  is a failure. Rollback does not undo non-transactional external effects; do not
  point a staging test at production notification recipients.
- Cancellation tested here is driver cancellation of an in-progress whole trip.
  The cancelled offer stays terminal; no seat inventory is reopened for sale.
  Passenger booking cancellation/seat restoration and pre-start cancellation
  remain unimplemented, separately scoped work.
- No concurrent-session load test, real Auth sign-in, Android build/device test,
  CO2 accounting, Firebase delivery, or live database operation was performed
  for this SQL-only change. Existing Android source was not modified.
- No approval or merge was submitted. Another teammate should review the fix and
  staging evidence before PR #5 is approved.
