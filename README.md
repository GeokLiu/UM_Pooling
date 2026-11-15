# UMPooling

A UM-only campus carpooling app for Universiti Malaya students and staff. Users with verified UM email accounts share rides, see the CO2 they save, and help UM raise climate awareness and plan lower-carbon commuting.

- **Course:** WIA2007 Mobile Application Development, Group Project 2026/2027 Semester 1 (OCC 8)
- **Group:** Group 9 (FOPGang)
- **SDG:** SDG 13 Climate Action, Target 13.3 (education, awareness-raising and capacity on climate action)
- **Platform:** Android (Kotlin, Jetpack Compose)

## Team

| Member | Role | Main area |
|---|---|---|
| Josephine Ding Jie Yu | Project manager and developer | M1 Authentication and Green Commuter Profile |
| Ng Geok Liu | Lead developer / architect | Backend, M3 booking and trip completion |
| Ng Yue Qhi | UI/UX and developer | Design system, chat, dashboard screens |
| Jasmine Chin Jia Yee | AI developer | M5 AI assistant and CO2 analytics |
| Ng Shao Ern | Developer | M2 ride matching and maps |
| Jasmine Chin Ying Hui | Developer and tester | M4 safety, survey, tests |

Full task split by phase: [docs/Task_Division.md](docs/Task_Division.md).

## Modules

| Module | Summary |
|---|---|
| M1 Authentication and Green Commuter Profile | UM email only, email verification, commuter profile, Green Commuter Tier |
| M2 Ride Matching and Location-Based Dispatch | Saved routes and zones, driver notifications, filterable feed with CO2 per offer |
| M3 Booking, Cost-Sharing and Coordination | Capped cost-share, seat reservation, trip-end CO2, in-app chat |
| M4 Commuter Safety and Emergency | Trip record, SOS message, ratings |
| M5 AI Commuting Assistant and Climate Impact Analytics | Natural-language requests, pickup grouping, CO2 dashboard |

Requirements and the SDG 13.3 mapping: [docs/UMPooling.md](docs/UMPooling.md).

## Getting started

Requirements: Android Studio, JDK 21, the Android SDK, and a device or emulator running Android 7.0 (API 24) or higher.

1. Clone the repo and set your own Git identity:
   ```
   git clone https://github.com/josephineding-2025/UMPooling.git
   git config user.name "Your Name"
   git config user.email "your-email@siswa.um.edu.my"
   ```
2. Open the folder in Android Studio and let Gradle sync. `local.properties` is created for you and is never committed.
3. Add the project keys to `local.properties` (ask the team's private chat for the values):
   ```
   SUPABASE_URL=https://<project>.supabase.co
   SUPABASE_ANON_KEY=<the publishable key, starts with sb_publishable_>
   ```
   Use only the publishable key. The secret / service-role key must never go in the app or the repository.
4. Run the `app` configuration on an emulator or device. The app builds without `google-services.json`; that file is only needed for push notifications, is kept private, and goes in `app/`.
5. Before opening a pull request, run `bash gradlew :app:assembleDebug :app:testDebugUnitTest`. It must pass.

## Backend (Supabase)

The backend is a Supabase project (Auth, Postgres with Row Level Security, an Edge Function for push). Read these before you touch data or backend code:

| Read this | When |
|---|---|
| [docs/architecture.md](docs/architecture.md) | How the app, Supabase, the Edge Function and Firebase push fit together |
| [docs/schema.md](docs/schema.md) | Table and column names, enum labels (case matters), functions, who can read or write what, the trip lifecycle |
| [docs/conventions.md](docs/conventions.md) | Naming, secrets, tests and how to write database changes |
| [supabase/README.md](supabase/README.md) | The migrations, the Edge Function, how to apply and test them |

Rules in short: change the database only with a new file in `supabase/migrations/` reviewed by Member 2, send enum labels exactly as written in `docs/schema.md`, and never commit secrets. Trip start, confirm, complete and cancel are database functions; the test for them is `supabase/checks/01_trip_lifecycle_test.sql`.

## Repository structure

```
UMPooling/
  app/                  Android app module (Kotlin, Jetpack Compose)
  supabase/
    migrations/         Database changes in order
    functions/          Edge Functions (push notifications)
    checks/             Read-only queries and tests for the live project
  gradle/               Gradle wrapper and version catalog (libs.versions.toml)
  docs/                 Team documents (architecture, schema, conventions, design, requirements)
  evidence/             Survey exports, UM unit emails, screenshots, test results
  .github/              Pull request template
  AI_Usage_Log.md       AI usage log
  CONTRIBUTING.md       Git workflow and code conventions
  TASKS.md              Requirement checklist with owners
  BUGS.md               Bug list
```

## Where to put things

- Ideas, notes, drafts, meeting notes: **docs/** only. Do not edit code for an idea until it is agreed.
- Code: only on your own feature branch, through a pull request. See [CONTRIBUTING.md](CONTRIBUTING.md).
- Survey data, screenshots, emails and test results: **evidence/** (remove personal data first).
- Any AI help: log it in [AI_Usage_Log.md](AI_Usage_Log.md) the same day.
