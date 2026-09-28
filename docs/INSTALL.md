# Install, run, update, remove

## New install (Mac)

1. OCI CLI configured as **your login user** (`~/.oci/config`). Test: `oci iam region-subscription list`.
2. `cloudflared` on PATH (`brew install cloudflare/cloudflare/cloudflared`).
3. `uv` on PATH (`curl -LsSf https://astral.sh/uv/install.sh | sh`).
4. Install the connector:

```bash
git clone https://github.com/MJVasya/grok-oci-connector.git
cd grok-oci-connector
bash installers/install-grok-oci.sh
```

Never use `sudo` on these commands. Files must land in `~/.grok` and `~/.local/bin`.

`install-grok-oci.sh` links:

- `~/.local/bin/start-oci-grok-stack`
- `~/.local/bin/stop-oci-grok-stack`

Ensure `~/.local/bin` is on your PATH (add `export PATH="$HOME/.local/bin:$PATH"` to `~/.zshrc` if `command -v start-oci-grok-stack` fails).

Optional env: copy `env.example` → `~/.grok/oci-stack/env` (region, profile, IDCS if HTTP mode demands it).

## After install (daily)

Do **not** rerun `install-grok-oci.sh`. Each session:

1. OCI credentials valid.
2. `start-oci-grok-stack` (no sudo) — starts official HTTP MCP + Cloudflare tunnel and prints `GROK_CONNECTOR_URL`.
3. grok.com **Custom** connector: paste that URL. The trycloudflare hostname changes every start.
4. When done: `stop-oci-grok-stack`.

If the MCP log still says `transport 'stdio'`, HTTP env did not reach `uvx`. Re-run the start script; do not start `uvx` by hand without `ORACLE_MCP_HOST` / `ORACLE_MCP_PORT`.

## Run (hidden stack + Grok URL)

```bash
start-oci-grok-stack
```

From a git clone:

```bash
bash installers/start-oci-grok-stack.sh
```

Prints:

```
GROK_CONNECTOR_URL=https://<name>.trycloudflare.com/mcp
```

Paste that URL into grok.com/connectors → Custom. Hostname changes every launch.

State files: `~/.grok/oci-stack/` (`mcp.pid`, `cloudflared.pid`, `mcp.log`, `cloudflared.log`, `connector.url`).

## Kill PIDs

```bash
stop-oci-grok-stack
```

Manual:

```bash
kill "$(cat ~/.grok/oci-stack/mcp.pid)"
kill "$(cat ~/.grok/oci-stack/cloudflared.pid)"
```

## Update

```bash
stop-oci-grok-stack
cd grok-oci-connector && git pull
bash installers/install-grok-oci.sh
start-oci-grok-stack
```

Then replace the Custom connector URL (quick tunnel host is new).

## Remove

```bash
stop-oci-grok-stack
rm -f ~/.local/bin/start-oci-grok-stack ~/.local/bin/stop-oci-grok-stack
rm -rf ~/.grok/oci-stack ~/.grok/mcp/oci
```

Edit `~/.grok/config.toml` and delete `[mcp_servers.oci]` if present. Remove the Custom connector on grok.com.
