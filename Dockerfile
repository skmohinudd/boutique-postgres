FROM postgres:16

LABEL org.opencontainers.image.title="Boutique PostgreSQL"
LABEL org.opencontainers.image.description="Shared local PostgreSQL platform for Boutique microservices"
LABEL org.opencontainers.image.vendor="Boutique Platform"

COPY --chmod=755 init/01-create-databases.sh \
    /docker-entrypoint-initdb.d/01-create-databases.sh

EXPOSE 5432
