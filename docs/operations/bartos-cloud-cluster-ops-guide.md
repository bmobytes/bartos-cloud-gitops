# Bartos Cloud Cluster Ops Guide

## Purpose

This document is a direct handoff reference for another AI agent managing the `bartos-cloud` Kubernetes cluster and GitOps repository.

It describes:
- the live cluster shape
- the GitOps repo structure
- how Argo CD is wired
- how secrets are managed
- what is currently healthy vs degraded
- the expected operating workflow for making safe changes

---

## 1. Cluster summary

### Identity
- Cluster name: `bartos-cloud`
- Kubernetes version: `v1.30.14`
- Platform style: HA kubeadm cluster
- OS: Rocky Linux 9.7
- Node count: 6

### Nodes
#### Control plane
- `k8s-cp-01.lab.bartos.media` — `192.168.141.90`
- `k8s-cp-02.lab.bartos.media` — `192.168.141.91`
- `k8s-cp-03.lab.bartos.media` — `192.168.141.92`

#### Workers
- `k8s-wkr-01.lab.bartos.media` — `192.168.141.93`
- `k8s-wkr-02.lab.bartos.media` — `192.168.141.94`
- `k8s-wkr-03.lab.bartos.media` — `192.168.141.95`

### Core cluster components
- CNI: `Cilium`
- Storage: `Longhorn`
- Ingress controller: `ingress-nginx`
- LoadBalancer implementation: `MetalLB`
- Published ingress IP: `192.168.141.230`
- DNS automation: `ExternalDNS` with Technitium webhook provider
- TLS: `cert-manager` with internal CA issuer `lab-ca`
- GitOps: `Argo CD`
- Secrets system: `Infisical Cloud` + `Infisical Kubernetes Operator`

---

## 2. Canonical management paths

### GitOps repo
- Remote: `git@github.com:bmobytes/bartos-cloud-gitops.git`
- Local path: `/mnt/rackshack/wish/workspace/bartos-cloud-gitops`

### Cluster access
- Kubeconfig: `/mnt/rackshack/projects/kube/hermes-kubeconfig.yaml`
- Context: `hermes@bartos-cloud`

### Canonical notes
- GitOps conventions: `02_reference/projects/bartos-cloud-gitops-conventions.md`
- Full cluster ops note: `02_reference/projects/bartos-cloud-cluster-ops-guide.md`

---

## 3. Access and RBAC model

### Default automation identity
The normal automation identity is the `hermes` ServiceAccount.

The RBAC source of truth is:
- `apps/infrastructure/hermes-rbac/rbac.yaml`

### Verified Hermes capabilities
The current Hermes identity can:
- manage namespaces
- act as namespace admin across namespaces
- read nodes, PVs, storage classes, ingress classes, and metrics
- manage Argo CD CRDs:
  - `applications.argoproj.io`
  - `applicationsets.argoproj.io`
  - `appprojects.argoproj.io`
- manage CRDs
- manage `ClusterRole` and `ClusterRoleBinding`
- manage Infisical CRDs

### Important boundary
Do **not** assume Hermes is unrestricted cluster-admin for every possible operation.

Use a true admin kubeconfig for tasks involving:
- kubeadm internals
- node reconfiguration
- control-plane reconfiguration
- cluster bootstrap beyond Hermes RBAC
- replacing core platform components such as Cilium, Longhorn, ingress-nginx, or MetalLB

---

## 4. GitOps ownership boundaries

### Managed in this repo
Repo layout:
- `bootstrap/`
- `clusters/bartos-cloud/`
- `apps/infrastructure/`
- `apps/monitoring/`
- `apps/workloads/`
- `apps/secrets/`
- `templates/`

### Not currently found in this repo
These components are live in cluster but were not found in the GitOps repo during validation:
- `Cilium`
- `MetalLB`
- `ingress-nginx`
- `Longhorn`

Treat those as external platform prerequisites unless explicitly migrated into GitOps later.

---

## 5. Argo CD topology

### Root app
Bootstrap manifest:
- `bootstrap/root-application.yaml`

Behavior:
- creates Argo application `bartos-cloud` in namespace `argocd`
- points to `clusters/bartos-cloud`
- tracks branch `main`
- uses automated sync with prune and self-heal enabled

