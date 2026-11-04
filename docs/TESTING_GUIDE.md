# Testing guide

## Local database

```bash
npm install
npx supabase start
npm run db:reset
npm run db:lint
npm run db:test
```

## Vitest

```bash
npm run test
npm run test:watch
```

## Notes

- The database tests validate RLS behavior, trigger behavior and storage constraints.
- The env tests validate required public variables and client setup contracts.
- Keep Docker available locally because Supabase uses a local Postgres stack.
