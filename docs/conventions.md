# Coding conventions

Applies to all members. The rules for branches, commits and pull requests are in `CONTRIBUTING.md`; this file adds the technical conventions.

## Android (Kotlin)

- Package `com.fopgang.umpooling`, with a sub-package per feature (`data`, `ui.theme`, `notifications`, and later `auth`, `matching`, `booking`, `safety`, `ai`).
- Architecture: UI (Compose) calls a ViewModel, which calls a repository, which calls Supabase. Composables never call Supabase directly.
- Naming: classes and composables `PascalCase`, functions and variables `camelCase`, constants `UPPER_SNAKE_CASE`.
- Strings go in `res/values/strings.xml` and `res/values-ms/strings.xml`, never hard-coded.
- Repositories return `Result<T>` and must not swallow coroutine cancellation (see `RideRepository`).
- Models map database columns with `@SerialName`. Use the constants in `Models.kt` for enum labels, for example `RequestStatus.PENDING`; labels are case sensitive.
- Geography values are sent as text built by `GeoPoint.ewkt(lng, lat)`. Longitude comes first.
- Validate UM emails with `UmEmail.isValid` only; do not write new `endsWith` checks.

## Database (Supabase)

- New tables and columns use snake_case. Only `users` keeps its legacy camelCase names (`"usersId"` and others); do not rename them without a coordinated change across the app, the database and the Edge Function.
- Every table has RLS enabled. Clients get the narrowest grants possible. Writes that need rules (booking, trips, roles) go through RPC functions, not direct table writes.
- RPC and trigger functions that run as the owner (`security definer`) must set `search_path = ''` and use fully qualified names.
- Changes are SQL files in `supabase/migrations/`, named `<yyyymmddhhmmss>_<name>.sql`, written to be re-runnable (`if not exists`, `create or replace`, `drop ... if exists`). Review by Member 2 before applying.
- Do not edit a migration that has been applied. Add a new one.
- Read-only inspection queries go in `supabase/checks/`.

## Edge Functions

- TypeScript on Deno, in `supabase/functions/<slug>/index.ts`.
- Authenticate the caller (for webhooks, the `x-webhook-secret` header). Never trust the request body alone.
- Return generic errors to the caller and log details with `console.error`. Never log tokens or personal data.

## Secrets

- Never commit: the service-role or secret key, `local.properties`, `google-services.json`, keystores, webhook secrets, Firebase private keys.
- The app uses only the publishable key. Server-side secrets live in Supabase function secrets and Vault.
- If a secret appears in a chat, a commit or a screenshot, treat it as leaked and rotate it.

## Tests

- Pure logic (validation, CO2 calculation, formatting) has JUnit tests in `app/src/test`.
- Run `bash gradlew :app:assembleDebug :app:testDebugUnitTest` before opening a pull request. The build must pass without `app/google-services.json`.

## Documentation and AI use

- Notes and drafts go in `docs/`; evidence (survey, tests, screenshots) in `evidence/`.
- Log every meaningful AI use in `AI_Usage_Log.md` the same day, with your own member number.