Bootstrap command:

```bash
export KUBECONFIG=/mnt/rackshack/projects/kube/hermes-kubeconfig.yaml
kubectl apply -n argocd -f /mnt/rackshack/wish/workspace/bartos-cloud-gitops/bootstrap/root-application.yaml
```

### Live child applications
Current live Argo apps:
- `bartos-cloud`
- `cert-manager`
- `cert-manager-issuers`
- `external-dns`
- `external-dns-secrets`
- `firecrawl`
- `firecrawl-secrets`
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

### Repo currency rule
Always update local repo state before making changes.

```bash
git -C /mnt/rackshack/wish/workspace/bartos-cloud-gitops fetch origin main
git -C /mnt/rackshack/wish/workspace/bartos-cloud-gitops pull --ff-only
```

---

## 6. Supported app patterns

### Pattern A — plain YAML + Kustomize
Use for small/custom apps.

Expected shape:

```text
apps/<group>/<app>/
├── kustomization.yaml
├── namespace.yaml
├── deployment.yaml
├── service.yaml
├── ingress.yaml
└── NOTES.md
```

Argo child app path:

```text
clusters/bartos-cloud/<app>-application.yaml
```

### Pattern B — upstream Helm chart + local values
Use for stable third-party apps.

Expected shape:

```text
apps/<group>/<app>/
├── values.yaml
└── NOTES.md
```

Argo typically uses a multi-source application:
- source 1 = upstream Helm chart
- source 2 = Git repo values reference via `$values/...`

Current examples:
- `cert-manager`
- `netdata`
- `openlit`
- `open-webui`

---

## 7. Networking, ingress, and TLS

### Ingress / LoadBalancer
Active ingress controller service:
- namespace: `ingress-nginx`
- service: `ingress-nginx-controller`
- external IP: `192.168.141.230`

Every public ingress in this cluster should ultimately publish that address.

### Hostname convention
Default hostname pattern:
- `<app>.lab.bartos.media`

Verified live ingresses:
- `argocd.lab.bartos.media`
- `firecrawl.lab.bartos.media`
- `honcho.lab.bartos.media`
- `honcho-ui.lab.bartos.media`
- `netdata.lab.bartos.media`
- `open-webui.lab.bartos.media`
- `openlit.lab.bartos.media`
- `test-app.lab.bartos.media`

### TLS convention
Default ingress settings:
- `ingressClassName: nginx`
- annotation: `cert-manager.io/cluster-issuer: lab-ca`
- TLS secret: `<app>-tls`

Relevant manifests:
- `apps/infrastructure/cert-manager-issuers/bootstrap-selfsigned-clusterissuer.yaml`
- `apps/infrastructure/cert-manager-issuers/lab-ca-certificate.yaml`
- `apps/infrastructure/cert-manager-issuers/lab-ca-clusterissuer.yaml`

---

## 8. Storage model

Default storage class:
- `longhorn`

Current workloads using Longhorn-backed PVCs include:
- Netdata
- Honcho Postgres
- Firecrawl NUQ Postgres
- Open WebUI
- OpenLIT
- `test-app`

Default assumption for new persistent apps: use Longhorn unless there is a clear reason not to.

---

## 9. Secrets model

### Design
Secrets are **not** committed to Git.

The cluster uses:
- Infisical Cloud as source of truth
- Infisical Kubernetes Operator for sync
- Git-managed `InfisicalSecret` claims
- regular Kubernetes Secrets consumed by workloads

### Operator details
Argo app:
- `infisical-operator`

Chart:
- repo: `https://dl.cloudsmith.io/public/infisical/helm-charts/helm/charts/`
- chart: `secrets-operator`
- version: `v0.10.29`

Values file:
- `apps/infrastructure/infisical-operator/values.yaml`

### Bootstrap exception
This local secret must exist in cluster to let the operator authenticate:
- namespace: `infisical`
- secret: `universal-auth-credentials`

This is intentionally **not** in Git.

### Project scope
Current Infisical scope:
- project slug: `bartos-k8s-6-lmc`
- environment slug: `prod`

### Claim pattern
Each app should define claim manifests under:
- `apps/secrets/<app>/`

