#!/usr/bin/env bash
set -euo pipefail
STATE="${GROK_OCI_STATE:-$HOME/.grok/oci-stack}"
for f in "$STATE/mcp.pid" "$STATE/cloudflared.pid"; do
  if [[ -f "$f" ]]; then
    kill "$(cat "$f")" 2>/dev/null || true
    rm -f "$f"
  fi
done
echo "stopped oci grok stack"
