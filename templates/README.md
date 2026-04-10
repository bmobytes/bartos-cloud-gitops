# GitOps templates

Two supported app patterns:

1. `plain-app/` — default for plain YAML + Kustomize apps
2. `helm-app/` — upstream Helm chart apps with local values in Git

## App bootstrap checklist

1. Choose `plain-app` or `helm-app`
2. Copy the template into `apps/<group>/<app>/` as needed
3. Fill out `NOTES.md`
4. Document required secret names and keys
5. Set ingress host under `*.lab.bartos.media`
6. Use TLS via `cert-manager.io/cluster-issuer: lab-ca`
7. Create `clusters/bartos-cloud/<app>-application.yaml`
8. Add the child app to `clusters/bartos-cloud/kustomization.yaml`
9. Validate locally
10. Push and verify Argo sync