Those claims create ordinary Kubernetes Secrets in the target namespace.

Examples:
- ExternalDNS:
  - Infisical path: `/external-dns`
  - K8s secret: `technitium-credentials`
- Honcho DB:
  - path: `/honcho/db`
  - K8s secret: `honcho-db`
- Honcho LLM key:
  - path/key: `/` → `OPENROUTER_HONCHO`
  - K8s secret: `honcho-llm`
- Firecrawl app bundle:
  - path: `/firecrawl`
  - K8s secret: `firecrawl-secrets`
- Firecrawl DB bundle:
  - path: `/firecrawl/db`
  - K8s secret: `firecrawl-db`
- Open WebUI:
  - claims under `apps/secrets/open-webui`
- Netdata:
  - claims under `apps/secrets/netdata`

### Secret rules
- never commit plaintext secrets
- commit claim manifests only
- bootstrap-only exceptions are acceptable when required to bring the secrets system up
- if an app still uses local/manual secrets, migrate it to `apps/secrets/<app>/` when practical

---

## 10. Live app inventory

### Infrastructure
- Argo CD
- cert-manager
- cert-manager issuers (`lab-ca`)
- ExternalDNS
- Hermes RBAC
- Infisical operator

### Monitoring / observability
- Netdata
- OpenLIT

### Workloads
- Honcho API
- Honcho deriver
- Honcho UI
- Honcho Postgres
- Firecrawl
- Open WebUI
- `test-app`

---

## 11. App-specific notes

### Honcho
Components:
- `honcho-postgres`
- `honcho-db-secrets`
- `honcho-secrets`
- `honcho`
- `honcho-ui`

Hosts:
- `honcho.lab.bartos.media`
- `honcho-ui.lab.bartos.media`

Notes:
- dedicated Postgres + pgvector
- LLM secret comes from Infisical
- config points at `https://openrouter.ai/api/v1`

### Open WebUI
Pattern:
- upstream Helm chart
- values in `apps/workloads/open-webui/values.yaml`
- secrets in `apps/secrets/open-webui`

Live config facts:
- chart version: `13.3.1`
- host: `open-webui.lab.bartos.media`
- storage: `10Gi` on Longhorn
- OpenRouter-compatible base URL: `https://openrouter.ai/api/v1`
- secret: `open-webui-llm`

### Firecrawl
Pattern:
- repo-local app under `apps/workloads/firecrawl`
- secrets under `apps/secrets/firecrawl`

Components:
- API
- worker
- Playwright
- Redis
- RabbitMQ
- NUQ Postgres
- NUQ bootstrap support

Host:
- `firecrawl.lab.bartos.media`

### Firecrawl current warning
As of validation on 2026-04-14:
- Argo app `firecrawl` = `Synced`, `Progressing`
- worker pod = `CrashLoopBackOff`
- worker logs show RabbitMQ connection failure: `ECONNREFUSED ... :5672`
- RabbitMQ pod is running but has very high restart count and repeated probe timeouts

Treat Firecrawl as degraded until repaired.

### Netdata
Pattern:
- upstream Helm chart
- values in `apps/monitoring/netdata/values.yaml`
- claim token delivered via Infisical-managed secret app

Host:
- `netdata.lab.bartos.media`

### OpenLIT
Pattern:
- upstream Helm chart
- values in `apps/monitoring/openlit/values.yaml`

Host:
- `openlit.lab.bartos.media`

---

## 12. Standard operator workflow

### Step 1 — sync context and repo

```bash
export KUBECONFIG=/mnt/rackshack/projects/kube/hermes-kubeconfig.yaml
kubectl config current-context
git -C /mnt/rackshack/wish/workspace/bartos-cloud-gitops fetch origin main
git -C /mnt/rackshack/wish/workspace/bartos-cloud-gitops status --short
git -C /mnt/rackshack/wish/workspace/bartos-cloud-gitops pull --ff-only
```

### Step 2 — validate live cluster state

```bash
kubectl get nodes -o wide
kubectl get ns
kubectl get applications.argoproj.io -n argocd
kubectl get pods -A
kubectl get ingress -A -o wide
kubectl get storageclass,pv,pvc -A
```

### Step 3 — validate manifests before push

