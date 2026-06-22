#!/bin/sh
set -e

# Wait for PostgreSQL
until pg_isready -h db -p 5432 -U postgres; do
  echo "Waiting for PostgreSQL..."
  sleep 2
done

# Run Postgres migrations (creates DB + oban_jobs table + app tables)
echo "Running Postgres migrations..."
mix ecto.create --quiet || echo "Database already exists"
mix ecto.migrate --quiet

# SQLite migrations run automatically at application startup via Ecto.Migrator
# (see Application.start/2 in application.ex)

echo "Starting Phoenix server..."
exec mix phx.server
