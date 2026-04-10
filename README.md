# bartos-cloud-gitops

GitOps repo for the `bartos-cloud` Kubernetes cluster.

## Layout

- `bootstrap/` — one-time Argo CD bootstrap manifests
- `clusters/bartos-cloud/` — app-of-apps definitions for this cluster
- `apps/infrastructure/` — infrastructure apps managed by Argo CD
- `apps/workloads/` — workload apps managed by Argo CD

## Current apps

- `cert-manager` — TLS certificate controller (Helm)
- `cert-manager-issuers` — internal CA bootstrap (`lab-ca` ClusterIssuer)
- `external-dns`
- `hermes-rbac`
- `netdata`
- `honcho-postgres` — dedicated Postgres with pgvector for Honcho
- `honcho-secrets` — Infisical-managed LLM API key for Honcho
- `honcho` — Honcho API + deriver worker (user context management for LLMs)

## Bootstrap

This repo uses a simple app-of-apps pattern:

1. Argo CD needs the repo credential configured for `git@github.com:bmobytes/bartos-cloud-gitops.git`
2. Bootstrap the root application:

```bash
kubectl apply -f bootstrap/root-application.yaml -n argocd
```

3. Argo CD will create child applications from `clusters/bartos-cloud/`
4. Child applications sync the app manifests from `apps/`

## Validation

Render manifests locally with:

```bash
kubectl kustomize clusters/bartos-cloud
kubectl kustomize apps/infrastructure/external-dns
kubectl kustomize apps/infrastructure/hermes-rbac
kubectl kustomize apps/infrastructure/cert-manager-issuers
kubectl kustomize apps/workloads/honcho-postgres
kubectl kustomize apps/secrets/honcho
kubectl kustomize apps/workloads/honcho

# cert-manager uses an upstream Helm chart with values stored in this repo.
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm template cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set installCRDs=true \
  -f apps/infrastructure/cert-manager/values.yaml

# Netdata uses an upstream Helm chart with values stored in this repo.
helm repo add netdata https://netdata.github.io/helmchart
helm repo update
helm template netdata netdata/netdata \
  --version 3.7.163 \
  -f apps/monitoring/netdata/values.yaml
```

## Conventions

### Supported app patterns

- `templates/plain-app/` — default pattern for plain YAML + Kustomize apps
- `templates/helm-app/` — upstream Helm chart apps with local values stored in this repo

### TLS defaults

- default internal hostname pattern: `<app>.lab.bartos.media`
- default ingress class: `nginx`
- default cluster issuer: `lab-ca`
- default TLS secret name: `<app>-tls`

### App bootstrap checklist

1. choose `plain-app` or `helm-app`
2. create the app path under `apps/<group>/<app>/`
3. fill in `NOTES.md`
4. document required secret names and keys
5. create `clusters/bartos-cloud/<app>-application.yaml`
6. add that child app to `clusters/bartos-cloud/kustomization.yaml`
7. validate locally
8. push and verify Argo sync

## Notes

- This repo stays plain YAML + Kustomize by default.
- Durable cluster changes should land here first, then sync through Argo CD.
- Emergency direct kubectl changes should be reflected back into GitOps immediately after.
- See `docs/plans/2026-04-09-bartos-cloud-tls-app-template.md` for the cert-manager + TLS + app-template implementation plan.