Kustomize apps:

```bash
kubectl kustomize clusters/bartos-cloud
kubectl kustomize apps/<group>/<app>
```

Helm apps:

```bash
helm template <name> <repo>/<chart> -f apps/<group>/<app>/values.yaml
```

### Step 4 — push and verify Argo reconciliation
- commit repo changes
- push to `main`
- watch Argo app status
- verify pods, services, ingress, and secrets after sync

### Step 5 — if live kubectl changes were required
Mirror every durable live fix back into Git immediately.

---

## 13. New app checklist

1. Pull latest `origin/main`
2. Choose app pattern
3. Create app path under `apps/...`
4. Add `NOTES.md` with purpose, secrets, hostname, and storage notes
5. Add `apps/secrets/<app>/` if the app needs secrets
6. Add `clusters/bartos-cloud/<app>-application.yaml`
7. Add the child app to `clusters/bartos-cloud/kustomization.yaml`
8. Validate locally
9. Commit and push
10. Verify Argo sync and workload health

---

## 14. Troubleshooting quick map

### Argo app unhealthy

```bash
kubectl get applications.argoproj.io -n argocd
kubectl describe application <app> -n argocd
kubectl logs -n argocd deploy/argocd-repo-server --tail=200
kubectl logs -n argocd statefulset/argocd-application-controller --tail=200
```

### DNS or ingress address wrong

```bash
kubectl -n ingress-nginx get svc ingress-nginx-controller -o wide
kubectl get ingress -A -o wide
kubectl -n external-dns logs deploy/external-dns --since=10m
```

Expected ingress address:
- `192.168.141.230`

### Secret not appearing

```bash
kubectl get infisicalsecrets.secrets.infisical.com -A
kubectl describe infisicalsecret <name> -n <namespace>
kubectl get secret -n <namespace>
kubectl logs -n infisical deploy/infisical-opera-controller-manager --tail=200
```

Common causes:
- wrong Infisical path
- missing key in Infisical
- bad `universal-auth-credentials`
- wrong destination namespace or secret name

### Storage issue

```bash
kubectl get pvc -A
kubectl describe pvc <name> -n <namespace>
kubectl -n longhorn-system get pods
kubectl -n longhorn-system logs deploy/longhorn-driver-deployer --tail=200
```

### Firecrawl issue path

```bash
kubectl -n firecrawl get pods
kubectl -n firecrawl logs deploy/firecrawl-worker --tail=200
kubectl -n firecrawl logs deploy/firecrawl-rabbitmq --tail=200
kubectl -n firecrawl describe pod <worker-pod>
kubectl -n firecrawl describe pod <rabbitmq-pod>
```

Current verified symptom:
- Firecrawl worker is failing because RabbitMQ intermittently refuses connections.

---

## 15. Live state snapshot

### Healthy Argo apps
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

### Not fully healthy
- `firecrawl` — `Synced`, `Progressing`

---

## 16. Minimal command pack

```bash
export KUBECONFIG=/mnt/rackshack/projects/kube/hermes-kubeconfig.yaml

kubectl config current-context
kubectl get nodes -o wide
kubectl get ns
kubectl get applications.argoproj.io -n argocd
kubectl get pods -A
kubectl get ingress -A -o wide
kubectl get storageclass,pv,pvc -A

git -C /mnt/rackshack/wish/workspace/bartos-cloud-gitops fetch origin main
git -C /mnt/rackshack/wish/workspace/bartos-cloud-gitops status --short
git -C /mnt/rackshack/wish/workspace/bartos-cloud-gitops pull --ff-only
git -C /mnt/rackshack/wish/workspace/bartos-cloud-gitops log --oneline --decorate -n 10 --all
```

---

## 17. Operating rules for another AI agent

- Git is the durable source of truth for repo-managed apps.
- Argo CD is the deploy/reconcile engine.
- Never store plaintext secrets in Git.
- Store `InfisicalSecret` claims in Git instead.
- Assume Cilium, Longhorn, MetalLB, and ingress-nginx are outside this repo unless proven otherwise.
- Pull latest remote state before editing anything.
- Treat Firecrawl as the primary currently degraded workload.
- Any durable live fix should be written back into GitOps and docs.
