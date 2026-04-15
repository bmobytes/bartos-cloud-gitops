# Longhorn

## Type

Upstream Helm chart app with local values stored in this repo.

## Purpose

Longhorn provides distributed block storage and is the default StorageClass for
the `bartos-cloud` cluster.

## Namespace

- `longhorn-system`

## Scope

- Longhorn manager
- Longhorn driver deployer
- Longhorn UI
- CSI driver components
- Default StorageClass `longhorn`

## Chart

- Repository: `https://charts.longhorn.io`
- Chart: `longhorn`
- Version: `1.6.2`

## Values

Configured to match the live cluster StorageClass parameters:
- `persistence.defaultClass: true` — makes `longhorn` the default StorageClass
- `persistence.defaultClassReplicaCount: 3` — `numberOfReplicas: '3'`
- `persistence.defaultFsType: ext4` — `fsType: 'ext4'`
- `storageClass.allowVolumeExpansion: true`
- `defaultSettings.defaultDataLocality: disabled` — `dataLocality: 'disabled'`

Live StorageClass also has these parameters (chart defaults):
- `staleReplicaTimeout: '30'`
- `fromBackup: ''`
- `unmapMarkSnapChainRemoved: 'ignored'`

## Secrets

- No static secrets required in Git.

## Notes

- Argo child app: `clusters/bartos-cloud/longhorn-application.yaml`
- Chart version pinned to match the currently running cluster version: `1.6.2`
- Longhorn is a critical storage component. Upgrades should be planned carefully.
- The `staleReplicaTimeout`, `fromBackup`, and `unmapMarkSnapChainRemoved`
  parameters are chart defaults and do not need explicit values.
