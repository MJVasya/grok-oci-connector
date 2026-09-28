# Grok OCI MCP Connector

Talks to Oracle’s official OCI Cloud MCP (`oracle.oci-cloud-mcp-server`) over **Streamable HTTP**, then exposes it to Grok with a Cloudflare quick tunnel.

Official refs:

- [oracle/mcp](https://github.com/oracle/mcp) — `src/oci-cloud-mcp-server`
- [Grok custom MCP tunneling](https://x.ai/docs/grok/connectors/custom-mcp-tunneling) (Cloudflare quick tunnel + Streamable HTTP)
- Tools: [docs/TOOLS.md](docs/TOOLS.md) · protocol: [docs/OFFICIAL-MCP.md](docs/OFFICIAL-MCP.md)

No Fusion-style Python bridge. HTTP is enabled by `ORACLE_MCP_HOST` + `ORACLE_MCP_PORT`. Default origin: `http://127.0.0.1:8888/mcp`.

```
Grok ──► https://<id>.trycloudflare.com/mcp ──► cloudflared ──► 127.0.0.1:8888
```

Full install / update / remove / kill-PID: [docs/INSTALL.md](docs/INSTALL.md).

## Official tools (live server)

| Tool | Use |
|---|---|
| `list_oci_clients` | SDK client classes in the installed `oci` package |
| `find_oci_api` | short keyword search → `client_fqn` + `operation` |
| `list_client_operations` | operations on one client class |
| `describe_oci_operation` | required/optional kwargs before a call |
| `invoke_oci_api` | run `client_fqn` + `operation` + `params` |

Transport: Streamable HTTP. Connector URL **must** end in `/mcp`.

`stdio` (bare `uvx oracle.oci-cloud-mcp-server`) is local-only. Grok cannot use it.

## New install

OCI CLI profile working (`~/.oci/config`). Never sudo.

```bash
git clone https://github.com/MJVasya/grok-oci-connector.git
cd grok-oci-connector
bash installers/install-grok-oci.sh
```

Installs `start-oci-grok-stack` / `stop-oci-grok-stack` into `~/.local/bin` (your user, not root).

## After install (daily)

Do **not** rerun `install-grok-oci.sh`. Each session:

1. Valid OCI session/API key (`oci iam region-subscription list`).
2. `start-oci-grok-stack` (no sudo) — prints `GROK_CONNECTOR_URL`.
3. grok.com Custom connector: paste that URL (quick-tunnel host changes every start).
4. Done: `stop-oci-grok-stack`.

## Run (prints Grok URL + PIDs)

```bash
start-oci-grok-stack
# or from a clone:
bash installers/start-oci-grok-stack.sh
```

## Kill PIDs

```bash
stop-oci-grok-stack
# or:
kill "$(cat ~/.grok/oci-stack/mcp.pid)"
kill "$(cat ~/.grok/oci-stack/cloudflared.pid)"
```

## Update

```bash
stop-oci-grok-stack
cd grok-oci-connector && git pull
bash installers/install-grok-oci.sh
```

## Remove

```bash
stop-oci-grok-stack
rm -f ~/.local/bin/start-oci-grok-stack ~/.local/bin/stop-oci-grok-stack ~/.local/bin/install-grok-oci.sh
rm -rf ~/.grok/oci-stack ~/.grok/mcp/oci
```

Tunnel **`:8888`** (HTTP MCP), not a stdio process. Connector URL must end in `/mcp`.
