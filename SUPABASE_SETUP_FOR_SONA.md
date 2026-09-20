# SONA DAILY LIFE HUB — Supabase setup

## Important
Do NOT put the PostgreSQL connection string or database password into `index.html`.
The browser should only use the Supabase project URL and publishable key.

The error:

`Could not find the table 'public.profiles' in the schema cache`

means the `public.profiles` table has not been created in this Supabase project (or the schema has not refreshed yet).

## Easiest fix
1. Open Supabase Dashboard → SQL Editor.
2. Create a new SQL query.
3. Paste the contents of `SONA_SUPABASE_SCHEMA.sql`.
4. Click Run.
5. Wait a few seconds and refresh the website.
6. Try logging in again.

## CLI option
From the folder containing your website:

    supabase login
    supabase init
    supabase link --project-ref auwcmybncaaavpwdgkgh
    supabase db push

For `supabase login`, use the Supabase CLI access-token flow. The PostgreSQL connection string is NOT the login token.

The included migration is:
`supabase/migrations/20260920000000_sona_daily_life_hub.sql`

## PostgreSQL connection string
The connection string is for database/SQL tools such as psql. It is NOT frontend code and should never contain a password that is shipped to Netlify.

## Frontend
The fixed HTML still uses:
- Supabase project URL
- Supabase publishable key

It never uses a database password or service_role key.
