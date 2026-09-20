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
    local label="$1"
    local value="${2:-N/A}"
    printf '  %-22s: %s\n' "$label" "$value"
  }
fi

print_section() {
  local title="$1"
  print_separator
  printf '  %s\n' "$title"
  print_separator
}

# ------------------------------------------------------------
# JSON helper
# ------------------------------------------------------------

json_get_string() {
  local json="$1"
  local key="$2"

  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" |
      jq -r --arg key "$key" '.[$key] // empty' 2>/dev/null |
      head -n 1
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
    printf '%s' "$json" |
      jq -r --arg key "$key" '.[$key] // empty' 2>/dev/null |
      head -n 1
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
    printf '%s' "$json" |
      jq -r --arg key "$key" '.[0][$key] // empty' 2>/dev/null |
      head -n 1
  else
    printf '%s' "$json" |
      grep -oP "\"${key}\"[[:space:]]*:[[:space:]]*\"\\K[^\"]+" |
      head -n 1
  fi
}

# ------------------------------------------------------------
# API pubbliche
# ------------------------------------------------------------

lookup_username_github() {
  local username="$1"

  curl -s \
    --max-time 12 \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/users/${username}" \
    2>/dev/null || echo "{}"
}

lookup_username_gitlab() {
  local username="$1"

  curl -s \
    --max-time 12 \
    -H "Accept: application/json" \
    --get \
    --data-urlencode "username=${username}" \
    "https://gitlab.com/api/v4/users" \
    2>/dev/null || echo "[]"
}

lookup_username_reddit() {
  local username="$1"

  curl -s \
    --max-time 12 \
    -A "Samu-Recon/1.0" \
    -H "Accept: application/json" \
    "https://www.reddit.com/user/${username}/about.json" \
    2>/dev/null || echo "{}"
}

# ------------------------------------------------------------
# Mini Sherlock: controllo dei profili pubblici
# ------------------------------------------------------------

sherlock_check_url() {
  local url="$1"
  local code

  code=$(
    curl -L \
      -s \
      -o /dev/null \
      -w "%{http_code}" \
      --connect-timeout 5 \
      --max-time 10 \
      -A "Mozilla/5.0 (compatible; SamuRecon/1.0)" \
      "$url" 2>/dev/null
  )

  case "$code" in
    200)
      printf 'FOUND'
      ;;
    301|302|303|307|308)
      printf 'REDIRECT'
      ;;
    403|429)
      printf 'CHECK_MANUALLY'
      ;;
    404)
      printf 'NOT_FOUND'
      ;;
    *)
      printf 'UNKNOWN'
      ;;
  esac
}

sherlock_print_result() {
  local output_file="$1"
  local platform="$2"
  local status="$3"
  local url="$4"

  printf '[%s] %s | %s\n' "$status" "$platform" "$url" >> "$output_file"

  case "$status" in
    FOUND)
      print_done "${platform}: pagina raggiungibile"
      print_field "URL" "$url"
      ;;
    REDIRECT)
      print_warn "${platform}: redirect, verifica manualmente"
      print_field "URL" "$url"
      ;;
    CHECK_MANUALLY)
      print_warn "${platform}: controllo limitato dal sito"
      print_field "URL" "$url"
      ;;
    NOT_FOUND)
      print_field "$platform" "Profilo non trovato"
      ;;
    *)
      print_field "$platform" "Risposta non verificabile"
      ;;
  esac
}

