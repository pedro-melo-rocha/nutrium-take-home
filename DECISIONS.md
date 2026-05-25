# Architecture Decisions

Why this app looks the way it does. One-liner per choice; deeper rationale in commit messages.

## Stack
- **Rails 7.2 API-only + standalone Vite React SPA** — clean separation, modern React DX.

## Testing
- **RSpec + FactoryBot backend; Vitest + RTL frontend** — standard senior stack for Rails + React.
