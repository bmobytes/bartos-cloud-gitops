# Firecrawl Deployment Notes

## Endpoint

- **API**: https://firecrawl.lab.bartos.media
- **Namespace**: `firecrawl`

## Required Secrets (create before first sync)

### `firecrawl-secrets` (namespace: firecrawl)

Application-level credentials. All keys are optional depending on features used.

| Key | Purpose |
|-----|---------|
| `BULL_AUTH_KEY` | Auth key for the Bull queue dashboard |
| `TEST_API_KEY` | API key used for authenticating requests |
| `OPENAI_API_KEY` | OpenAI key for LLM-based extraction |

```bash
kubectl -n firecrawl create secret generic firecrawl-secrets \
  --from-literal=BULL_AUTH_KEY='<value>' \
  --from-literal=TEST_API_KEY='<value>' \
  --from-literal=OPENAI_API_KEY='<value>'
```

### `firecrawl-db` (namespace: firecrawl)

NUQ Postgres credentials. Required when `nuqPostgres.enabled=true` (default).

| Key | Purpose |
|-----|---------|
| `POSTGRES_USER` | Postgres superuser name |
| `POSTGRES_PASSWORD` | Postgres superuser password |
| `POSTGRES_DB` | Database name |
| `NUQ_DATABASE_URL` | Full connection URI, e.g. `postgresql://user:pass@firecrawl-nuq-postgres:5432/dbname` |
| `NUQ_DATABASE_URL_LISTEN` | Same URI — used for LISTEN/NOTIFY channel |

```bash
kubectl -n firecrawl create secret generic firecrawl-db \
  --from-literal=POSTGRES_USER='firecrawl' \
  --from-literal=POSTGRES_PASSWORD='<generate>' \
  --from-literal=POSTGRES_DB='firecrawl_nuq' \
  --from-literal=NUQ_DATABASE_URL='postgresql://firecrawl:<password>@firecrawl-nuq-postgres:5432/firecrawl_nuq' \
  --from-literal=NUQ_DATABASE_URL_LISTEN='postgresql://firecrawl:<password>@firecrawl-nuq-postgres:5432/firecrawl_nuq'
```

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
