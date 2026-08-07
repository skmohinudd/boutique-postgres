#!/usr/bin/env bash
set -Eeuo pipefail
: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${POSTGRES_DB:?POSTGRES_DB is required}"
: "${BOUTIQUE_DATABASES:?BOUTIQUE_DATABASES is required}"
IFS=',' read -ra databases <<< "$BOUTIQUE_DATABASES"
for raw in "${databases[@]}"; do
  db="$(printf '%s' "$raw" | xargs)"
  [[ -n "$db" ]] || continue
  [[ "$db" =~ ^[A-Za-z][A-Za-z0-9_]*$ ]] || { echo "Invalid database name: $db" >&2; exit 1; }
  exists="$(psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -tAc "SELECT 1 FROM pg_database WHERE datname='$db'")"
  if [[ "$exists" == "1" ]]; then
    echo "Database already exists: $db"
  else
    createdb -U "$POSTGRES_USER" -O "$POSTGRES_USER" "$db"
    echo "Database created: $db"
  fi
done
