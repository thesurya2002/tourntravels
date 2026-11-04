# Environment variables

## Public variables

| Name                                   | Purpose                                             | Required | Where to get it                      |
| -------------------------------------- | --------------------------------------------------- | -------- | ------------------------------------ |
| `NEXT_PUBLIC_SITE_URL`                 | Public site base URL used in metadata and redirects | Yes      | App config / deployment env          |
| `NEXT_PUBLIC_BUSINESS_TIMEZONE`        | Default business timezone for public UI and helpers | Yes      | IANA timezone such as `Asia/Kolkata` |
| `NEXT_PUBLIC_SUPABASE_URL`             | Public Supabase project URL                         | Yes      | Supabase project settings            |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | Browser-safe Supabase key                           | Yes      | Supabase project API keys            |

## Server variables

| Name                        | Purpose                                      | Required            | Where to get it              |
| --------------------------- | -------------------------------------------- | ------------------- | ---------------------------- |
| `SUPABASE_SECRET_KEY`       | Admin service key; keep secret-only          | Optional until used | Supabase dashboard           |
| `SUPABASE_JWKS_URL`         | Optional JWKS endpoint for auth verification | Optional            | Supabase Auth settings       |
| `ENABLE_DESIGN_SYSTEM_PAGE` | Enables internal design system gate          | No                  | Local dev only               |
| `RAZORPAY_KEY_ID`           | Future payment key                           | Optional            | Razorpay dashboard           |
| `RAZORPAY_KEY_SECRET`       | Future payment secret                        | Optional            | Razorpay dashboard           |
| `RAZORPAY_WEBHOOK_SECRET`   | Future webhook verification                  | Optional            | Razorpay dashboard           |
| `ADMIN_PATH_SLUG`           | Hidden admin path slug                       | Optional            | Owner specification          |
| `RESEND_API_KEY`            | Future email automation                      | Optional            | Resend dashboard             |
| `EMAIL_FROM`                | Default sender address                       | Optional            | Resend / domain verification |

The project intentionally avoids duplicate non-prefixed `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` variables. The published browser values are the only supported keys for Next.js and the server-only admin client reads the secret key lazily when needed.

This milestone deliberately keeps the values as placeholders and does not commit real secrets. Values are documented here without the actual secret contents.
