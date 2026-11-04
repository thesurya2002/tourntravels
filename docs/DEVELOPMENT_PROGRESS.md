# Development progress

## Milestone 02 progress

- Supabase project configuration initialized.
- Typed environment and client factories created.
- Core schema and RLS migration foundation created.
- Local seed and database tests scaffolded.

## Installed versions

- Next.js: 15.3.3
- Supabase CLI: 2.49.4
- @supabase/ssr: 0.8.0
- @supabase/supabase-js: 2.56.0
- Zod: 4.6.7

## Decisions

- Public env includes the required Supabase browser keys.
- The secret key is intentionally kept out of client code and imported only from the admin service.
- Local-only sample data is documented as not for production.

## Known points

- Full cloud linking and migration push remain deferred to owner-approved infra steps.
- The admin path remains intentionally hidden and is not linked in public docs.
