# Deployment guide

## Local development

1. Install Docker and start the local Supabase stack with `npx supabase start`.
2. Copy `.env.example` to `.env.local` and fill the required values.
3. Run `npm run db:reset` to build the schema from zero.
4. Run `npm run dev` to serve the app.

## Production guidance

- Create separate Supabase projects for development and production.
- Link the project manually only after owner approval.
- Push migrations with `supabase db push` only when the project is intentionally linked.
- Keep a separate environment file for production values.

## First super admin

The owner must create the first auth user in the Supabase dashboard or via Auth API, then update the `public.profiles` record to set the role to `super_admin` and status `active`.

## Function region note

The default region should be selected close to the Supabase data region and owner-approved in the Vercel settings. This is a configuration decision that should be made before production launch.
