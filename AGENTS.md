# AGENTS.md — bartos-cloud-gitops

This repository is the GitOps source of truth for the `bartos-cloud` Kubernetes cluster.

If you are another AI agent working here, follow these rules exactly.

---

## 1. Mission

Your job is to manage workloads and supporting infrastructure for `bartos-cloud` through GitOps.

Default goals:
- keep Git as the durable source of truth
- make Argo CD converge cleanly
- keep secrets out of Git
- verify live cluster health after changes
- avoid changing platform components that are not owned by this repo

---

## 2. Canonical paths

- Repo root: `/mnt/rackshack/wish/workspace/bartos-cloud-gitops`
- Git remote: `git@github.com:bmobytes/bartos-cloud-gitops.git`
- Kubeconfig: `/mnt/rackshack/projects/kube/hermes-kubeconfig.yaml`
- Kube context: `hermes@bartos-cloud`
- Full ops guide: `docs/operations/bartos-cloud-cluster-ops-guide.md`

Always work from this repo checkout unless explicitly told otherwise.

---

## 3. Required first steps before any change

Run these first:

```bash
export KUBECONFIG=/mnt/rackshack/projects/kube/hermes-kubeconfig.yaml
kubectl config current-context
git fetch origin main
git status --short
git pull --ff-only
kubectl get applications.argoproj.io -n argocd
kubectl get pods -A
```

If the repo is dirty with unrelated changes, stop and inspect before editing.

---

## 4. Source-of-truth rules

### Use GitOps first
For durable changes:
- edit manifests/values in this repo
- commit changes
- push changes
- let Argo CD reconcile
- verify live resources after sync

### Live kubectl edits are temporary
Only make direct cluster changes when necessary for:
- debugging
- emergency repair
- confirming a hypothesis

If a live change is meant to persist, mirror it back into Git immediately.

---

## 5. Ownership boundaries

### Repo-managed
This repo manages:
- Argo app-of-apps structure
- workload manifests
- some infrastructure apps
- Helm values for selected apps
- Infisical secret claims
- Hermes RBAC

### Not currently managed here
Do **not** assume ownership of these unless you explicitly add them to GitOps:
- Cilium
- Longhorn
- MetalLB
- ingress-nginx

These exist in the cluster but were not found in this repo during validation.

---

## 6. Access model

Default cluster identity is the `hermes` ServiceAccount.

It can currently:
- manage namespaces
- manage namespace-scoped workloads
- manage Argo CD CRDs
- manage CRDs
- manage ClusterRoles and ClusterRoleBindings
- manage Infisical CRDs
- read nodes, PVs, storage classes, ingress classes, and metrics

Do **not** assume this identity is a full replacement for a true admin kubeconfig in every situation.

Use an admin path for:
- kubeadm changes
- node changes
- control-plane reconfiguration
- core platform replacement or bootstrap work

---

## 7. Repo structure

```text
bootstrap/                  # root Argo bootstrap manifest
clusters/bartos-cloud/      # child Argo Applications
apps/infrastructure/        # infra apps/manifests
apps/monitoring/            # monitoring app values
apps/workloads/             # workload apps/manifests
apps/secrets/               # InfisicalSecret claims
templates/                  # app templates
```

### Root bootstrap
- file: `bootstrap/root-application.yaml`
- creates root app: `bartos-cloud`
- root path: `clusters/bartos-cloud`

### Child apps
Each child app usually lives at:
- `clusters/bartos-cloud/<app>-application.yaml`

---

## 8. Supported app patterns

### Pattern A — plain YAML + Kustomize
Use for small/custom apps.

Expected files:
```text
apps/<group>/<app>/
├── kustomization.yaml
├── namespace.yaml
├── deployment.yaml
├── service.yaml
├── ingress.yaml
└── NOTES.md
```

### Pattern B — upstream Helm chart + local values
Use for mature third-party apps.

Expected files:
```text
apps/<group>/<app>/
├── values.yaml
└── NOTES.md
```

Multi-source Argo apps are normal for Helm apps.

Examples:
- `cert-manager`
- `netdata`
- `openlit`
- `open-webui`

---

## 9. Secrets rules

Secrets do **not** belong in Git.

Use this pattern instead:
- store secret values in Infisical Cloud
- commit `InfisicalSecret` claim manifests in `apps/secrets/<app>/`
- let the Infisical operator materialize Kubernetes Secrets in-cluster

### Current Infisical scope
- project slug: `bartos-k8s-6-lmc`
- env slug: `prod`

### Bootstrap exception
The following secret must exist locally in-cluster and is not stored in Git:
- namespace: `infisical`
- secret: `universal-auth-credentials`

