BEGIN;

SELECT plan(5);

SELECT has_table('public', 'profiles', 'profiles table exists');
SELECT has_table('public', 'bookings', 'bookings table exists');
SELECT has_table('public', 'content_faqs', 'catalogue table exists');
SELECT has_table('public', 'settings', 'settings table exists');
SELECT ok(
  (
    SELECT count(*) > 0 AND bool_and(c.relrowsecurity)
    FROM pg_class AS c
    JOIN pg_namespace AS n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind IN ('r', 'p')
  ),
  'row level security is enabled on every public table'
);

SELECT * FROM finish();
ROLLBACK;
