#!/usr/bin/env bash


roblox_curl() {
  curl -s \
    --connect-timeout 5 \
    --max-time 15 \
    -A "Samu-Recon/1.0" \
    -H "Accept: application/json" \
    "$@"
}

roblox_json_string() {
  local json="$1"
  local key="$2"

  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" |
      jq -r --arg key "$key" '.[$key] // empty' 2>/dev/null |
      head -n 1
  else
    printf '%s' "$json" |
      grep -oP "\"${key}\"[[:space:]]*:[[:space:]]*\"\\K[^\"]*" |
      head -n 1
  fi
}

roblox_json_number() {
  local json="$1"
  local key="$2"

  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" |
      jq -r --arg key "$key" '.[$key] // empty' 2>/dev/null |
      head -n 1
  else
    printf '%s' "$json" |
      grep -oP "\"${key}\"[[:space:]]*:[[:space:]]*\\K[0-9]+" |
      head -n 1
  fi
}

roblox_json_bool() {
  local json="$1"
  local key="$2"

  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" |
      jq -r --arg key "$key" '.[$key] // false' 2>/dev/null |
      head -n 1
  else
    if printf '%s' "$json" | grep -qP "\"${key}\"[[:space:]]*:[[:space:]]*true"; then
      printf 'true'
    else
      printf 'false'
    fi
  fi
}

lookup_roblox_user_by_username() {
  local username="$1"
  local payload

  payload=$(printf '{"usernames":["%s"],"excludeBannedUsers":false}' "$username")

  roblox_curl \
    -X POST \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "https://users.roblox.com/v1/usernames/users"
}

lookup_roblox_user_by_id() {
  local user_id="$1"

  roblox_curl \
    "https://users.roblox.com/v1/users/${user_id}"
}

lookup_roblox_avatar_headshot() {
  local user_id="$1"

  roblox_curl \
    "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=${user_id}&size=420x420&format=Png&isCircular=false"
}

lookup_roblox_friend_count() {
  local user_id="$1"

  roblox_curl \
    "https://friends.roblox.com/v1/users/${user_id}/friends/count"
}

lookup_roblox_followers_count() {
  local user_id="$1"

  roblox_curl \
    "https://friends.roblox.com/v1/users/${user_id}/followers/count"
}

lookup_roblox_followings_count() {
  local user_id="$1"

  roblox_curl \
    "https://friends.roblox.com/v1/users/${user_id}/followings/count"
}

lookup_roblox_friends() {
  local user_id="$1"

  roblox_curl \
    "https://friends.roblox.com/v1/users/${user_id}/friends"
}

lookup_roblox_groups() {
  local user_id="$1"

  roblox_curl \
    "https://groups.roblox.com/v2/users/${user_id}/groups/roles"
}

lookup_roblox_badges() {
  local user_id="$1"

  roblox_curl \
    "https://badges.roblox.com/v1/users/${user_id}/badges?limit=25&sortOrder=Desc"
}

lookup_roblox_games_created() {
  local user_id="$1"

  roblox_curl \
    "https://games.roblox.com/v2/users/${user_id}/games?accessFilter=Public&limit=25&sortOrder=Desc"
}

lookup_roblox_social_links() {
  local user_id="$1"

  roblox_curl \
    "https://accountinformation.roblox.com/v1/users/${user_id}/promotion-channels"
}

roblox_print_json_count() {
  local label="$1"
  local json="$2"
  local count

  if command -v jq >/dev/null 2>&1; then
    count=$(printf '%s' "$json" | jq -r '.count // (.data | length) // empty' 2>/dev/null)
  else
    count=$(roblox_json_number "$json" "count")
  fi

  [[ -z "$count" ]] && count="N/D"
  print_field "$label" "$count"
}

