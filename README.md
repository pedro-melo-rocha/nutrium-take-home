# Nutri App — Appointment Requests

Senior Full-Stack take-home: patients search nutritionists by name / service / location and request appointments; nutritionists accept or reject.

## Stack

- **Backend**: Ruby on Rails 7.2 (API-only) + PostgreSQL
- **Frontend**: React 18 + TypeScript + Vite
- **Tests**: RSpec (backend), Vitest + React Testing Library (frontend)
- **Email**: ActionMailer (letter_opener in dev)

## Layout

```
nutrium-take-home/
  api/   # Rails 7.2 API
  web/   # Vite React SPA
```

## Prerequisites

- Ruby 3.3
- Node 20+
- PostgreSQL 14+ running locally

## Setup

```bash
# Backend
cd api
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server          # http://localhost:3000

# Frontend (new terminal)
cd web
npm install
npm run dev               # http://localhost:5173
```

## Running tests

```bash
# Backend
cd api && bundle exec rspec

# Frontend
cd web && npm test
```

## API endpoints

All endpoints under `/api/v1/`. JSON in, JSON out. No auth.

### Search nutritionists

```bash
# Default location (blank → "Braga")
curl 'http://localhost:3000/api/v1/nutritionists'

# Filter by location + free-text query (name OR service name)
curl 'http://localhost:3000/api/v1/nutritionists?location=Porto&q=sport'

# Paginate (page 1-based; per_page default 10, capped at 50)
curl 'http://localhost:3000/api/v1/nutritionists?location=Braga&page=2&per_page=5'
```

A blank or invalid location falls back to `Braga` ("invalid" = yields zero
results). The response reports the resolved `location`, so the frontend can
label results ("Showing results for Braga"), plus a `pagination` block:

```json
{ "page": 1, "per_page": 10, "total_count": 6, "total_pages": 1 }
```

### Create an appointment request

```bash
curl -X POST 'http://localhost:3000/api/v1/appointment_requests' \
  -H 'Content-Type: application/json' \
  -d '{
    "appointment_request": {
      "service_id": 1,
      "guest_name": "Sara Pinto",
      "guest_email": "sara@example.com",
      "starts_at": "2026-06-02T10:00:00Z"
    }
  }'
```

Returns `201 Created` with the persisted record. Any prior `pending` request
from the same email is auto-canceled (one-pending-per-guest invariant; the
partial unique index is the race guard).

Errors:
- `422 validation_failed` — model validation error
- `409 concurrent_submission` — race lost on the partial unique index

### Lookup active request (frontend pre-check)

```bash
curl 'http://localhost:3000/api/v1/appointment_requests/lookup?guest_email=sara@example.com'
```

Returns `{ active: <request> | null }`. Lets the SPA show a confirmation
dialog before superseding an existing pending/accepted request.

### Accept / reject (nutritionist queue)

```bash
curl -X PATCH 'http://localhost:3000/api/v1/appointment_requests/42' \
  -H 'Content-Type: application/json' \
  -d '{ "decision": "accept" }'

curl -X PATCH 'http://localhost:3000/api/v1/appointment_requests/42' \
  -H 'Content-Type: application/json' \
  -d '{ "decision": "reject" }'
```

`decision` (not `action` — Rails reserves `params[:action]`).

On accept, all other pending requests for the same nutritionist whose time
range overlaps are auto-canceled. The Postgres GiST exclusion constraint
`no_overlapping_accepted` is the race guard against double-booking.

Errors:
- `409 overlap_conflict` — slot already taken by another accepted request
- `409 invalid_state` — request is not in `pending`
- `422 validation_failed`

Mails enqueue *after* the transaction commits (never inside it). In dev,
`letter_opener` pops the email in a browser tab.

### Nutritionist queue

```bash
curl 'http://localhost:3000/api/v1/nutritionists/1/appointment_requests?status=pending'
```

`status` ∈ `pending | accepted | rejected | canceled`. Defaults to `pending`.

## Notes / Decisions

- API-only Rails + standalone Vite SPA chosen over Rails monolith for cleaner separation and modern frontend DX.
- Search location falls back to `Braga` when blank or invalid (zero-hit).
- Guest identity is email-only.
- Nutritionist views are unauthenticated.

See `DECISIONS.md` for the full architecture log.
