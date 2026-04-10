# APP_NAME

## Type

Plain Kustomize app.

## Required edits

- replace `APP_NAME`
- replace `APP_NAMESPACE`
- replace `APP_HOST`
- replace container image and ports
- add secrets / PVCs as needed

## Default conventions

- ingress class: `nginx`
- cluster issuer: `lab-ca`
- TLS secret name: `APP_NAME-tls`
- default hostname: `APP_HOST.lab.bartos.media`

## Remember

- add `clusters/bartos-cloud/APP_NAME-application.yaml`
- add that child app to `clusters/bartos-cloud/kustomization.yaml`
- document required Kubernetes secrets here
