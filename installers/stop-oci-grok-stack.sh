#!/usr/bin/env bash
# Kill hidden MCP + cloudflared started by start-oci-grok-stack
# Run as your login user. Never sudo.
set -euo pipefail

if [[ "$(id -u)" -eq 0 ]]; then
  echo "Do not use sudo. Run as the same login user that started the stack."
  exit 1
fi

STATE="${GROK_OCI_STATE:-$HOME/.grok/oci-stack}"
PORT="${ORACLE_MCP_PORT:-8888}"
killed=0
ME="$(id -un)"

for name in mcp.pid cloudflared.pid; do
  f="$STATE/$name"
  if [[ -f "$f" ]]; then
    pid="$(cat "$f")"
    if kill "$pid" 2>/dev/null; then
      echo "killed $name PID=$pid"
      killed=1
    else
      echo "stale $name PID=$pid (already dead)"
    fi
    rm -f "$f"
  fi
done

for p in $(lsof -tiTCP:"$PORT" -sTCP:LISTEN 2>/dev/null || true); do
  owner="$(ps -o user= -p "$p" 2>/dev/null | awk '{print $1}')"
  if [[ "$owner" == "$ME" ]]; then
    echo "killed leftover :${PORT} PID=$p"
    kill "$p" 2>/dev/null || true
    killed=1
  fi
done

for p in $(pgrep -u "$ME" -f "cloudflared tunnel --url http://127.0.0.1:${PORT}" || true); do
  echo "killed leftover cloudflared PID=$p"
  kill "$p" 2>/dev/null || true
  killed=1
done

[[ "$killed" == "1" ]] || echo "nothing running"
echo "state: $STATE"
