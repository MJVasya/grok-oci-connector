#!/usr/bin/env bash
# Hidden stack: official OCI Cloud MCP (HTTP) + Cloudflare quick tunnel.
# Prints GROK_CONNECTOR_URL = https://<trycloudflare-host>/mcp
# Run as your login user. Never sudo.
set -euo pipefail

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Do not use sudo. Run as your login user so PIDs/logs land in ~/.grok/oci-stack"
  exit 1
fi

LISTEN="${ORACLE_MCP_HOST:-127.0.0.1}"
PORT="${ORACLE_MCP_PORT:-8888}"
WAIT_SECS="${TUNNEL_WAIT:-45}"
STATE="${GROK_OCI_STATE:-$HOME/.grok/oci-stack}"
ENV_FILE="${GROK_OCI_ENV:-$STATE/env}"
mkdir -p "$STATE"
LOG="$STATE/cloudflared.log"
MCP_LOG="$STATE/mcp.log"
URL_FILE="$STATE/connector.url"
PID_MCP="$STATE/mcp.pid"
PID_CF="$STATE/cloudflared.pid"

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  set -a && source "$ENV_FILE" && set +a
  LISTEN="${ORACLE_MCP_HOST:-$LISTEN}"
  PORT="${ORACLE_MCP_PORT:-$PORT}"
fi

stop_old() {
  for f in "$PID_MCP" "$PID_CF"; do
    if [[ -f "$f" ]]; then
      kill "$(cat "$f")" 2>/dev/null || true
      rm -f "$f"
    fi
  done
  for p in $(lsof -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true); do
    if [[ "$(ps -o user= -p "$p" 2>/dev/null | awk '{print $1}')" == "$(id -un)" ]]; then
      kill "$p" 2>/dev/null || true
    fi
  done
}

extract_host() {
  grep -Eo 'https://[a-z0-9-]+\.trycloudflare\.com' "$LOG" 2>/dev/null | tail -n 1 || true
}

command -v cloudflared >/dev/null || {
  echo "install cloudflared: brew install cloudflare/cloudflare/cloudflared"
  exit 1
}
command -v uvx >/dev/null || {
  echo "install uv: curl -LsSf https://astral.sh/uv/install.sh | sh"
  exit 1
}

stop_old
: > "$LOG"
: > "$MCP_LOG"
rm -f "$URL_FILE"

export ORACLE_MCP_HOST="$LISTEN"
export ORACLE_MCP_PORT="$PORT"
export OCI_CONFIG_PROFILE="${OCI_CONFIG_PROFILE:-DEFAULT}"
export FASTMCP_LOG_LEVEL="${FASTMCP_LOG_LEVEL:-INFO}"
export ORACLE_MCP_BASE_URL="${ORACLE_MCP_BASE_URL:-http://${LISTEN}:${PORT}}"

nohup env ORACLE_MCP_HOST="$LISTEN" ORACLE_MCP_PORT="$PORT" \
  ORACLE_MCP_BASE_URL="$ORACLE_MCP_BASE_URL" \
  OCI_CONFIG_PROFILE="$OCI_CONFIG_PROFILE" \
  OCI_REGION="${OCI_REGION:-}" \
  ${IDCS_DOMAIN:+IDCS_DOMAIN="$IDCS_DOMAIN"} \
  ${IDCS_CLIENT_ID:+IDCS_CLIENT_ID="$IDCS_CLIENT_ID"} \
  ${IDCS_CLIENT_SECRET:+IDCS_CLIENT_SECRET="$IDCS_CLIENT_SECRET"} \
  ${IDCS_AUDIENCE:+IDCS_AUDIENCE="$IDCS_AUDIENCE"} \
  uvx oracle.oci-cloud-mcp-server \
  >"$MCP_LOG" 2>&1 &
echo $! > "$PID_MCP"
sleep 1.2
if ! kill -0 "$(cat "$PID_MCP")" 2>/dev/null; then
  echo "MCP failed to start"; cat "$MCP_LOG"; exit 1
fi
if grep -qi "transport 'stdio'" "$MCP_LOG"; then
  echo "WARN: still stdio — HTTP env not picked up. Check $MCP_LOG"
fi

nohup cloudflared tunnel --no-autoupdate --url "http://${LISTEN}:${PORT}" \
  >"$LOG" 2>&1 &
echo $! > "$PID_CF"

echo "Waiting up to ${WAIT_SECS}s for trycloudflare hostname..."
HOST=""
for _ in $(seq 1 "$WAIT_SECS"); do
  HOST="$(extract_host || true)"
  if [[ -n "$HOST" ]]; then
    break
  fi
  sleep 1
done

if [[ -z "$HOST" ]]; then
  echo "FAIL: no trycloudflare host in $LOG"
  tail -n 20 "$LOG"
  exit 1
fi

URL="${HOST}/mcp"
printf '%s\n' "$URL" > "$URL_FILE"
printf 'GROK_CONNECTOR_URL=%s\n' "$URL"
echo "$URL" | pbcopy 2>/dev/null || true
echo "Stop: stop-oci-grok-stack"
echo "PIDs: mcp=$(cat "$PID_MCP") cloudflared=$(cat "$PID_CF")"
echo "Logs: $MCP_LOG  $LOG"
echo "User: $(id -un)  state: $STATE"
