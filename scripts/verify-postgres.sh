#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env"

CONTAINER_NAME="boutique-postgres"
NETWORK_NAME="boutique-network"
VOLUME_NAME="boutique-postgres-data"

echo
echo "=============================================="
echo "Verifying Boutique PostgreSQL"
echo "=============================================="

if [[ ! -f "${ENV_FILE}" ]]; then
    echo "ERROR: Missing ${ENV_FILE}"
    exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

if ! docker container inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
    echo "ERROR: Container does not exist: ${CONTAINER_NAME}"
    exit 1
fi

if [[ "$(
    docker inspect \
        --format='{{.State.Running}}' \
        "${CONTAINER_NAME}"
)" != "true" ]]; then
    echo "ERROR: Container is not running: ${CONTAINER_NAME}"
    exit 1
fi

health_status="$(
    docker inspect \
        --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' \
        "${CONTAINER_NAME}"
)"

echo "Container health: ${health_status}"

if [[ "${health_status}" != "healthy" ]]; then
    echo "ERROR: PostgreSQL container is not healthy."
    exit 1
fi

if ! docker network inspect "${NETWORK_NAME}" >/dev/null 2>&1; then
    echo "ERROR: Missing Docker network: ${NETWORK_NAME}"
    exit 1
fi

if ! docker volume inspect "${VOLUME_NAME}" >/dev/null 2>&1; then
    echo "ERROR: Missing Docker volume: ${VOLUME_NAME}"
    exit 1
fi

echo
echo "Available PostgreSQL databases:"

docker exec "${CONTAINER_NAME}" \
    psql \
    --username="${POSTGRES_USER}" \
    --dbname="${POSTGRES_DB}" \
    --command="SELECT datname FROM pg_database WHERE datistemplate = false ORDER BY datname;"

IFS=',' read -ra DATABASES <<< "${BOUTIQUE_DATABASES}"

echo
echo "Checking required microservice databases:"

for raw_database in "${DATABASES[@]}"; do
    database_name="$(echo "${raw_database}" | xargs)"

    database_exists="$(
        docker exec "${CONTAINER_NAME}" \
            psql \
            --username="${POSTGRES_USER}" \
            --dbname="${POSTGRES_DB}" \
            --tuples-only \
            --no-align \
            --command="SELECT 1 FROM pg_database WHERE datname='${database_name}';"
    )"

    if [[ "${database_exists}" != "1" ]]; then
        echo "ERROR: Database is missing: ${database_name}"
        exit 1
    fi

    echo "Verified: ${database_name}"
done

echo
echo "Network verified: ${NETWORK_NAME}"
echo "Volume verified: ${VOLUME_NAME}"
echo "PostgreSQL verification completed successfully."

