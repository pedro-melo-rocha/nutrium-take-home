# Architecture Decisions

Why this app looks the way it does. One-liner per choice; deeper rationale in commit messages.

## Stack
- **Rails 7.2 API-only + standalone Vite React SPA** — clean separation, modern React DX.

## Testing
- **RSpec + FactoryBot backend; Vitest + RTL frontend** — standard senior stack for Rails + React.

## Email
- **letter_opener in dev (no real SMTP)** — Real send (Resend / SES / SMTP) is one line in `development.rb` if needed.
- **Post-commit enqueue, not in-transaction** — service objects (`Accept`, `Reject`) call `deliver_later` AFTER `ActiveRecord::Base.transaction { }` returns. Enqueueing inside the txn would risk sending mail for work that gets rolled back.
- **ActiveJob retry policy on `ApplicationJob`** — polynomial backoff on transient SMTP / network errors (5 attempts) and AR deadlocks (3 attempts); `discard_on ActiveJob::DeserializationError` so jobs for deleted records don't loop.
- **`canceled_by_overlap` is a distinct mail from `rejected`** — auto-cancel from slot conflict is not a personal "no"; precise copy avoids misleading the guest.
- **No "submitted" confirmation mail** — spec asks only for accept/reject notifications; skipping it cuts inbox noise + scope.

## Data
- **No `Guest` table** — spec is email-only, no auth; `guest_name` + `guest_email` denormalized on each request.
- **`ends_at` snapshot, not derived** — accepted appointments are contracts at booking time; service-duration changes must not shift past bookings.
- **`nutritionist_id` denormalized on `appointment_request`** — required for the GiST exclusion constraint; query convenience is a bonus.
- **Status enum: `pending` / `accepted` / `rejected` / `canceled`** — `canceled` covers both guest-supersede and overlap auto-reject.
- **`timestamptz` for `starts_at` / `ends_at`** — required for `IMMUTABLE` `tstzrange()` in the GiST expression.

## Concurrency & integrity
- **DB-level invariants over app-level** — Postgres partial unique (one pending per email) + GiST exclusion (no overlapping accepted) make races impossible regardless of app logic.
- **Transactional invalidation on new pending submit** — app marks prior pendings `canceled` before insert; unique index is the race-safety net.
- **Service objects own transactions** — `AppointmentRequests::{Create,Accept,Reject}` wrap each state change. Result objects (`success`/`record`/`error_code`) let controllers map to HTTP statuses without rescue forests.

## API
- **Search: blank OR invalid location → Braga** — "invalid" collapses into "yields zero results" (no canonical location list to validate against). The response reports the resolved `location` so the UI can label results ("Showing results for Braga"). Matches the spec literally ("no location or invalid location → consider Braga as default");
- **`PATCH` body uses `decision` (not `action`)** — `params[:action]` is reserved by Rails for the controller-action name.
- **Lookup endpoint exists** — `GET /appointment_requests/lookup?guest_email=` returns the guest's active (pending OR accepted) request so the frontend can show a confirmation dialog before superseding. No auth means anyone with an email can probe; acceptable for take-home scope (spec is no-auth).
- **Only pending is auto-superseded on new submit** — accepted appointments survive. If a guest wants to cancel an accepted appointment to book a new slot, the frontend dialog can explain; no separate "cancel my accepted" endpoint shipped (out of spec scope).
