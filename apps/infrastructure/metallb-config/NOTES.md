# MetalLB Config

## Type

Plain YAML + Kustomize app.

## Purpose

Defines the MetalLB IPAddressPool and L2Advertisement for the cluster. Separated
from the MetalLB controller chart so CRDs are guaranteed to exist before these
custom resources are applied.

## Namespace

- `metallb-system`

## Scope

- `IPAddressPool/homelab-pool` — address range for LoadBalancer services
- `L2Advertisement/homelab-l2` — L2 mode advertisement for the pool

## Address pool

Verified live pool configuration:
- pool name: `homelab-pool`
- addresses: `192.168.141.230-192.168.141.254`
- autoAssign: `true`
- avoidBuggyIPs: `false`
- L2Advertisement name: `homelab-l2`
- interface: `ens33`

## Secrets

- None.

## Notes

- Argo child app: `clusters/bartos-cloud/metallb-config-application.yaml`
- Sync-wave `0` ensures this applies after the MetalLB controller (wave `-2`)
  has installed CRDs and is running.
- Pool name `homelab-pool` and L2Advertisement name `homelab-l2` match live
  cluster resource names.
