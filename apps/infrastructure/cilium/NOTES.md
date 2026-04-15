# Cilium

## Type

Upstream Helm chart app with local values stored in this repo.

## Purpose

Cilium is the CNI plugin for the `bartos-cloud` cluster, providing pod networking
and network policy enforcement.

## Namespace

- `kube-system`

## Scope

- Cilium agent (DaemonSet)
- Cilium operator
- VXLAN tunnel-mode networking

## Chart

- Repository: `https://helm.cilium.io/`
- Chart: `cilium`
- Version: `1.19.1`

## Values

Matches the live cluster configuration retrieved via `helm get values`:
- `cluster.name: kubernetes`
- `operator.replicas: 1`
- `routingMode: tunnel`
- `tunnelProtocol: vxlan`

## Secrets

- No static secrets required in Git.
- Cilium may generate internal certs/keys at runtime; these are not managed here.

## Notes

- Argo child app: `clusters/bartos-cloud/cilium-application.yaml`
- Chart version pinned to match the currently running cluster version: `1.19.1`
- Cilium is a critical platform component. Changes should be tested carefully and
  coordinated with cluster maintenance windows.
- CRDs are managed by the chart. Argo sync option `ServerSideApply=true` is used
  to handle large CRD resources and avoid annotation size limits.
