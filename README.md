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

## Notes / Decisions

- API-only Rails + standalone Vite SPA chosen over Rails monolith for cleaner separation and modern frontend DX.
- Default search location is `Braga` when none provided (per spec).
- Guest identity is email-only (no auth).
- Nutritionist views are unauthenticated per spec.
