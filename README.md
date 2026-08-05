# boutique-postgres

Provides local PostgreSQL initialization and verification utilities.

## Overview

- **Type:** Platform repository
- **Stack:** Docker

## Flow

```text
Client / service → Controller → Business logic → Database / events / downstream services
```

## Configuration

```text
BOUTIQUE_DATABASES
CONTAINER_NAME
ENV_FILE
IMAGE_NAME
NETWORK_NAME
POSTGRES_DB
POSTGRES_USER
PROJECT_ROOT
```

## Docker

```bash
docker build -t boutique-postgres:local .
```

## CI/CD

This repository is built and deployed independently through its own GitHub Actions workflow.
