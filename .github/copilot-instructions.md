# Copilot instructions

## Project context

- TourNTravels is a commercial travel platform for the Indian market.
- The app uses Next.js App Router, TypeScript, Tailwind, shadcn/ui and Framer Motion.
- All money is stored as integer paise.
- Business timezone defaults to Asia/Kolkata and must remain configurable.

## Hard rules

1. Do not rebuild existing functionality unnecessarily.
2. Do not overwrite working files without inspecting them.
3. Do not expose secrets in code or docs.
4. Keep admin paths hidden and out of public docs.
5. Use server-side verification for auth, authorization and payment-related checks.
6. Do not implement future milestone features outside the current milestone.
7. Use database migrations for schema changes.
8. Keep business logic out of React components.
9. Validate all changes with lint, typecheck and tests.
10. Preserve the existing design tokens and travel-journal theme.
