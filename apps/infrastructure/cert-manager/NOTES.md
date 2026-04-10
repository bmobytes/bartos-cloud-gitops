# cert-manager

## Type

Upstream Helm chart app with local values stored in this repo.

## Purpose

Installs the cert-manager controller stack used for certificate issuance in the cluster.

## Namespace

- `cert-manager`

## Scope

- CRDs installed by chart values (`installCRDs: true`)
- controller
- webhook
- cainjector

## Secrets

- No static secrets required in Git.
- Issuer-specific secrets should be documented in the issuer app or the consuming app.

## Notes

- Argo child app: `clusters/bartos-cloud/cert-manager-application.yaml`
- Chart version is pinned to match the currently running cluster version: `v1.14.5`
- Cluster-wide issuer policy lives separately in `apps/infrastructure/cert-manager-issuers/`
