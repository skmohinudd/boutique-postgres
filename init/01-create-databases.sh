#!/usr/bin/env bash

set -Eeuo pipefail

echo "=============================================="
echo "Boutique database provisioning started"
echo "=============================================="

if [[ -z "${POSTGRES_USER:-}" ]]; then
    echo "ERROR: POSTGRES_USER is missing."
    exit 1
fi

if [[ -z "${POSTGRES_DB:-}" ]]; then
    echo "ERROR: POSTGRES_DB is missing."
    exit 1
fi

if [[ -z "${BOUTIQUE_DATABASES:-}" ]]; then
    echo "ERROR: BOUTIQUE_DATABASES is missing."
    exit 1
fi

IFS=',' read -ra DATABASES <<< "${BOUTIQUE_DATABASES}"

for raw_database in "${DATABASES[@]}"; do
    database_name="$(echo "${raw_database}" | xargs)"

    if [[ -z "${database_name}" ]]; then
        continue
    fi

    if [[ ! "${database_name}" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]; then
        echo "ERROR: Invalid database name: ${database_name}"
        exit 1
    fi

    database_exists="$(
        psql \
            --username="${POSTGRES_USER}" \
            --dbname="${POSTGRES_DB}" \
            --tuples-only \
            --no-align \
            --command="SELECT 1 FROM pg_database WHERE datname='${database_name}';"
    )"

    if [[ "${database_exists}" == "1" ]]; then
        echo "Database already exists: ${database_name}"
    else
        echo "Creating database: ${database_name}"

        createdb \
            --username="${POSTGRES_USER}" \
            --owner="${POSTGRES_USER}" \
            "${database_name}"

        echo "Database created: ${database_name}"
    fi
done

echo "=============================================="
echo "Boutique database provisioning completed"
echo "=============================================="
