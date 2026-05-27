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
