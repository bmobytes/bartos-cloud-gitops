# UniFi Daily Briefing secrets

Infisical path: `/unifi-daily-briefing`
Project: `bartos-k8s-6-lmc`
Environment: `prod`
Auth: Universal Auth via `universal-auth-credentials` in namespace `infisical`

Required keys:
- `UDB_UNIFI_BASE_URL`
- `UDB_UNIFI_API_KEY`
- `UDB_UNIFI_USERNAME`
- `UDB_UNIFI_PASSWORD`
- `UDB_DISCORD_WEBHOOK_URL`
- `UDB_DISCORD_BOT_TOKEN`

Current deployment note:
- The cluster app is safe to sync with placeholder values.
- A valid UniFi API key is still required before collector jobs should be unsuspended.
- Discord delivery credentials are optional for the web UI, but required for scheduled Discord posting.
- Rackshack Brain writes are not yet wired from inside the cluster workload.
