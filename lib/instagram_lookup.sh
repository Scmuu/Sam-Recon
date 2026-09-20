#!/usr/bin/env bash

lookup_instagram_profile() {
  local username="$1"

  local url="https://www.instagram.com/${username}/"
  local html
  html=$(curl -s -L -A "Mozilla/5.0" "$url")

  if echo "$html" | grep -q "Page Not Found"; then
    echo '{"exists":false}'
    return 1
  fi

  local json_match
  json_match=$(echo "$html" | grep -o '<script type="text/json" id="rawAndMetaTags">[^<]*</script>' | \
    sed 's/<script type="text\/json" id="rawAndMetaTags">//;s/<\/script>//' | head -1)

  if [[ -z "$json_match" ]]; then
    echo '{"exists":true,"note":"profilo esiste ma parsing non implementato"}'
    return 0
  fi
  echo "$json_match"
}