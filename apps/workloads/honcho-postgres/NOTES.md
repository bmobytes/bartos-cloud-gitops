# honcho-postgres

Dedicated PostgreSQL instance for Honcho with pgvector support.

## Image

`pgvector/pgvector:pg16`

## Storage

- PVC: `honcho-postgres-data` — 10Gi on Longhorn (ReadWriteOnce)
- Data path: `/var/lib/postgresql/data/pgdata`

## Required live secret

A Kubernetes secret named `honcho-db` must exist in namespace `honcho` **before** this app syncs.
This secret is **not managed by GitOps** — create it manually on the cluster.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: honcho-db
  namespace: honcho
type: Opaque
stringData:
  POSTGRES_USER: honcho
  POSTGRES_PASSWORD: <generate-a-strong-password>
  POSTGRES_DB: honcho
  DB_CONNECTION_URI: "postgresql+psycopg://honcho:<password>@honcho-postgres:5432/honcho"
```

The `DB_CONNECTION_URI` must use the `postgresql+psycopg` scheme (required by Honcho's SQLAlchemy async driver).
The hostname `honcho-postgres` must match the Service name in this app.

## Notes

- Strategy is `Recreate` to avoid two pods mounting the same PVC.
- The pgvector extension is available in the image; Honcho's migration scripts create it automatically.
