# TourNTravels

TourNTravels is a travel, tour-package and car-booking platform for the Indian market.

## Milestone status

- Milestone 01: complete foundation and design system
- Milestone 02: database, security and storage foundation in progress

## Local setup

```bash
npm install
cp .env.example .env.local
npm run dev
```

## Scripts

- `npm run dev`
- `npm run build`
- `npm run lint`
- `npm run typecheck`
- `npm run test`
- `npm run db:start`
- `npm run db:reset`
- `npm run db:lint`
- `npm run db:test`

## Project structure

- `src/app` – App Router pages and route handlers
- `src/lib` – shared utilities, env validation, and Supabase factories
- `src/components` – reusable UI primitives and layout components
- `supabase/migrations` – schema and policy migrations
- `supabase/tests` – pgTAP tests
- `docs` – project and operational documentation