run_samu_sherlock() {
  local username="$1"
  local base_dir
  local results_dir
  local output_file

  local item
  local platform
  local template
  local url
  local status

  if [[ -z "$username" ]]; then
    print_error "Username vuoto per Sherlock"
    return 1
  fi

  base_dir="${SCRIPT_DIR:-$(pwd)}"
  results_dir="${base_dir}/results/sherlock"
  output_file="${results_dir}/${username}.txt"

  mkdir -p "$results_dir"
  : > "$output_file"

  print_section "SAMU SHERLOCK - USERNAME DISCOVERY"
  print_field "Username" "$username"
  print_field "File risultati" "$output_file"
  print_separator

  local -a sites=(
    "GitHub|https://github.com/{username}"
    "GitLab|https://gitlab.com/{username}"
    "Reddit|https://www.reddit.com/user/{username}/"
    "Instagram|https://www.instagram.com/{username}/"
    "X/Twitter|https://x.com/{username}"
    "TikTok|https://www.tiktok.com/@{username}"
    "Twitch|https://www.twitch.tv/{username}"
    "YouTube|https://www.youtube.com/@{username}"
    "Steam|https://steamcommunity.com/id/{username}/"
    "Pinterest|https://www.pinterest.com/{username}/"
    "Tumblr|https://{username}.tumblr.com/"
    "Medium|https://medium.com/@{username}"
    "Dev.to|https://dev.to/{username}"
    "Keybase|https://keybase.io/{username}"
    "SoundCloud|https://soundcloud.com/{username}"
    "Telegram|https://t.me/{username}"
    "Mastodon|https://mastodon.social/@{username}"
    "Patreon|https://www.patreon.com/{username}"
    "Ko-fi|https://ko-fi.com/{username}"
    "Flickr|https://www.flickr.com/people/{username}/"
    "Vimeo|https://vimeo.com/{username}"
    "Behance|https://www.behance.net/{username}"
    "Dribbble|https://dribbble.com/{username}"
    "DeviantArt|https://www.deviantart.com/{username}"
    "CodePen|https://codepen.io/{username}"
    "Replit|https://replit.com/@{username}"
    "Hacker News|https://news.ycombinator.com/user?id={username}"
    "Product Hunt|https://www.producthunt.com/@{username}"
  )

  for item in "${sites[@]}"; do
    platform="${item%%|*}"
    template="${item#*|}"

    # Qui viene sostituito {username} con quello digitato.
    url="${template//\{username\}/$username}"

    status=$(sherlock_check_url "$url")
    sherlock_print_result "$output_file" "$platform" "$status" "$url"
  done

  print_separator
  print_done "Samu Sherlock completato"
  print_field "Risultati salvati" "$output_file"
  print_field "Nota" "Un match indica solo che lo username risulta su un sito: non conferma l'identita della persona."
}

# ------------------------------------------------------------
# Exposure metadata
# ------------------------------------------------------------

lookup_breach_hudsonrock_detailed() {
  local username="$1"

  curl -s \
    --max-time 12 \
    -H "Accept: application/json" \
    --get \
    --data-urlencode "search_value=${username}" \
    "https://cavalier.hudsonrock.com/api/json/v2/osint/search" \
    2>/dev/null || echo "{}"
}

# ------------------------------------------------------------
# Funzione chiamata da recon.sh
# ------------------------------------------------------------

