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

The UI was originally written against Honcho v2 endpoints. All API paths have been
updated to `/v3/` for this deployment. Known limitations:

- **Collections & Documents**: The Collections tab calls `/v3/workspaces/.../peers/.../collections`
  and `/v3/.../collections/.../documents`. These endpoints existed in v2 but may not be present
  in v3. If the Honcho instance does not expose collection endpoints, the Collections tab will
  show an error. This is expected — the rest of the UI (peers, sessions, messages, search,
  dialectic) should work normally.
- **Search**: `/v3/workspaces/{id}/search` — verify this endpoint exists on your Honcho version.
- **Dialectic chat**: `/v3/workspaces/{id}/peers/{id}/chat` — same caveat.
- **Representation/context**: `/v3/.../sessions/{id}/context` — may differ between versions.

If any v3 endpoint returns 404, the original v2 paths are easy to restore by editing
`index.html` (search-replace `/v3/` back to `/v2/`).
