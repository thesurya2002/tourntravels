# Security checklist

## RLS status

- RLS is enabled on the `public` tables created in this milestone.
- Public/read allowed tables are filtered to published or active rows.
- Customer access is restricted to their own records.
- Staff and admin roles are evaluated from `public.profiles` only.
- System-only records and payment tables are not writable by clients.

## Key handling

- `SUPABASE_SECRET_KEY` is server-only and must never be exposed to the browser.
- A Supabase secret key that was previously shared in plain text must be rotated before any cloud project is used.
- Local development uses the values printed by `supabase start` in a private `.env.local` file.

## Deployment note

- Production environments require a backup strategy and owner review of retention windows.
- The admin slug is never exposed in public links or the robots file.
- Vercel Hobby plans are non-commercial and should not be used for production-grade hosted workloads without sign-off.

## CSP note

- A strict Content-Security-Policy is intentionally deferred until the Razorpay integration milestone because the scripts and inline behavior require additional review.
