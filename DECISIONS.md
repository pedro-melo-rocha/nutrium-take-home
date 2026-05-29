# Architecture Decisions

Why this app looks the way it does. One-liner per choice; deeper rationale in commit messages.

## Stack
- **Rails 7.2 API-only + standalone Vite React SPA** — clean separation, modern React DX.

## Testing
- **RSpec + FactoryBot backend; Vitest + RTL frontend** — standard senior stack for Rails + React.

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
- **Search: blank location → Braga; non-blank honored as-typed** — empty results are returned with a `suggestion: { location, results_count }` payload so the frontend can offer a graceful fallback ("No hits in Porto. Show 6 in Braga?"). Suggestion strategy is pluggable — today hardcoded Braga, future could be geo-IP / distance / popularity. Avoids silent surprise where user searched Porto and got Braga back.
- **`PATCH` body uses `decision` (not `action`)** — `params[:action]` is reserved by Rails for the controller-action name.
- **Lookup endpoint exists** — `GET /appointment_requests/lookup?guest_email=` returns the guest's active (pending OR accepted) request so the frontend can show a confirmation dialog before superseding. No auth means anyone with an email can probe; acceptable for take-home scope (spec is no-auth).
- **Only pending is auto-superseded on new submit** — accepted appointments survive. If a guest wants to cancel an accepted appointment to book a new slot, the frontend dialog can explain; no separate "cancel my accepted" endpoint shipped (out of spec scope).
