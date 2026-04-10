# honcho-secrets

Infisical-managed secrets for the Honcho workload.

## What it creates

A Kubernetes secret `honcho-llm` in namespace `honcho`, synced from Infisical.

## Infisical source

- Project: `bartos-k8s-6-lmc`
- Environment: `prod`
- Path: `/`
- Auth: Universal Auth via `universal-auth-credentials` in namespace `infisical`

## Expected secret key

| Infisical key        | K8s secret  | Env var mapped to               |
|----------------------|-------------|---------------------------------|
| `OPENROUTER_HONCHO`  | `honcho-llm`| `LLM_OPENAI_COMPATIBLE_API_KEY` |

This is an OpenRouter API key used by both the Honcho API and deriver deployments.

## Prerequisites

1. The secret `OPENROUTER_HONCHO` must exist at path `/` in the Infisical
   project `bartos-k8s-6-lmc`, environment `prod`.
2. The `universal-auth-credentials` secret must exist in namespace `infisical`
   (shared cluster-wide Infisical auth — not managed by this app).
3. The Infisical operator must be running on the cluster.

## Sync behavior

- Resync interval: 60s
- Instant updates: disabled
- Creation policy: Owner (the operator owns the K8s secret lifecycle)
