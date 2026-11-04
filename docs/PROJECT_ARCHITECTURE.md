# Project architecture

## Core conventions

- Server Components are default; `use client` is only used for interactive features.
- Server actions handle UI mutations; route handlers are reserved for JSON exports and webhooks.
- Business logic stays in server-side services rather than components.
- Supabase is the source of truth for persistence, policies and storage.

## Runtime layers

```text
src/app
  ├── (public) public pages and layout
  ├── (internal) internal debug pages
  ├── api/health route
  └── globals.css
src/components
  ├── ui shared shadcn-style primitives
  ├── layout public shell and nav
  ├── shared reusable domain components
  └── motion motion wrappers
src/lib
  ├── env typed environment validation
  ├── supabase browser/server/admin clients
  ├── constants site settings and navigation
  ├── money INR helpers
  ├── datetime timezone helpers
  └── utils class merging
supabase
  ├── migrations database schema and RLS
  ├── tests pgTAP coverage
  └── seed.sql local sample data
```

## Supabase client usage

- `src/lib/supabase/client.ts` – browser/client usage where cookies are not needed.
- `src/lib/supabase/server.ts` – server component / action / route usage under user session RLS.
- `src/lib/supabase/admin.ts` – secret-key service client for internal system tasks only.

## Future milestone guidance

- `features/*` – domain-focused feature modules and services
- `server/*` – backend service layering and orchestration
- `supabase/migrations` – all schema changes
- `supabase/seed.sql` – local sample data only
