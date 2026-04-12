# OpenLIT

Self-hosted AI/LLM observability platform deployed via Argo CD from the upstream OpenLIT Helm chart.

- **Chart:** `openlit/openlit` v1.17.2
- **Namespace:** `openlit`
- **Ingress:** `openlit.lab.bartos.media` (nginx, TLS via lab-ca)
- **Backend:** Bundled ClickHouse (Longhorn-backed persistence)

## Secrets

No external secrets are required for basic bring-up. The chart ships with default ClickHouse credentials (`default` / `OPENLIT`) baked into the chart values. These are used internally between the OpenLIT app and the bundled ClickHouse instance.

**Post-deploy hardening:** Consider rotating the default ClickHouse password and supplying it via a Kubernetes secret (`clickhouse.auth.secret` and `config.secret` chart values) once the deployment is verified.

## Authentication

By default, OpenLIT starts in preview mode disabled, which means email/password login is active. The default credentials are set in the app's own onboarding flow on first access. No pre-seeded account secret is needed.

## Operator

The bundled `openlit-operator` subchart is disabled. It provides auto-instrumentation for workloads via OpenTelemetry but is not required for the core UI/platform.

## Anonymous telemetry

Disabled via `config.usageMetrics: false`.
