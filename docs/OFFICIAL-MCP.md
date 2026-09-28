# Official OCI Cloud MCP

Package: `oracle.oci-cloud-mcp-server` from [oracle/mcp](https://github.com/oracle/mcp).

## Transports

| Mode | How | Who can connect |
|---|---|---|
| stdio | `uvx oracle.oci-cloud-mcp-server` with no host/port | local MCP client only |
| HTTP / Streamable HTTP | `ORACLE_MCP_HOST` + `ORACLE_MCP_PORT` set | Grok via public HTTPS `/mcp` |

This stack always sets:

```
ORACLE_MCP_HOST=127.0.0.1
ORACLE_MCP_PORT=8888
```

Listen log must contain `transport 'http'` (or streamable-http), never `stdio`.

## Auth

- **stdio / this stack’s outbound OCI calls:** `~/.oci/config` profile (`OCI_CONFIG_PROFILE`, default `DEFAULT`). Token or API key.
- **Official HTTP + IAM user-on-behalf:** `IDCS_DOMAIN`, `IDCS_CLIENT_ID`, `IDCS_CLIENT_SECRET`, `IDCS_AUDIENCE`, `ORACLE_MCP_BASE_URL`. Put these in `~/.grok/oci-stack/env` if the process exits asking for them.
- Default HTTP scopes (if IDCS used): `openid profile email oci_mcp.cloud.invoke`.
- Register `${ORACLE_MCP_BASE_URL}/auth/callback` on the IAM confidential app. Quick-tunnel host changes every start, so named Cloudflare Tunnel is better if you rely on IDCS callbacks.

## Cloudflare

Quick tunnel: `cloudflared tunnel --url http://127.0.0.1:8888`.

Grok docs: Cloudflare quick tunnels **do not** support SSE. Streamable HTTP is OK.

## URL

Grok Custom connector:

```
https://<trycloudflare-host>/mcp
```

Do not paste `localhost`, `127.0.0.1`, or a URL without `/mcp`.
