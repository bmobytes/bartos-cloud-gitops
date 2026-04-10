# Honcho Explorer UI

Static HTML UI for browsing Honcho workspaces, peers, sessions, messages, and collections.

## Architecture

- **nginx:1-alpine** serves `index.html` and reverse-proxies API requests to the `honcho` service in-cluster
- Ingress at `honcho-ui.lab.bartos.media` with TLS via `lab-ca`
- Same-origin proxy eliminates CORS issues: `/v3/*` and `/health` are forwarded to the Honcho API

## Defaults

- **Base URL**: `window.location.origin` (same-origin, hits the nginx proxy)
- **Workspace ID**: `hermes`

## API compatibility

The UI was originally written against Honcho v2 endpoints. It has been remapped to the current Honcho v3 API surface used by this cluster.

### Endpoint remaps applied

- connect:
  - from `GET /v3/workspaces/{workspace_id}`
  - to `POST /v3/workspaces` with `{ id }`
- peers list:
  - to `POST /v3/workspaces/{workspace_id}/peers/list`
- sessions list:
  - to `POST /v3/workspaces/{workspace_id}/sessions/list`
- peer-scoped sessions:
  - to `POST /v3/workspaces/{workspace_id}/peers/{peer_id}/sessions`
- messages list:
  - to `POST /v3/workspaces/{workspace_id}/sessions/{session_id}/messages/list`
- search:
  - to `POST /v3/workspaces/{workspace_id}/search`
- dialectic chat:
  - to `POST /v3/workspaces/{workspace_id}/peers/{peer_id}/chat` with `query`
- peer context:
  - `GET /v3/workspaces/{workspace_id}/peers/{peer_id}/context`
- session context:
  - `GET /v3/workspaces/{workspace_id}/sessions/{session_id}/context?peer_target=...`
- collections/documents view:
  - replaced with workspace-wide **conclusions** using `POST /v3/workspaces/{workspace_id}/conclusions/list`

### Removed / repurposed feature

- The old Collections/Documents view no longer exists in current Honcho v3 as used here.
- The UI now uses that tab to show **Conclusions** instead.

### Remaining caveats

- The single-file UI is still a pragmatic compatibility layer, not a full product-grade Honcho v3 client.
- If a future Honcho release changes request/response shapes, the affected tab may need another small patch.
