# Backend API Contract

This is the contract the Flutter client (`lib/data/repositories/`) expects once a
real backend exists. Nothing here is implemented yet — every `Http*Repository`
class throws `UnimplementedError` naming the endpoint it's waiting on. The app
currently runs entirely on `Mock*Repository` implementations backed by
`lib/mockData/*`; flipping `--dart-define=DATA_MODE=http` (plus
`--dart-define=API_BASE_URL=...`) is what would switch it over once these
endpoints exist (see `lib/data/data_config.dart`, `lib/data/repositories.dart`).

All request/response JSON shapes below mirror the `toJson()`/`fromJson()`
methods added to the corresponding model in `lib/models/`.

## Auth (`lib/data/repositories/auth_repository.dart`)

| Endpoint | Method | Notes |
|---|---|---|
| `/auth/otp/request` | POST | body: `{ "identifier": string }` (phone or email). No response body needed. |
| `/auth/otp/verify` | POST | body: `{ "identifier": string, "code": string, "returning": bool }` → `User` JSON on success. Errors should distinguish an expired code from a wrong code (client currently expects `otp_expired` / `otp_invalid`). |
| `/auth/google` | POST | Real Google OAuth token exchange → `User` JSON. |
| `/users/me` | PATCH | Partial `User` JSON → updated `User` JSON. |
| `/users/me` | GET | Token-based profile fetch, used for session recovery. Replaces the mock's identifier-based account lookup (`AuthRepository.findAccountByIdentifier`) — a real backend should resolve this from the auth token alone, not require the client to pass an identifier. |

`User` JSON shape: see `lib/models/user.dart:202-268` (`toJson`/`fromJson`).

## Opportunities (`lib/data/repositories/opportunity_repository.dart`)

| Endpoint | Method | Notes |
|---|---|---|
| `/opportunities` | GET | Query params: `type`, `workMode`, `query`, `categories` (repeated), `location`, `employmentType`, `locations` (repeated) → `Opportunity[]`. |
| `/opportunities/{id}` | GET | → single `Opportunity`. The client currently calls this synchronously and inline, per-row, across several list/card widgets — until a local cache is added on the client side, a real implementation should stay cheap/CDN-cacheable, since it may be called often in a short window. |
| `/opportunities/search-terms` | GET | → `string[]`, used for search-box autocomplete. |

`Opportunity` JSON shape: `lib/models/opportunity.dart`.

## Applications (`lib/data/repositories/application_repository.dart`)

| Endpoint | Method | Notes |
|---|---|---|
| `/applications` | GET | → `Application[]` for the signed-in user, most-recent-first with Offers surfaced first (current client-side sort in `mock_applications.dart:listApplications` — fine to keep client-side, or move server-side). |
| `/applications` | POST | body: `{ "opportunityId": string, "note": string?, "screeningAnswers": {string: string}? }` → `Application`. Must be idempotent per (user, opportunity) — a repeat call for an opportunity the user already has a live application for should return the existing application, not create a duplicate (mirrors `mock_applications.dart:createApplication`'s `isNew: false` behavior). |
| `/applications/{id}` | DELETE | Soft delete (sets a `deletedAt`, recoverable) — not a hard delete. |
| `/applications/{id}/restore` | POST | Un-deletes. |
| `/applications/deleted` | GET | → `Application[]` currently in the trash for this user. |
| `/applications/{id}/permanent` | DELETE | Hard delete, irreversible. |
| `/applications/{id}` | GET | → single `Application`, used inline/synchronously in card widgets — same caching note as `/opportunities/{id}`. |

`Application` JSON shape (+ nested `ApplicationOpportunitySummary`/`ApplicationEvent`/`ApplicationMessage`/`InterviewDetails`): `lib/models/application.dart`.

## Notifications (`lib/data/repositories/notification_repository.dart`)

| Endpoint | Method | Notes |
|---|---|---|
| `/notifications` | GET | Query param: `isSchool` (bool) — segments the notification set the way `mock_notifications.dart`'s two static lists do today. → `NotificationItem[]`. |

`NotificationItem` JSON shape: `lib/models/notification_item.dart`.

## Courses (`lib/data/repositories/course_repository.dart`) — not yet rewired into any screen

| Endpoint | Method | Notes |
|---|---|---|
| `/courses` | GET | → `Course[]`. |
| `/courses/{id}` | GET | → single `Course`. |

`Course`/`SyllabusModule` JSON shape: `lib/models/course.dart`. The richer filter/search
helpers in `mock_courses.dart` (`filterCoursesAdvanced`, `courseSyllabus`) aren't
part of the interface yet — courses screens still read `mock_courses.dart`
directly; this is flagged as follow-up work, not an oversight.

## Bookings (`lib/data/repositories/booking_repository.dart`) — not yet rewired into any screen

| Endpoint | Method | Notes |
|---|---|---|
| `/bookings` | GET | → `Booking[]` for the signed-in user. |
| `/bookings` | POST | body: kind/mode/sessionType/date/time/name/phone/email → `Booking`, or a conflict response if the slot's taken (mirrors `mock_bookings.dart:createBooking`'s null-on-conflict). |
| `/bookings/{id}` | PATCH | Reschedule — same conflict behavior as create. |
| `/bookings/{id}` | DELETE | Cancel. |
| `/bookings/{id}/restore` | POST | Undo a cancel. |
| `/bookings/slots` | GET | Query: `date`, `time`, `excludeBookingId?` → `{ "taken": bool }`. |

`Booking` JSON shape: `lib/models/booking.dart`.

## Uploads (`lib/data/repositories/upload_repository.dart`) — not yet rewired into any screen

| Endpoint | Method | Notes |
|---|---|---|
| `/uploads/resume` | POST (multipart) | Resume PDF bytes → `{ "url": string }`. `resume_screen.dart` currently only holds bytes in memory/locally; wiring this up is follow-up work. |
| `/uploads/photo` | POST (multipart) | Profile photo bytes → `{ "url": string }`. Same status — `profile_edit_screen.dart`. |

## Not covered here

- **Career DNA** (`lib/mockData/career_dna/`) and **skill stories**
  (`lib/mockData/mock_skill_stories.dart`) are app content, not user data —
  no repository/endpoint was scoped for these this pass.
- **`OpportunityMatch`** (`lib/models/opportunity_match.dart`) is a Dart
  `extension` on `Opportunity` (match-score/deadline-label computation), not
  a data class — there's nothing to serialize; it stays a client-side
  computation over `Opportunity` + `User`.
- **Session/token expiry** — the client has no concept of a token expiring
  or refreshing today (see `lib/state/app_state.dart`). A real backend
  issuing real tokens should define a refresh flow; the client-side work to
  consume it is out of scope until then.
