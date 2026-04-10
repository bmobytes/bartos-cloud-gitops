# APP_NAME

## Type

Upstream Helm chart app with local values stored in this repo.

## Required edits

- replace `APP_NAME`
- replace `APP_NAMESPACE`
- replace `APP_GROUP`
- replace chart repo/name/version in `application.yaml`
- extend `values.yaml` with chart-specific settings

## Default conventions

- if the chart exposes ingress values, prefer `cert-manager.io/cluster-issuer: lab-ca`
- default TLS secret name: `APP_NAME-tls`
- default hostname: `APP_NAME.lab.bartos.media`

## Remember

- copy `application.yaml` to `clusters/bartos-cloud/APP_NAME-application.yaml`
- store only non-secret values in Git
- document required secret names and keys here
