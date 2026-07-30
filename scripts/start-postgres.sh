#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env"

IMAGE_NAME="boutique-postgres:local"
CONTAINER_NAME="boutique-postgres"
NETWORK_NAME="boutique-network"
VOLUME_NAME="boutique-postgres-data"

echo
echo "=============================================="
echo "Starting Boutique PostgreSQL"
echo "=============================================="

if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: Docker command is not available."
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker Desktop is not running."
    exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
    echo "ERROR: Missing ${ENV_FILE}"
    echo "Create it from .env.example before continuing."
    exit 1
fi

required_variables=(
    POSTGRES_USER
    POSTGRES_PASSWORD
    POSTGRES_DB
    BOUTIQUE_DATABASES
)

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

for variable_name in "${required_variables[@]}"; do
    if [[ -z "${!variable_name:-}" ]]; then
        echo "ERROR: ${variable_name} is missing from .env"
        exit 1
    fi
done

if ! docker network inspect "${NETWORK_NAME}" >/dev/null 2>&1; then
    echo "Creating Docker network: ${NETWORK_NAME}"
    docker network create "${NETWORK_NAME}" >/dev/null
else
    echo "Docker network already exists: ${NETWORK_NAME}"
fi

if ! docker volume inspect "${VOLUME_NAME}" >/dev/null 2>&1; then
    echo "Creating Docker volume: ${VOLUME_NAME}"
    docker volume create "${VOLUME_NAME}" >/dev/null
else
    echo "Docker volume already exists: ${VOLUME_NAME}"
fi

echo "Building PostgreSQL image: ${IMAGE_NAME}"

docker build \
    --tag "${IMAGE_NAME}" \
    "${PROJECT_ROOT}"

if docker container inspect "${CONTAINER_NAME}" >/dev/null 2>&1; then
    echo "Removing existing container: ${CONTAINER_NAME}"
    docker rm -f "${CONTAINER_NAME}" >/dev/null
fi

echo "Starting PostgreSQL container: ${CONTAINER_NAME}"

docker run -d \
    --name "${CONTAINER_NAME}" \
    --hostname "${CONTAINER_NAME}" \
    --network "${NETWORK_NAME}" \
    --restart unless-stopped \
    --env-file "${ENV_FILE}" \
    -p 5432:5432 \
    -v "${VOLUME_NAME}:/var/lib/postgresql/data" \
    --health-cmd='pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
    --health-interval=5s \
    --health-timeout=5s \
    --health-retries=12 \
    "${IMAGE_NAME}" >/dev/null

echo "Waiting for PostgreSQL health check..."

for attempt in {1..24}; do
    health_status="$(
        docker inspect \
            --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}starting{{end}}' \
            "${CONTAINER_NAME}"
    )"

    echo "Health check ${attempt}/24: ${health_status}"

    if [[ "${health_status}" == "healthy" ]]; then
        break
    fi

    if [[ "${health_status}" == "unhealthy" ]]; then
        echo "ERROR: PostgreSQL became unhealthy."
        docker logs "${CONTAINER_NAME}"
        exit 1
    fi

    sleep 5
done

final_health="$(
    docker inspect \
        --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}unknown{{end}}' \
        "${CONTAINER_NAME}"
)"

if [[ "${final_health}" != "healthy" ]]; then
    echo "ERROR: PostgreSQL did not become healthy."
    docker logs "${CONTAINER_NAME}"
    exit 1
fi

echo "Creating any missing microservice databases..."

MSYS_NO_PATHCONV=1 docker exec "$CONTAINER_NAME" \
  bash /docker-entrypoint-initdb.d/01-create-databases.sh

echo
echo "=============================================="
echo "Boutique PostgreSQL is ready"
echo "=============================================="
echo "Image:      ${IMAGE_NAME}"
echo "Container:  ${CONTAINER_NAME}"
echo "Network:    ${NETWORK_NAME}"
echo "Volume:     ${VOLUME_NAME}"
echo "Port:       5432"
echo "Databases:  ${BOUTIQUE_DATABASES}"

