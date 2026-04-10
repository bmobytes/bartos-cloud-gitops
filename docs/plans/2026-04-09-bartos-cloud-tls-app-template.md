# Bartos Cloud TLS + App Template Implementation Plan

> **For Hermes:** Use subagent-driven-development or BMO direct execution to implement this plan task-by-task.

**Goal:** Establish durable cert-manager/TLS conventions and a repeatable GitOps app bootstrap pattern for `bartos-cloud`.

**Architecture:** Keep the repo as Argo app-of-apps with plain YAML + Kustomize as the default. Treat cert-manager as infrastructure, cluster issuers as a separate cluster-scoped app, and support two app shapes: plain Kustomize apps and upstream Helm apps with local values.

**Tech Stack:** Argo CD, Kustomize, cert-manager, ingress-nginx, ExternalDNS, MetalLB, Infisical.

---

## Current observed state

- Repo already uses app-of-apps under `clusters/bartos-cloud/`
- Live apps in GitOps:
  - `external-dns`
  - `hermes-rbac`
  - `test-app`
  - `netdata`
  - `infisical-operator`
  - `infisical-secrets`
- `cert-manager` is running in-cluster already, but is **not yet represented in the GitOps repo**
- Current ingresses have no TLS blocks:
  - `argocd.lab.bartos.media`
  - `netdata.lab.bartos.media`
  - `test-app.lab.bartos.media`
- Because this cluster is homelab/private-first, TLS conventions should work for **internal lab services now** without assuming public ACME reachability

---

## Design decisions

### TLS / cert-manager conventions

1. **GitOps-manage cert-manager**
   - Add a dedicated child app for cert-manager so cluster bootstrap is reproducible.
   - Keep chart values in-repo.

2. **Separate controller install from issuer policy**
   - `cert-manager` app installs the controller
   - `cert-manager-issuers` app owns `ClusterIssuer`, bootstrap CA materials, and cluster TLS policy

3. **Default internal TLS strategy: local cluster CA**
   - For `*.lab.bartos.media`, use a cert-manager-managed internal CA first.
   - Bootstrap sequence:
     - `SelfSigned` ClusterIssuer (bootstrap only)
     - root CA `Certificate`
     - `CA` ClusterIssuer backed by the generated CA secret
   - Default issuing path for lab apps: `ClusterIssuer/lab-ca`

4. **Future public TLS remains optional**
   - Add `letsencrypt-staging` / `letsencrypt-prod` only when a public solver is actually available.
   - Do not block internal TLS on public DNS/HTTP reachability.

5. **Ingress defaults**
   - every ingress sets `ingressClassName: nginx`
   - every ingress gets a TLS block
   - default issuer annotation:
     - `cert-manager.io/cluster-issuer: lab-ca`
   - TLS secret naming:
     - single host: `<app>-tls`
     - multi-host/shared ingress: `<app>-ingress-tls`

6. **Hostname convention**
   - default app hostname: `<app>.lab.bartos.media`
   - reserve non-`lab` public names for later public-facing services only

### App bootstrap pattern

Support exactly **two** app patterns:

1. **Plain app (default)**
   - app path contains manifests + `kustomization.yaml`
   - use for small internal services and first-party YAML

2. **Helm app (upstream chart + local values)**
   - child `Application` is multi-source
   - repo stores `values.yaml` and `NOTES.md`
   - use for mature third-party charts like Netdata

Avoid inventing more patterns unless a real app needs them.

### Required files for every new app

#### Plain app

```text
apps/<group>/<app>/
├── kustomization.yaml
├── namespace.yaml
├── deployment.yaml            # if applicable
├── service.yaml               # if applicable
├── ingress.yaml               # if applicable
└── NOTES.md
```

#### Helm app

```text
apps/<group>/<app>/
├── values.yaml
└── NOTES.md
```

#### Cluster child app

```text
clusters/bartos-cloud/<app>-application.yaml
```

### Required NOTES.md contents for each app

Every app notes file should document:
- purpose of the app
- hostnames used
- secret names expected
- secret keys expected
- storage/PVC expectations
- whether the app is plain or Helm-based
- any manual bootstrap or one-time migration step

---

## Target repo additions

```text
bartos-cloud-gitops/
├── docs/
│   └── plans/
│       └── 2026-04-09-bartos-cloud-tls-app-template.md
├── templates/
│   ├── plain-app/
│   │   ├── NOTES.md
│   │   ├── deployment.yaml
│   │   ├── ingress.yaml
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   └── service.yaml
│   └── helm-app/
│       ├── NOTES.md
│       ├── application.yaml
│       └── values.yaml
├── clusters/
│   └── bartos-cloud/
│       ├── cert-manager-application.yaml
│       └── cert-manager-issuers-application.yaml
└── apps/
    └── infrastructure/
        ├── cert-manager/
        │   └── values.yaml
        └── cert-manager-issuers/
            ├── bootstrap-selfsigned-clusterissuer.yaml
            ├── lab-ca-certificate.yaml
            ├── lab-ca-clusterissuer.yaml
            └── kustomization.yaml
```

---

## Implementation tasks

