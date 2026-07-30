#!/usr/bin/env bash

set -Eeuo pipefail

CONTAINER_NAME="boutique-postgres"

if docker ps \
    --filter "name=^/${CONTAINER_NAME}$" \
    --format '{{.Names}}' |
    grep -qx "${CONTAINER_NAME}"; then

    echo "Stopping PostgreSQL container: ${CONTAINER_NAME}"
    docker stop "${CONTAINER_NAME}" >/dev/null
    echo "PostgreSQL stopped successfully."
else
    echo "PostgreSQL container is not currently running."
fi

echo "The persistent PostgreSQL volume was not deleted."
