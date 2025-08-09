#!/bin/sh
set -e

# Wait for PostgreSQL to be ready
until pg_isready -h db -p 5432 -U postgres; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

# Run database setup
echo "Setting up database..."
mix ecto.create || echo "Database already exists"
mix ecto.migrate

# Start the application
echo "Starting Phoenix server..."
exec mix phx.server