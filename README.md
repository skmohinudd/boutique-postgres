
# Boutique PostgreSQL

Shared local PostgreSQL infrastructure for the Boutique microservices platform.

## Architecture

One PostgreSQL container serves multiple microservices.

Each microservice owns a separate database:

- Product Catalog Service: `product_catalog_db`
- Inventory Service: `inventory_db`

Each microservice manages its own tables and Flyway migrations.

## Important files

- `.env`: real local values and secrets; never committed
- `.env.example`: safe GitHub template
- `Dockerfile`: creates the Boutique PostgreSQL image
- `init/01-create-databases.sh`: creates missing databases
- `scripts/start-postgres.sh`: builds and starts PostgreSQL
- `scripts/stop-postgres.sh`: stops PostgreSQL without deleting data
- `scripts/verify-postgres.sh`: checks health, network, volume and databases

## Start

```bash
./scripts/start-postgres.sh
