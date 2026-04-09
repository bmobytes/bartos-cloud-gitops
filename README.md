# bartos-cloud-gitops

GitOps repo for the `bartos-cloud` Kubernetes cluster.

## Layout

- `bootstrap/` — one-time Argo CD bootstrap manifests
- `clusters/bartos-cloud/` — app-of-apps definitions for this cluster
- `apps/infrastructure/` — infrastructure apps managed by Argo CD
- `apps/workloads/` — workload apps managed by Argo CD

## Current apps

- `external-dns`
- `hermes-rbac`
- `test-app`

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
kubectl kustomize apps/workloads/test-app
```

## Notes

- This repo stays plain YAML + Kustomize.
- Durable cluster changes should land here first, then sync through Argo CD.
- Emergency direct kubectl changes should be reflected back into GitOps immediately after.
