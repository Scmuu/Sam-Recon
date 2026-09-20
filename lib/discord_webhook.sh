#!/usr/bin/env bash

send_ip_discord_report() {
  local ip="$1"
  local webhook_url="${DISCORD_WEBHOOK_URL:-}"

  if [[ -z "$webhook_url" ]]; then
    return 1
  fi

  local payload
  payload=$(cat <<EOF
{
  "embeds": [
    {
      "title": "IP Recon - ${ip}",
      "color": 7506394,
      "fields": [
        {"name": "IP", "value": "${ip}", "inline": true}
      ],
      "footer": {"text": "samu-recon"}
    }
  ]
}
EOF
)

  curl -s -X POST "$webhook_url" \
    -H "Content-Type: application/json" \
    -d "$payload"
}