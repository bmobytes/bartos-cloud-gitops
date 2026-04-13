# Firecrawl Deployment Notes

## Endpoint

- **API**: https://firecrawl.lab.bartos.media
- **Namespace**: `firecrawl`

## Secrets (managed by Infisical Operator)

Both secrets below are synced automatically by the Infisical operator via
`InfisicalSecret` resources in `apps/secrets/firecrawl/`. No manual
`kubectl create secret` steps are required.

### `firecrawl-secrets` (namespace: firecrawl)

Application-level credentials. All keys are optional depending on features used.
Synced from Infisical path `/firecrawl`.

| Key | Purpose |
|-----|---------|
| `BULL_AUTH_KEY` | Auth key for the Bull queue dashboard |
| `TEST_API_KEY` | API key used for authenticating requests |
| `OPENAI_API_KEY` | OpenAI key for LLM-based extraction |

### `firecrawl-db` (namespace: firecrawl)

NUQ Postgres credentials. Required when `nuqPostgres.enabled=true` (default).
Synced from Infisical path `/firecrawl/db`.

| Key | Purpose |
|-----|---------|
| `POSTGRES_USER` | Postgres superuser name |
| `POSTGRES_PASSWORD` | Postgres superuser password |
| `POSTGRES_DB` | Database name |
| `NUQ_DATABASE_URL` | Full connection URI, e.g. `postgresql://user:pass@firecrawl-nuq-postgres:5432/dbname` |
| `NUQ_DATABASE_URL_LISTEN` | Same URI — used for LISTEN/NOTIFY channel |

## NUQ bootstrap behavior

- The upstream `ghcr.io/firecrawl/nuq-postgres` image ships `/docker-entrypoint-initdb.d/010-nuq.sql`, but that only runs on the very first `initdb` for an empty `PGDATA` directory.
- This chart starts Postgres with `cron.database_name=${POSTGRES_DB}` so `pg_cron` can be created in the same database that Firecrawl uses.
- This chart also installs a PostSync Job named `firecrawl-nuq-bootstrap` that waits for Postgres readiness and then applies an idempotent copy of the NUQ bootstrap SQL.
- The Job is safe to rerun on later Argo CD syncs and repairs clusters where the PVC already contained a database but not the NUQ schema after a partial/failed first init.

## Internal Services (ClusterIP only)

| Service | Port |
|---------|------|
| `firecrawl-redis` | 6379 |
| `firecrawl-rabbitmq` | 5672 (AMQP), 15672 (management) |
| `firecrawl-nuq-postgres` | 5432 |
| `firecrawl-playwright` | 3000 |

## Optional Components

Set in `values.yaml` to enable:

- `extractWorker.enabled: true` — LLM-based data extraction worker
- `nuqWorker.enabled: true` — NUQ queue worker (requires NUQ Postgres)

## Storage

- NUQ Postgres uses a `longhorn` PVC (`10Gi` default)
- Redis is ephemeral (no PVC) — acceptable for queue/cache data
- RabbitMQ is ephemeral — queues are transient by design
