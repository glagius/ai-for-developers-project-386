# AGENTS.md

## Project

Cal Clone — Cal.com MVP. Online appointment scheduling service built with Elixir/Ash.

See `README.md` for project description and `PLAN.md` for implementation phases (0–5).

**Single calendar owner (no auth), guests book without registration.**

## Stack

- Elixir / AshPhoenix (Phoenix + LiveView)
- Ash + AshPostgres (domain resources)
- AshWebComponents (UI components)
- AshJsonApi (automatic REST endpoints from Ash resources)
- TypeSpec (API contract, contract-first approach)
- PostgreSQL (Docker)
- Timex (timezones)

## Contract-First Approach

TypeSpec (`api/typespec/`) is the API contract source of truth. Compiled to OpenAPI 3.0 → Swagger UI at `/api/docs`.

Ash resources (`lib/scheduling/`) implement the contract. `ash_json_api` generates REST endpoints automatically — **zero controllers** for CRUD.

Public booking UI (`/events/*`) and admin (`/admin/*`) use Phoenix LiveView directly.

```
TypeSpec spec (api/typespec/) → OpenAPI 3.0 → /api/docs (Swagger)

Ash Resource + ash_json_api → /api/* (REST endpoints)
Ash Resource + ash_phoenix  → LiveView UI (admin + guest)
```

## Domain Architecture

- Two resources: `EventType` (id, name, description, duration_minutes) and `Booking` (event_type_id, start_at UTC, guest_name, guest_email, guest_message)
- **No User resource, no auth** — single predefined calendar owner
- Booking `start_at` is unique across ALL event types (one booking per time slot)
- `end_at` is calculated from `start_at + duration_minutes`
- Booking window: 14 days from today
- Slot calculation is a custom Ash action (`calculate_slots`) on `Booking` with `run` callback

## Key Gotchas

- Booking uniqueness: unique constraint on `start_at` alone (not event_type_id + start_at) — prevents double booking across event types
- Slot calculation must filter: existing bookings, 14-day window, alignment to duration_minutes
- TypeSpec and Ash resources are **mirrored, not generated** — keep them in sync manually

## TypeSpec Workflow

```bash
make typespec                              # compile TypeSpec → OpenAPI
```

Compiled OpenAPI served by Phoenix at `/api/openapi.yaml`, Swagger UI at `/api/docs`.

## Makefile Targets

```bash
make install    # mix deps.get + npm install (TypeSpec)
make test       # mix test
make start.dev  # docker compose postgres + mix phx.server
make start.prod # docker compose up -d --build
make typespec   # compile TypeSpec → OpenAPI
```

## Phases (in order, see PLAN.md for details)

0. Infra (Phoenix + Ash init, Docker, TypeSpec, Makefile, devcontainer)
1. Event Types (TypeSpec → Ash + ash_json_api → Admin UI)
2. Booking (TypeSpec → Ash + ash_json_api + calculate_slots)
3. Guest Pages (`/events/*` — list, calendar, book)
4. Admin Dashboard (`/admin/bookings`)
5. Tests (unit, integration, contract compliance)
