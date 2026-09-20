#!/usr/bin/env bash

if ! declare -F print_separator >/dev/null 2>&1; then
  print_separator() {
    printf '\n────────────────────────────────────────\n'
  }
fi

if ! declare -F print_done >/dev/null 2>&1; then
  print_done() {
    printf '[DONE] %s\n' "$1"
  }
fi

if ! declare -F print_warn >/dev/null 2>&1; then
  print_warn() {
    printf '[!] %s\n' "$1"
  }
fi

if ! declare -F print_error >/dev/null 2>&1; then
  print_error() {
    printf '[ERROR] %s\n' "$1"
  }
fi

if ! declare -F print_loading >/dev/null 2>&1; then
  print_loading() {
    printf '[*] %s\n' "$1"
  }
fi

if ! declare -F print_field >/dev/null 2>&1; then
  print_field() {
    printf '  %-24s: %s\n' "$1" "${2:-N/A}"
  }
fi

discord_print_section() {
  local title="$1"
  print_separator
  printf '  %s\n' "$title"
  print_separator
}

discord_is_valid_snowflake() {
  local user_id="$1"

  [[ "$user_id" =~ ^[0-9]{17,20}$ ]]
}

discord_json_string() {
  local json="$1"
  local key="$2"

  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" |
      jq -r --arg key "$key" '
        .[$key] //
        .user[$key] //
        .data[$key] //
        .data.user[$key] //
        empty
      ' 2>/dev/null |
      head -n 1
  else
    printf '%s' "$json" |
      grep -oP "\"${key}\"[[:space:]]*:[[:space:]]*\"\\K[^\"]*" |
      head -n 1
  fi
}

discord_json_bool() {
  local json="$1"
  local key="$2"

  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" |
      jq -r --arg key "$key" '
        .[$key] //
        .user[$key] //
        .data[$key] //
        .data.user[$key] //
        false
      ' 2>/dev/null |
      head -n 1
  else
    if printf '%s' "$json" | grep -qP "\"${key}\"[[:space:]]*:[[:space:]]*true"; then
      printf 'true'
    else
      printf 'false'
    fi
  fi
}

discord_json_number() {
  local json="$1"
  local key="$2"

  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" |
      jq -r --arg key "$key" '
        .[$key] //
        .user[$key] //
        .data[$key] //
        .data.user[$key] //
        empty
      ' 2>/dev/null |
      head -n 1
  else
    printf '%s' "$json" |
      grep -oP "\"${key}\"[[:space:]]*:[[:space:]]*\\K[0-9]+" |
      head -n 1
  fi
}

lookup_discord_user_by_id() {
  local user_id="$1"

  curl -s \
    --connect-timeout 5 \
    --max-time 12 \
    -A "Samu-Recon/1.0" \
    -H "Accept: application/json" \
    "https://discordlookup.mesalytic.moe/v1/user/${user_id}" \
    2>/dev/null || echo "{}"
}

discord_id_to_creation_timestamp() {
  local user_id="$1"

  if ! discord_is_valid_snowflake "$user_id"; then
    printf '0'
    return 1
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$user_id" <<'PY'
import sys
snowflake = int(sys.argv[1])
discord_epoch_ms = 1420070400000
print((snowflake >> 22) + discord_epoch_ms)
PY
  elif command -v python >/dev/null 2>&1; then
    python - "$user_id" <<'PY'
import sys
snowflake = int(sys.argv[1])
discord_epoch_ms = 1420070400000
print((snowflake >> 22) + discord_epoch_ms)
PY
  else
    printf '0'
    return 1
  fi
}

discord_id_to_creation_date() {
  local user_id="$1"
  local timestamp

  timestamp=$(discord_id_to_creation_timestamp "$user_id")

  if [[ "$timestamp" == "0" ]] || [[ -z "$timestamp" ]]; then
    printf 'N/A'
    return 1
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$timestamp" <<'PY'
import sys
from datetime import datetime, timezone
milliseconds = int(sys.argv[1])
created = datetime.fromtimestamp(milliseconds / 1000, tz=timezone.utc)
print(created.strftime("%Y-%m-%d %H:%M:%S UTC"))
PY
  elif command -v python >/dev/null 2>&1; then
    python - "$timestamp" <<'PY'
import sys
from datetime import datetime, timezone
milliseconds = int(sys.argv[1])
created = datetime.fromtimestamp(milliseconds / 1000, tz=timezone.utc)
print(created.strftime("%Y-%m-%d %H:%M:%S UTC"))
PY
  else
    printf 'N/A'
  fi
}

discord_id_to_account_age() {
  local user_id="$1"
  local timestamp

  timestamp=$(discord_id_to_creation_timestamp "$user_id")

  if [[ "$timestamp" == "0" ]] || [[ -z "$timestamp" ]]; then
    printf 'N/A'
    return 1
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 - "$timestamp" <<'PY'
import sys
from datetime import datetime, timezone
milliseconds = int(sys.argv[1])
created = datetime.fromtimestamp(milliseconds / 1000, tz=timezone.utc)
now = datetime.now(timezone.utc)
days = (now - created).days
years = days // 365
remaining_days = days % 365
print(f"{years} anni, {remaining_days} giorni")
PY
  elif command -v python >/dev/null 2>&1; then
    python - "$timestamp" <<'PY'
import sys
from datetime import datetime, timezone
milliseconds = int(sys.argv[1])
created = datetime.fromtimestamp(milliseconds / 1000, tz=timezone.utc)
now = datetime.now(timezone.utc)
days = (now - created).days
years = days // 365
remaining_days = days % 365
print(f"{years} anni, {remaining_days} giorni")
PY
  else
    printf 'N/A'
  fi
}

