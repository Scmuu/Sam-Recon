#!/usr/bin/env bash

#!/usr/bin/env bash

# ============================================================
# Samu Recon - Email OSINT
# Fonti pubbliche e metadati di esposizione.
# ============================================================

lookup_email_gravatar() {
  local email="$1"
  local normalized
  local hash

  normalized=$(printf '%s' "$email" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
  hash=$(printf '%s' "$normalized" | md5sum | awk '{print $1}')

  curl -s \
    -A "Samu-Recon/1.0" \
    -H "Accept: application/json" \
    "https://en.gravatar.com/${hash}.json" \
    2>/dev/null || echo "{}"
}

lookup_email_github() {
  local email="$1"

  curl -s \
    -H "Accept: application/vnd.github+json" \
    --get \
    --data-urlencode "q=${email}" \
    "https://api.github.com/search/users" \
    2>/dev/null || echo "{}"
}

lookup_email_gitlab() {
  local email="$1"

  curl -s \
    -H "Accept: application/json" \
    --get \
    --data-urlencode "search=${email}" \
    "https://gitlab.com/api/v4/users" \
    2>/dev/null || echo "[]"
}

lookup_email_hudsonrock() {
  local email="$1"

  curl -s \
    -H "Accept: application/json" \
    --get \
    --data-urlencode "search_value=${email}" \
    "https://cavalier.hudsonrock.com/api/json/v2/osint/search" \
    2>/dev/null || echo "{}"
}

json_get_string() {
  local json="$1"
  local key="$2"

  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" | jq -r --arg key "$key" '.[$key] // empty' 2>/dev/null | head -n 1
  else
    printf '%s' "$json" |
      grep -oP "\"${key}\"[[:space:]]*:[[:space:]]*\"\\K[^\"]+" |
      head -n 1
  fi
}

json_get_number() {
  local json="$1"
  local key="$2"

  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" | jq -r --arg key "$key" '.[$key] // empty' 2>/dev/null | head -n 1
  else
    printf '%s' "$json" |
      grep -oP "\"${key}\"[[:space:]]*:[[:space:]]*\\K[0-9]+" |
      head -n 1
  fi
}

json_array_first_string() {
  local json="$1"
  local key="$2"

  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" | jq -r --arg key "$key" '.[0][$key] // empty' 2>/dev/null | head -n 1
  else
    printf '%s' "$json" |
      grep -oP "\"${key}\"[[:space:]]*:[[:space:]]*\"\\K[^\"]+" |
      head -n 1
  fi
}

run_email_osint() {
  local email="$1"
  local gravatar_json
  local github_json
  local gitlab_json
  local breach_json
  local value
  local github_total

  if [[ -z "$email" ]]; then
    print_error "Email vuota"
    return 1
  fi

  print_header "EMAIL OSINT + DATA BREACH"
  print_field "Target email" "$email"
  print_separator

  # ----------------------------------------------------------
  # Gravatar
  # ----------------------------------------------------------
  print_loading "Gravatar lookup"
  gravatar_json=$(lookup_email_gravatar "$email")

  if [[ "$gravatar_json" == *'"entry"'* ]]; then
    print_done "Gravatar: profilo pubblico trovato"

    value=$(json_get_string "$gravatar_json" "displayName")
    [[ -n "$value" ]] && print_field "Nome pubblico" "$value"

    value=$(json_get_string "$gravatar_json" "profileUrl")
    [[ -n "$value" ]] && print_field "Profilo pubblico" "$value"

    value=$(json_get_string "$gravatar_json" "thumbnailUrl")
    [[ -n "$value" ]] && print_field "Avatar URL" "$value"
  else
    print_field "Gravatar" "Nessun profilo pubblico"
  fi

  print_separator

  # ----------------------------------------------------------
  # GitHub
  # ----------------------------------------------------------
  print_loading "GitHub search"
  github_json=$(lookup_email_github "$email")
  github_total=$(json_get_number "$github_json" "total_count")

  if [[ -n "$github_total" ]] && [[ "$github_total" =~ ^[0-9]+$ ]] && (( github_total > 0 )); then
    print_done "GitHub: risultati pubblici trovati"
    print_field "Risultati GitHub" "$github_total"
  else
    print_field "GitHub" "Nessun risultato pubblico"
  fi

  print_separator

  # ----------------------------------------------------------
  # GitLab
  # ----------------------------------------------------------
  print_loading "GitLab search"
  gitlab_json=$(lookup_email_gitlab "$email")

  if [[ "$gitlab_json" != "[]" ]] && [[ "$gitlab_json" == *'"username"'* ]]; then
    print_done "GitLab: risultato pubblico trovato"

    value=$(json_array_first_string "$gitlab_json" "username")
    [[ -n "$value" ]] && print_field "GitLab username" "$value"

    value=$(json_array_first_string "$gitlab_json" "name")
    [[ -n "$value" ]] && print_field "GitLab nome pubblico" "$value"

    value=$(json_array_first_string "$gitlab_json" "web_url")
    [[ -n "$value" ]] && print_field "GitLab profilo" "$value"
  else
    print_field "GitLab" "Nessun risultato pubblico"
  fi

  print_separator

  # ----------------------------------------------------------
  # Exposure metadata
  # ----------------------------------------------------------
  print_header "EXPOSURE METADATA"
  print_loading "Breach exposure lookup"

  breach_json=$(lookup_email_hudsonrock "$email")

  if [[ -n "$breach_json" ]] && [[ "$breach_json" != "{}" ]] && [[ "$breach_json" != "null" ]]; then
    value=$(json_get_number "$breach_json" "entries_count")

    if [[ -n "$value" ]] && [[ "$value" =~ ^[0-9]+$ ]] && (( value > 0 )); then
      print_warn "Sono presenti record di esposizione"
      print_field "Record exposure" "$value"
      print_field "Nota" "Sono mostrati soltanto metadati, senza credenziali."
    else
      print_field "Exposure lookup" "Nessun record verificabile"
    fi
  else
    print_field "Exposure lookup" "Nessun record verificabile"
  fi

  print_separator
  print_done "Email OSINT completato per: ${email}"

  if declare -F log_message >/dev/null 2>&1; then
    log_message "INFO" "Email OSINT completato per ${email}"
  fi
}