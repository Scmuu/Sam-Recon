#!/usr/bin/env bash

validate_email_api() {
  local email="$1"
  local api_key="${EMAILPROBER_API_KEY:-}"
  local startuphub_key="${STARTUPHUB_API_KEY:-}"

  if [[ -n "$api_key" ]]; then
    curl -s "https://emailprober.com/api/${email}?key=${api_key}"
  elif [[ -n "$startuphub_key" ]]; then
    curl -s "https://api.startuphub.ai/api/v1/email/validate?email=${email}&apikey=${startuphub_key}"
  else
    echo '{"error":"Nessuna API key configurata per email validation"}'
  fi
}