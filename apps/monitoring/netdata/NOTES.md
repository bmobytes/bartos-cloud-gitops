# Netdata

Netdata is deployed by Argo CD from the upstream Netdata Helm chart.

## Secret requirement

Before the app can claim successfully in Netdata Cloud, the `netdata` namespace must contain a secret named `netdata-cloud-claim` with:

- `NETDATA_CLAIM_TOKEN`

Example:

```bash
kubectl create namespace netdata --dry-run=client -o yaml | kubectl apply -f -
kubectl -n netdata create secret generic netdata-cloud-claim   --from-literal=NETDATA_CLAIM_TOKEN='<token>'   --dry-run=client -o yaml | kubectl apply -f -
```

Non-secret settings are stored in `values.yaml`:
- claim URL: `https://app.netdata.cloud`
- room ID: `b0a5f9a1-6e9b-49af-910c-fda989ba88e6`
- ingress host: `netdata.lab.bartos.media`
