#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Do not use sudo. Run as your login user so files land in ~/.grok and ~/.local/bin"
  exit 1
fi

SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ "$SOURCE" != /* ]] && SOURCE="${DIR}/${SOURCE}"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

BIN="${HOME}/.local/bin"
STATE="${HOME}/.grok/oci-stack"
MCP_DIR="${HOME}/.grok/mcp/oci"
mkdir -p "$BIN" "$STATE" "$MCP_DIR"

ln -sfn "${ROOT}/installers/start-oci-grok-stack.sh" "${BIN}/start-oci-grok-stack"
ln -sfn "${ROOT}/installers/stop-oci-grok-stack.sh" "${BIN}/stop-oci-grok-stack"

if [[ ! -f "${STATE}/env" && -f "${ROOT}/env.example" ]]; then
  cp "${ROOT}/env.example" "${STATE}/env"
  echo "Wrote ${STATE}/env from env.example — edit region/profile"
fi

cat > "${MCP_DIR}/manifest.json" << EOF
{
  "name": "oci",
  "version": "1.0.0",
  "description": "Official Oracle OCI Cloud MCP (local Streamable HTTP + Cloudflare tunnel)",
  "transport": { "type": "http", "url": "http://127.0.0.1:8888/mcp" }
}
EOF

mkdir -p "${HOME}/.grok"
TOML="${HOME}/.grok/config.toml"
if [[ -f "$TOML" ]] && grep -q '\[mcp_servers.oci\]' "$TOML"; then
  echo "config.toml already has [mcp_servers.oci]"
else
  printf '\n[mcp_servers.oci]\nurl = "http://127.0.0.1:8888/mcp"\n' >> "$TOML"
  echo "Wrote ${TOML} [mcp_servers.oci]"
fi

if ! echo ":$PATH:" | grep -q ":${BIN}:"; then
  echo "Add to ~/.zshrc: export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo
echo "Next: start-oci-grok-stack   # prints GROK_CONNECTOR_URL"
echo "Stop: stop-oci-grok-stack"
echo "No sudo. Commands: ${BIN}/start-oci-grok-stack"
