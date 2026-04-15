# ingress-nginx

## Type

Upstream Helm chart app with local values stored in this repo.

## Purpose

Provides the ingress controller for all HTTP/HTTPS traffic into the cluster.

## Namespace

- `ingress-nginx`

## Scope

- ingress-nginx controller (Deployment)
- LoadBalancer Service pinned to `192.168.141.230`
- Admission webhook

## Chart

- Repository: `https://kubernetes.github.io/ingress-nginx`
- Chart: `ingress-nginx`
- Version: `4.10.1`

## Values

- `controller.publishService.enabled: false` — avoids relying on `--publish-service`.
- `controller.extraArgs.publish-status-address: 192.168.141.230` — forces ingress
  status publication to the MetalLB VIP that ExternalDNS should publish.
- `controller.service.loadBalancerIP: 192.168.141.230` — pins the service to the
  MetalLB-assigned IP.
- `controller.config.use-forwarded-headers: true` — preserves client IP through
  the proxy.

## Secrets

- No static secrets required in Git.
- The admission webhook generates its own TLS certificate at runtime.

## Notes

- Argo child app: `clusters/bartos-cloud/ingress-nginx-application.yaml`
- Chart version pinned to match the currently running cluster version: `4.10.1`
  (app version `1.10.1`).
- The `publishService` setting is critical for ExternalDNS integration. Without it,
  ingress resources will not have an address, and DNS records will not be created.
