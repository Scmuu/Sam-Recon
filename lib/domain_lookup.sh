#!/usr/bin/env bash

lookup_domain_whois() {
  local domain="$1"
  local api_key="${WHOISJSON_API_KEY:-}"

  if [[ -z "$api_key" ]]; then
    curl -s "https://api.whoisjson.com/v1/whois?domain=${domain}"
  else
    curl -s "https://api.whoisjson.com/v1/whois?domain=${domain}&key=${api_key}"
  fi
}

lookup_domain_security_headers() {
  local url="$1"
  curl -s "https://www.ranknibbler.com/api/v1/security-headers?url=${url}"
}

lookup_domain_dns() {
  local domain="$1"
  local records=("A" "MX" "TXT" "NS")
  local result="{"

  for type in "${records[@]}"; do
    local dns_json
    dns_json=$(curl -s "https://cloudflare-dns.com/dns-query?name=${domain}&type=${type}" \
      -H "accept: application/dns-json")
    result+="\"${type}\":${dns_json},"
  done

  result="${result%,}}" # rimuovi ultima virgola
  result+="}"
  echo "$result"
}