run_username_osint() {
  local username="$1"
  local github_json
  local gitlab_json
  local reddit_json
  local breach_json
  local value
  local exposure_count

  if [[ -z "$username" ]]; then
    print_error "Username vuoto"
    return 1
  fi

  # Questa riga passa sempre il valore inserito, ad esempio tei.rl.
  run_samu_sherlock "$username"

  print_section "USERNAME PROFILE DETAILS"

  # GitHub
  print_loading "GitHub API lookup"
  github_json=$(lookup_username_github "$username")

  if [[ "$github_json" == *'"login"'* ]] &&
     [[ "$github_json" != *'"message":"Not Found"'* ]]; then

    print_done "GitHub: utente trovato"

    value=$(json_get_string "$github_json" "login")
    [[ -n "$value" ]] && print_field "GitHub login" "$value"

    value=$(json_get_number "$github_json" "id")
    [[ -n "$value" ]] && print_field "GitHub ID" "$value"

    value=$(json_get_string "$github_json" "html_url")
    [[ -n "$value" ]] && print_field "GitHub URL" "$value"

    value=$(json_get_string "$github_json" "name")
    [[ -n "$value" ]] && print_field "Nome pubblico" "$value"

    value=$(json_get_string "$github_json" "company")
    [[ -n "$value" ]] && print_field "Azienda pubblica" "$value"

    value=$(json_get_string "$github_json" "location")
    [[ -n "$value" ]] && print_field "Localita pubblica" "$value"

    value=$(json_get_string "$github_json" "blog")
    [[ -n "$value" ]] && print_field "Sito/blog" "$value"

    value=$(json_get_string "$github_json" "twitter_username")
    [[ -n "$value" ]] && print_field "X pubblico" "@${value}"

    value=$(json_get_number "$github_json" "followers")
    [[ -n "$value" ]] && print_field "Followers" "$value"

    value=$(json_get_number "$github_json" "public_repos")
    [[ -n "$value" ]] && print_field "Repository pubblici" "$value"
  else
    print_field "GitHub" "Utente non trovato"
  fi

  print_separator

  # GitLab
  print_loading "GitLab API lookup"
  gitlab_json=$(lookup_username_gitlab "$username")

  if [[ "$gitlab_json" != "[]" ]] &&
     [[ "$gitlab_json" == *'"username"'* ]]; then

    print_done "GitLab: utente trovato"

    value=$(json_array_first_string "$gitlab_json" "username")
    [[ -n "$value" ]] && print_field "GitLab username" "$value"

    value=$(json_array_first_string "$gitlab_json" "name")
    [[ -n "$value" ]] && print_field "GitLab nome" "$value"

    value=$(json_array_first_string "$gitlab_json" "web_url")
    [[ -n "$value" ]] && print_field "GitLab URL" "$value"

    value=$(json_array_first_string "$gitlab_json" "bio")
    [[ -n "$value" ]] && print_field "GitLab bio" "$value"
  else
    print_field "GitLab" "Utente non trovato"
  fi

  print_separator

  # Reddit
  print_loading "Reddit API lookup"
  reddit_json=$(lookup_username_reddit "$username")

  if [[ "$reddit_json" == *'"display_name"'* ]] ||
     [[ "$reddit_json" == *'"name"'* ]]; then

    print_done "Reddit: utente trovato"

    value=$(json_get_string "$reddit_json" "display_name")
    [[ -z "$value" ]] && value=$(json_get_string "$reddit_json" "name")
    [[ -n "$value" ]] && print_field "Reddit username" "$value"

    value=$(json_get_number "$reddit_json" "link_karma")
    [[ -n "$value" ]] && print_field "Link karma" "$value"

    value=$(json_get_number "$reddit_json" "comment_karma")
    [[ -n "$value" ]] && print_field "Comment karma" "$value"

    print_field "Reddit URL" "https://www.reddit.com/user/${username}/"
  else
    print_field "Reddit" "Utente non trovato o risposta limitata"
  fi

  print_separator
  print_section "EXPOSURE METADATA"

  print_loading "Breach exposure lookup"
  breach_json=$(lookup_breach_hudsonrock_detailed "$username")
  exposure_count=$(json_get_number "$breach_json" "entries_count")

  if [[ -n "$exposure_count" ]] &&
     [[ "$exposure_count" =~ ^[0-9]+$ ]] &&
     (( exposure_count > 0 )); then

    print_warn "Sono presenti record di esposizione"
    print_field "Record exposure" "$exposure_count"
    print_field "Nota" "Mostrati solo metadati, senza password o credenziali."
  else
    print_field "Exposure lookup" "Nessun record verificabile"
  fi

  print_separator
  print_done "Username OSINT completato per: ${username}"

  if declare -F log_message >/dev/null 2>&1; then
    log_message "INFO" "Username OSINT completato per ${username}"
  fi
}