run_roblox_lookup() {
  local target="$1"
  local search_json
  local user_id
  local user_json
  local avatar_json
  local friends_json
  local followers_json
  local followings_json
  local groups_json
  local badges_json
  local games_json
  local socials_json
  local value

  if [[ -z "$target" ]]; then
    print_error "Username Roblox vuoto"
    return 1
  fi

  print_loading "Ricerca username Roblox"
  search_json=$(lookup_roblox_user_by_username "$target")

  if command -v jq >/dev/null 2>&1; then
    user_id=$(printf '%s' "$search_json" | jq -r '.data[0].id // empty' 2>/dev/null)
  else
    user_id=$(printf '%s' "$search_json" | grep -oP '"id"[[:space:]]*:[[:space:]]*\K[0-9]+' | head -n 1)
  fi

  if [[ -z "$user_id" ]]; then
    print_error "Utente Roblox non trovato"
    return 1
  fi

  print_done "Utente Roblox trovato"
  print_field "User ID" "$user_id"
  print_field "Profilo" "https://www.roblox.com/users/${user_id}/profile"

  print_separator
  print_loading "Recupero profilo pubblico"
  user_json=$(lookup_roblox_user_by_id "$user_id")

  value=$(roblox_json_string "$user_json" "name")
  [[ -n "$value" ]] && print_field "Username" "$value"

  value=$(roblox_json_string "$user_json" "displayName")
  [[ -n "$value" ]] && print_field "Display name" "$value"

  value=$(roblox_json_string "$user_json" "description")
  [[ -n "$value" ]] && print_field "Descrizione pubblica" "$value"

  value=$(roblox_json_string "$user_json" "created")
  [[ -n "$value" ]] && print_field "Account creato" "$value"

  value=$(roblox_json_bool "$user_json" "isBanned")
  print_field "Account bannato" "$value"

  value=$(roblox_json_bool "$user_json" "hasVerifiedBadge")
  print_field "Badge verificato" "$value"

  print_separator
  print_loading "Recupero avatar pubblico"
  avatar_json=$(lookup_roblox_avatar_headshot "$user_id")

  if command -v jq >/dev/null 2>&1; then
    value=$(printf '%s' "$avatar_json" | jq -r '.data[0].imageUrl // empty' 2>/dev/null)
  else
    value=$(roblox_json_string "$avatar_json" "imageUrl")
  fi

  [[ -n "$value" ]] && print_field "Avatar URL" "$value"

  print_separator
  print_loading "Recupero contatori pubblici"

  friends_json=$(lookup_roblox_friend_count "$user_id")
  followers_json=$(lookup_roblox_followers_count "$user_id")
  followings_json=$(lookup_roblox_followings_count "$user_id")

  roblox_print_json_count "Amici" "$friends_json"
  roblox_print_json_count "Follower" "$followers_json"
  roblox_print_json_count "Following" "$followings_json"

  print_separator
  print_loading "Recupero gruppi pubblici"
  groups_json=$(lookup_roblox_groups "$user_id")

  if command -v jq >/dev/null 2>&1; then
    value=$(printf '%s' "$groups_json" | jq -r '.data | length' 2>/dev/null)
  else
    value=""
  fi

  [[ -z "$value" ]] && value="N/D"
  print_field "Gruppi pubblici" "$value"

  print_separator
  print_loading "Recupero badge pubblici"
  badges_json=$(lookup_roblox_badges "$user_id")

  if command -v jq >/dev/null 2>&1; then
    value=$(printf '%s' "$badges_json" | jq -r '.data | length' 2>/dev/null)
  else
    value=""
  fi

  [[ -z "$value" ]] && value="N/D"
  print_field "Badge mostrati" "$value"

  print_separator
  print_loading "Recupero giochi creati pubblici"
  games_json=$(lookup_roblox_games_created "$user_id")

  if command -v jq >/dev/null 2>&1; then
    value=$(printf '%s' "$games_json" | jq -r '.data | length' 2>/dev/null)
  else
    value=""
  fi

  [[ -z "$value" ]] && value="N/D"
  print_field "Giochi pubblici mostrati" "$value"

  print_separator
  print_loading "Recupero social link pubblici"
  socials_json=$(lookup_roblox_social_links "$user_id")

  if command -v jq >/dev/null 2>&1; then
    value=$(printf '%s' "$socials_json" | jq -r '.promotionChannels | length // 0' 2>/dev/null)
  else
    value=""
  fi

  [[ -z "$value" ]] && value="N/D"
  print_field "Social link pubblici" "$value"

  print_separator
  print_done "Roblox public OSINT completato"

  if declare -F log_message >/dev/null 2>&1; then
    log_message "INFO" "Roblox lookup completato per ${target} (ID: ${user_id})"
  fi
}