If you need a new app secret:
1. create secret values in Infisical
2. add claim manifests under `apps/secrets/<app>/`
3. add a corresponding Argo child app if needed
4. verify the Kubernetes Secret appears in the target namespace

Never commit plaintext credentials, API keys, tokens, or passwords.

---

## 10. Networking and TLS defaults

### Hostnames
Default hostname pattern:
- `<app>.lab.bartos.media`

### Ingress
Default assumptions:
- ingress controller: `ingress-nginx`
- ingress class: `nginx`
- published IP should resolve to: `192.168.141.230`

### TLS
Default ingress TLS settings:
- annotation: `cert-manager.io/cluster-issuer: lab-ca`
- TLS secret name: `<app>-tls`

If DNS or ingress state looks wrong, verify:
```bash
kubectl -n ingress-nginx get svc ingress-nginx-controller -o wide
kubectl get ingress -A -o wide
kubectl -n external-dns logs deploy/external-dns --since=10m
```

---

## 11. Storage defaults

Default storage class:
- `longhorn`

For persistent apps, default to Longhorn unless there is a strong reason otherwise.

Verify with:
```bash
kubectl get storageclass,pv,pvc -A
```

---

## 12. Standard workflow for changes

### A. Sync state first
```bash
export KUBECONFIG=/mnt/rackshack/projects/kube/hermes-kubeconfig.yaml
kubectl config current-context
git fetch origin main
git pull --ff-only
kubectl get applications.argoproj.io -n argocd
kubectl get pods -A
```

### B. Make repo changes
- choose the correct app pattern
- edit only the minimal required files
- keep NOTES up to date when you change app behavior
- add/update secret claims under `apps/secrets/` if needed

### C. Validate locally
For Kustomize apps:
```bash
kubectl kustomize clusters/bartos-cloud
kubectl kustomize apps/<group>/<app>
```

For Helm apps:
```bash
helm template <name> <repo>/<chart> -f apps/<group>/<app>/values.yaml
```

### D. Commit and push
Use narrow commits.

### E. Verify live cluster
After Argo sync:
```bash
kubectl get applications.argoproj.io -n argocd
kubectl get pods -A
kubectl get ingress -A -o wide
kubectl get secret -A
```

---

## 13. New app checklist

1. pull latest `origin/main`
2. choose plain-app or Helm-app pattern
3. create `apps/...` path
4. add `NOTES.md`
5. add `apps/secrets/<app>/` if secrets are required
6. add `clusters/bartos-cloud/<app>-application.yaml`
7. add child app to `clusters/bartos-cloud/kustomization.yaml`
8. validate locally
9. commit and push
10. verify Argo and workload health

---

## 14. Known important live status

### Healthy Argo apps during last validation
- `bartos-cloud`
- `cert-manager`
- `cert-manager-issuers`
- `external-dns`
- `external-dns-secrets`
- `hermes-rbac`
- `honcho`
- `honcho-db-secrets`
- `honcho-postgres`
- `honcho-secrets`
- `honcho-ui`
- `infisical-operator`
- `infisical-secrets`
- `netdata`
- `open-webui`
- `open-webui-secrets`
- `openlit`
- `firecrawl-secrets`

### Known degraded app
- `firecrawl` — `Synced`, `Progressing`

Known symptom:
- Firecrawl worker is crashing because RabbitMQ intermittently refuses connections.

Before doing unrelated work, be aware that Firecrawl is already in a degraded state.

---

## 15. Fast troubleshooting commands

### Argo
```bash
kubectl get applications.argoproj.io -n argocd
kubectl describe application <app> -n argocd
kubectl logs -n argocd deploy/argocd-repo-server --tail=200
kubectl logs -n argocd statefulset/argocd-application-controller --tail=200
```

### Secrets / Infisical
```bash
kubectl get infisicalsecrets.secrets.infisical.com -A
kubectl describe infisicalsecret <name> -n <namespace>
kubectl get secret -n <namespace>
kubectl logs -n infisical deploy/infisical-opera-controller-manager --tail=200
```

### Storage
```bash
kubectl get storageclass,pv,pvc -A
kubectl get pods -n longhorn-system
```

### Firecrawl
```bash
kubectl -n firecrawl get pods
kubectl -n firecrawl logs deploy/firecrawl-worker --tail=200
kubectl -n firecrawl logs deploy/firecrawl-rabbitmq --tail=200
```

---

## 16. Final operating rules

- prefer GitOps over direct kubectl edits
- prefer minimal, surgical changes
- validate before and after every change
- keep secrets out of Git
- pull latest remote state before editing
- do not assume ownership of platform components outside this repo
- document durable changes
- treat Firecrawl as a known degraded workload until repaired
