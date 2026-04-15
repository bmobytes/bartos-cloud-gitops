# MetalLB

## Type

Upstream Helm chart app with local values stored in this repo.

## Purpose

MetalLB provides bare-metal LoadBalancer service support for the cluster.

## Namespace

- `metallb-system`

## Scope

- MetalLB controller (Deployment)
- MetalLB speaker (DaemonSet)
- CRDs

## Chart

- Repository: `https://metallb.github.io/metallb`
- Chart: `metallb`
- Version: `0.14.5`

## Values

Default chart values are used. The MetalLB chart installs the controller and
speaker but does not include IP pool or advertisement configuration. Those are
managed separately in `apps/infrastructure/metallb-config/`.

## Secrets

- No static secrets required in Git.
- The speaker memberlist secret is generated at runtime and is not managed here.

## Notes

- Argo child app: `clusters/bartos-cloud/metallb-application.yaml`
- Chart version pinned to match the currently running cluster version: `0.14.5`
- IP pool and L2 advertisement are in a separate Argo app (`metallb-config`)
  so the controller CRDs are installed before the config resources are applied.
- Argo sync-wave `-2` is used so MetalLB installs before ingress-nginx.
