# honcho

Honcho API and deriver worker — user context management for LLM applications.

- Upstream: https://github.com/plastic-labs/honcho
- Image: `ghcr.io/plastic-labs/honcho:latest`
- Ingress: `https://honcho.lab.bartos.media` (internal only, lab-ca TLS)
- FastAPI docs UI: `https://honcho.lab.bartos.media/docs`
- Auth: disabled (`AUTH_USE_AUTH=false`)

## Deployments

### honcho-api

- Runs the FastAPI server (default container CMD)
- Init container runs DB migrations via `python scripts/provision_db.py`
- Port: 8000
- Health: `GET /health`
- `DERIVER_ENABLED=false` — the API process does not run the deriver loop
- Shared config loaded from ConfigMap `honcho-config`

### honcho-deriver

- Background worker: `python -m src.deriver`
- Polls the DB queue for work items (representations, summaries, and dream tasks)
- No exposed port
- `DERIVER_ENABLED=true`
- Shared config loaded from ConfigMap `honcho-config`

## LLM configuration

All non-secret LLM settings live in ConfigMap `honcho-config` and are shared by both deployments.

- Provider: OpenRouter-compatible (`*_PROVIDER=custom`)
- Base URL: `https://openrouter.ai/api/v1`
- Default model: `google/gemini-2.5-flash`
- Embeddings provider: `openrouter`
- API key: sourced from K8s secret `honcho-llm`, key `OPENROUTER_HONCHO`, mapped to env var `LLM_OPENAI_COMPATIBLE_API_KEY`
- Dialectic levels `minimal`, `low`, `medium`, `high`, and `max` all use the same initial model for simplicity
- Dream deduction and induction models are also set to the same initial model

## Required live secrets

### honcho-db (manual — not in GitOps)

See `apps/workloads/honcho-postgres/NOTES.md` for creation instructions.
Used by both the API and deriver for `DB_CONNECTION_URI`.

### honcho-llm (Infisical-managed)

Created by the `honcho-secrets` Argo app via InfisicalSecret.
See `apps/secrets/honcho/NOTES.md` for details.

## Cache / Redis

Not deployed. `CACHE_ENABLED=false` on both deployments via ConfigMap.
Add Redis later if caching is needed for performance.
