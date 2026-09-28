# grok-oci-connector

Same stack as [grok-fusion-connector](https://github.com/MJVasya/grok-fusion-connector): local MCP + Cloudflare quick tunnel → Grok Custom connector.

Origin is Oracle's official `oracle.oci-cloud-mcp-server` (HTTP / Streamable HTTP). No Fusion-style Python bridge required — that server already speaks HTTP when `ORACLE_MCP_HOST` + `ORACLE_MCP_PORT` are set.

```
Grok ──► https://<id>.trycloudflare.com/mcp ──► cloudflared ──► 127.0.0.1:8888
```

Cloudflare **quick** tunnels work with Streamable HTTP. They do **not** support SSE. This server is Streamable HTTP. Hostname changes every start.

## Prereqs (Mac)

- `cloudflared` — `brew install cloudflare/cloudflare/cloudflared`
- `uv` — `curl -LsSf https://astral.sh/uv/install.sh | sh`
- OCI CLI config at `~/.oci/config` (`oci session authenticate` or API key)
- Do **not** use sudo

## Daily

```bash
bash installers/start-oci-grok-stack.sh
# prints + copies:
# GROK_CONNECTOR_URL=https://xxxx.trycloudflare.com/mcp

# grok.com → Connectors → Custom → paste URL

bash installers/stop-oci-grok-stack.sh
```

Keep **both** processes alive while chatting.

## Auth notes

- **stdio** uses `~/.oci/config`. Grok cannot use stdio.
- This stack forces **HTTP**. Outbound OCI calls still use your local OCI profile (`OCI_CONFIG_PROFILE`, default `DEFAULT`).
- Official HTTP mode *can* also require IAM/IDCS (`IDCS_DOMAIN`, `IDCS_CLIENT_ID`, …). If the process exits asking for those, put them in `~/.grok/oci-stack/env` (see `env.example`).
- Quick tunnel is public. Use a least-privilege IAM user. Named Cloudflare Tunnel + Access later if you want a stable host.

## Files

| Path | Role |
|---|---|
| `installers/start-oci-grok-stack.sh` | uvx HTTP MCP + cloudflared; print URL |
| `installers/stop-oci-grok-stack.sh` | kill PIDs |
| `env.example` | optional IDCS / region overrides |