lookup_discord_avatar_url() {
  local user_id="$1"
  local avatar_hash="$2"

  if [[ -z "$avatar_hash" ]] || [[ "$avatar_hash" == "null" ]]; then
    printf ''
    return 1
  fi

  if [[ "$avatar_hash" == a_* ]]; then
    printf 'https://cdn.discordapp.com/avatars/%s/%s.gif?size=1024' \
      "$user_id" "$avatar_hash"
  else
    printf 'https://cdn.discordapp.com/avatars/%s/%s.png?size=1024' \
      "$user_id" "$avatar_hash"
  fi
}

lookup_discord_banner_url() {
  local user_id="$1"
  local banner_hash="$2"

  if [[ -z "$banner_hash" ]] || [[ "$banner_hash" == "null" ]]; then
    printf ''
    return 1
  fi

  if [[ "$banner_hash" == a_* ]]; then
    printf 'https://cdn.discordapp.com/banners/%s/%s.gif?size=1024' \
      "$user_id" "$banner_hash"
  else
    printf 'https://cdn.discordapp.com/banners/%s/%s.png?size=1024' \
      "$user_id" "$banner_hash"
  fi
}

discord_profile_url() {
  local user_id="$1"
  printf 'https://discord.com/users/%s' "$user_id"
}

discord_format_flags() {
  local flags="$1"

  if [[ -z "$flags" ]] || ! [[ "$flags" =~ ^[0-9]+$ ]]; then
    printf 'N/D'
    return 0
  fi

  local -a values=()

  (( flags & 1 )) && values+=("Discord Staff")
  (( flags & 2 )) && values+=("Partner")
  (( flags & 4 )) && values+=("HypeSquad Events")
  (( flags & 8 )) && values+=("Bug Hunter Level 1")
  (( flags & 64 )) && values+=("HypeSquad Bravery")
  (( flags & 128 )) && values+=("HypeSquad Brilliance")
  (( flags & 256 )) && values+=("HypeSquad Balance")
  (( flags & 512 )) && values+=("Early Supporter")
  (( flags & 16384 )) && values+=("Bug Hunter Level 2")
  (( flags & 131072 )) && values+=("Verified Bot")
  (( flags & 262144 )) && values+=("Early Verified Bot Developer")
  (( flags & 4194304 )) && values+=("Active Developer")

  if (( ${#values[@]} == 0 )); then
    printf 'Nessun badge pubblico rilevato'
  else
    local joined
    joined=$(IFS=', '; echo "${values[*]}")
    printf '%s' "$joined"
  fi
}

run_discord_lookup() {
  local user_id="$1"
  local json
  local value
  local avatar_hash
  local banner_hash
  local avatar_url
  local banner_url
  local flags
  local creation_date
  local account_age

  if [[ -z "$user_id" ]]; then
    print_error "Discord ID vuoto"
    return 1
  fi

  if ! discord_is_valid_snowflake "$user_id"; then
    print_error "Inserisci un Discord User ID numerico valido (17-20 cifre)"
    print_field "Nota" "Uno username Discord non consente un lookup pubblico affidabile senza API autorizzata."
    return 1
  fi

  discord_print_section "DISCORD PUBLIC LOOKUP"
  print_field "Discord User ID" "$user_id"
  print_field "Profilo Discord" "$(discord_profile_url "$user_id")"

  creation_date=$(discord_id_to_creation_date "$user_id")
  account_age=$(discord_id_to_account_age "$user_id")

  print_field "ID creato il" "$creation_date"
  print_field "Eta account" "$account_age"

  print_separator
  print_loading "Recupero metadata pubblici"

  json=$(lookup_discord_user_by_id "$user_id")

  if [[ -z "$json" ]] || [[ "$json" == "{}" ]] || [[ "$json" == "null" ]]; then
    print_warn "Fonte pubblica non disponibile o nessun dettaglio aggiuntivo"
    return 0
  fi

  value=$(discord_json_string "$json" "username")
  [[ -n "$value" ]] && print_field "Username" "$value"

  value=$(discord_json_string "$json" "global_name")
  [[ -n "$value" ]] && print_field "Display name" "$value"

  value=$(discord_json_string "$json" "discriminator")
  [[ -n "$value" ]] && print_field "Discriminator legacy" "$value"

  value=$(discord_json_bool "$json" "bot")
  [[ "$value" == "true" ]] && print_field "Tipo account" "Bot" || print_field "Tipo account" "Utente"

  value=$(discord_json_bool "$json" "system")
  [[ "$value" == "true" ]] && print_field "System account" "Si"

  flags=$(discord_json_number "$json" "public_flags")
  [[ -z "$flags" ]] && flags=$(discord_json_number "$json" "flags")

  if [[ -n "$flags" ]]; then
    print_field "Public flags" "$flags"
    print_field "Badge pubblici" "$(discord_format_flags "$flags")"
  fi

  avatar_hash=$(discord_json_string "$json" "avatar")
  avatar_url=$(lookup_discord_avatar_url "$user_id" "$avatar_hash")
  [[ -n "$avatar_url" ]] && print_field "Avatar URL" "$avatar_url"

  banner_hash=$(discord_json_string "$json" "banner")
  banner_url=$(lookup_discord_banner_url "$user_id" "$banner_hash")
  [[ -n "$banner_url" ]] && print_field "Banner URL" "$banner_url"

  value=$(discord_json_string "$json" "accent_color")
  [[ -n "$value" ]] && print_field "Accent color" "$value"

  value=$(discord_json_string "$json" "banner_color")
  [[ -n "$value" ]] && print_field "Banner color" "$value"

  print_separator
  print_done "Discord public lookup completato"

  if declare -F log_message >/dev/null 2>&1; then
    log_message "INFO" "Discord lookup completato per ID ${user_id}"
  fi
}