### Task 1: Add repo documentation for the two supported app patterns

**Objective:** Make the GitOps shape explicit before adding more apps.

**Files:**
- Modify: `README.md`
- Create: `templates/plain-app/*`
- Create: `templates/helm-app/*`

**Steps:**
1. Update `README.md` with a new section named `Conventions`.
2. Document the two supported app patterns:
   - plain Kustomize app
   - Helm chart app with local values
3. Add `templates/plain-app/` scaffolding files.
4. Add `templates/helm-app/` scaffolding files.
5. Validate the plain app template renders with:
   - `kubectl kustomize templates/plain-app`

**Verification:**
- `kubectl kustomize templates/plain-app`
- expected: valid rendered YAML output

---

### Task 2: Bring cert-manager under GitOps

**Objective:** Make cert-manager installation reproducible.

**Files:**
- Create: `clusters/bartos-cloud/cert-manager-application.yaml`
- Create: `apps/infrastructure/cert-manager/values.yaml`
- Modify: `clusters/bartos-cloud/kustomization.yaml`
- Modify: `README.md`

**Design:**
- Install upstream chart via Argo CD multi-source or inline values.
- Prefer the same style already used successfully for Netdata and Infisical.
- Namespace: `cert-manager`
- Sync wave: before issuer resources

**Verification:**
- `kubectl kustomize clusters/bartos-cloud`
- If Helm values are external, also validate chart rendering with:
  - `helm repo add jetstack https://charts.jetstack.io`
  - `helm repo update`
  - `helm template cert-manager jetstack/cert-manager --namespace cert-manager --set installCRDs=true -f apps/infrastructure/cert-manager/values.yaml`

---

### Task 3: Add cluster issuer bootstrap app

**Objective:** Establish a reusable internal CA for lab ingress certificates.

**Files:**
- Create: `clusters/bartos-cloud/cert-manager-issuers-application.yaml`
- Create: `apps/infrastructure/cert-manager-issuers/kustomization.yaml`
- Create: `apps/infrastructure/cert-manager-issuers/bootstrap-selfsigned-clusterissuer.yaml`
- Create: `apps/infrastructure/cert-manager-issuers/lab-ca-certificate.yaml`
- Create: `apps/infrastructure/cert-manager-issuers/lab-ca-clusterissuer.yaml`
- Create: `apps/infrastructure/cert-manager-issuers/NOTES.md`
- Modify: `clusters/bartos-cloud/kustomization.yaml`

**Convention:**
- bootstrap issuer name: `selfsigned-bootstrap`
- CA certificate secret: `lab-ca-key-pair`
- durable cluster issuer name: `lab-ca`

**Verification:**
- `kubectl kustomize apps/infrastructure/cert-manager-issuers`
- `kubectl kustomize clusters/bartos-cloud`

---

### Task 4: Apply TLS conventions to existing ingresses

**Objective:** Make existing apps conform to the new TLS pattern.

**Files:**
- Modify: `apps/workloads/test-app/ingress.yaml`
- Modify: `apps/monitoring/netdata/values.yaml`
- Add later if desired: Argo CD ingress source-of-truth under GitOps if/when Argo itself is pulled fully under this repo

**Convention for test-app ingress:**
- annotation: `cert-manager.io/cluster-issuer: lab-ca`
- TLS secret: `test-app-tls`
- host: `test-app.lab.bartos.media`

**Convention for Netdata values:**
- chart ingress annotations include `cert-manager.io/cluster-issuer: lab-ca`
- chart ingress TLS points to `netdata-tls`

**Verification:**
- `kubectl kustomize apps/workloads/test-app`
- `helm template netdata netdata/netdata --version 3.7.163 -f apps/monitoring/netdata/values.yaml`

---

### Task 5: Add a written bootstrap checklist for future apps

**Objective:** Make adding apps routine instead of ad hoc.

**Files:**
- Create or update: `templates/README.md` or `README.md`

**Checklist content:**
- choose plain vs Helm pattern
- create app folder
- create NOTES.md
- declare secrets required
- declare ingress host
- declare TLS secret name
- create child app manifest under `clusters/bartos-cloud/`
- add it to `clusters/bartos-cloud/kustomization.yaml`
- validate render locally
- push and verify Argo

---

## Recommended execution order

1. Task 1 — document the patterns
2. Task 2 — GitOps-manage cert-manager
3. Task 3 — add internal CA issuer bootstrap
4. Task 4 — apply TLS to test-app and Netdata
5. Task 5 — finalize the bootstrap checklist

---

## Acceptance criteria

The work is complete when:
- cert-manager is represented in GitOps
- cluster issuers are represented in GitOps
- the repo has one documented default TLS issuer for internal apps
- the repo has one documented plain app pattern and one documented Helm app pattern
- at least one existing app ingress is converted to the new TLS convention
- the README tells future-you exactly how to add the next app

---

## Notes on scope

- This plan intentionally does **not** assume public Let’s Encrypt issuance today.
- This plan intentionally avoids storing secrets in Git.
- If later you expose selected services publicly, add a second issuer path rather than replacing `lab-ca`.
