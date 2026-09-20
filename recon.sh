#!/usr/bin/env bash


set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

LOG_FILE="${SCRIPT_DIR}/samu-recon.log"
touch "$LOG_FILE" 2>/dev/null || true

# ============================================================
# Import moduli presenti in lib/
# ============================================================

source "${SCRIPT_DIR}/lib/colors.sh"
source "${SCRIPT_DIR}/lib/utils.sh"
source "${SCRIPT_DIR}/lib/ascii_art.sh"

source "${SCRIPT_DIR}/lib/ip_lookup.sh"
source "${SCRIPT_DIR}/lib/domain_lookup.sh"
source "${SCRIPT_DIR}/lib/email_lookup.sh"

source "${SCRIPT_DIR}/lib/email_osint.sh"
source "${SCRIPT_DIR}/lib/username_osint.sh"
source "${SCRIPT_DIR}/lib/phone_osint.sh"

source "${SCRIPT_DIR}/lib/instagram_lookup.sh"
source "${SCRIPT_DIR}/lib/roblox_lookup.sh"
source "${SCRIPT_DIR}/lib/discord_lookup.sh"
source "${SCRIPT_DIR}/lib/discord_webhook.sh"

# ============================================================
# Fallback grafici
# ============================================================

if ! declare -F print_separator >/dev/null 2>&1; then
  print_separator() {
    printf '\n────────────────────────────────────────\n'
  }
fi

if ! declare -F print_loading >/dev/null 2>&1; then
  print_loading() {
    printf '[*] %s\n' "$1"
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

if ! declare -F print_field >/dev/null 2>&1; then
  print_field() {
    printf '  %-22s: %s\n' "$1" "${2:-N/A}"
  }
fi

if ! declare -F print_mission >/dev/null 2>&1; then
  print_mission() {
    printf '\n[MISSION] %s\n' "$1"
  }
fi

# ============================================================
# Utility
# ============================================================

log_message() {
  local level="$1"
  local message="$2"

  printf '[%s] [%s] %s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" \
    "$level" \
    "$message" >> "$LOG_FILE"
}

pause_screen() {
  echo
  read -rp "Premi INVIO per continuare..." _
}

valid_email() {
  [[ "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
}

valid_username() {
  [[ "$1" =~ ^[A-Za-z0-9._-]{2,64}$ ]]
}

valid_phone() {
  [[ "$1" =~ ^[+]?[0-9[:space:]().-]{6,25}$ ]]
}

valid_domain() {
  [[ "$1" =~ ^([A-Za-z0-9-]+\.)+[A-Za-z]{2,}$ ]]
}

valid_ip() {
  [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || [[ "$1" =~ : ]]
}

# ============================================================
# Banner
# ============================================================

show_main_banner() {
  clear 2>/dev/null || true

  if declare -F print_waifu_banner >/dev/null 2>&1; then
    print_waifu_banner
  elif declare -F print_samu_default >/dev/null 2>&1; then
    print_samu_default
  else
    echo "SAMU RECON"
  fi
}

show_module_banner() {
  local module="$1"

  clear 2>/dev/null || true

  case "$module" in
    ip)
      if declare -F print_samu_ip >/dev/null 2>&1; then
        print_samu_ip
      else
        show_main_banner
      fi
      ;;
    domain)
      if declare -F print_samu_domain >/dev/null 2>&1; then
        print_samu_domain
      else
        show_main_banner
      fi
      ;;
    email)
      if declare -F print_samu_email >/dev/null 2>&1; then
        print_samu_email
      else
        show_main_banner
      fi
      ;;
    username)
      if declare -F print_samu_username >/dev/null 2>&1; then
        print_samu_username
      else
        show_main_banner
      fi
      ;;
    phone)
      if declare -F print_samu_phone >/dev/null 2>&1; then
        print_samu_phone
      else
        show_main_banner
      fi
      ;;
    instagram)
      if declare -F print_samu_instagram >/dev/null 2>&1; then
        print_samu_instagram
      else
        show_main_banner
      fi
      ;;
    roblox)
      if declare -F print_samu_roblox >/dev/null 2>&1; then
        print_samu_roblox
      else
        show_main_banner
      fi
      ;;
    discord)
      if declare -F print_samu_discord >/dev/null 2>&1; then
        print_samu_discord
      else
        show_main_banner
      fi
      ;;
    *)
      show_main_banner
      ;;
  esac
}

# ============================================================
# Moduli
# ============================================================

run_ip_module() {
  local ip="$1"

  show_module_banner ip
  print_mission "IP Lookup"
  print_field "Target IP" "$ip"
  print_separator

  if declare -F run_ip_lookup >/dev/null 2>&1; then
    run_ip_lookup "$ip"
  else
    print_error "Funzione run_ip_lookup non trovata in lib/ip_lookup.sh"
  fi

  log_message "INFO" "IP lookup: ${ip}"
}

run_domain_module() {
  local domain="$1"

  show_module_banner domain
  print_mission "Domain Lookup"
  print_field "Target dominio" "$domain"
  print_separator

  if declare -F domain_lookup >/dev/null 2>&1; then
    domain_lookup "$domain"
  elif declare -F lookup_domain >/dev/null 2>&1; then
    lookup_domain "$domain"
  else
    print_error "Funzione dominio non trovata in lib/domain_lookup.sh"
  fi

  log_message "INFO" "Domain lookup: ${domain}"
}

run_email_lookup_module() {
  local email="$1"

  show_module_banner email
  print_mission "Email Lookup"
  print_field "Target email" "$email"
  print_separator

  if declare -F email_lookup >/dev/null 2>&1; then
    email_lookup "$email"
  elif declare -F lookup_email >/dev/null 2>&1; then
    lookup_email "$email"
  else
    print_error "Funzione email non trovata in lib/email_lookup.sh"
  fi

  log_message "INFO" "Email lookup: ${email}"
}

run_email_osint_module() {
  local email="$1"

  show_module_banner email
  print_mission "Email OSINT + Data Breach"
  print_field "Target email" "$email"
  print_separator

  if declare -F run_email_osint >/dev/null 2>&1; then
    run_email_osint "$email"
  else
    print_error "Funzione run_email_osint non trovata in lib/email_osint.sh"
  fi

  log_message "INFO" "Email OSINT: ${email}"
}

run_username_module() {
  local username="$1"

  show_module_banner username
  print_mission "Username OSINT + Data Breach"
  print_field "Target username" "$username"
  print_separator

  # Questa è la chiamata importante: passa il valore inserito.
  if declare -F run_username_osint >/dev/null 2>&1; then
    run_username_osint "$username"
  else
    print_error "Funzione run_username_osint non trovata in lib/username_osint.sh"
  fi

  log_message "INFO" "Username OSINT: ${username}"
}

run_phone_module() {
  local phone="$1"

  show_module_banner phone
  print_mission "Phone OSINT + Data Breach"
  print_field "Target phone" "$phone"
  print_separator

  if declare -F run_phone_osint >/dev/null 2>&1; then
    run_phone_osint "$phone"
  else
    print_error "Funzione run_phone_osint non trovata in lib/phone_osint.sh"
  fi

  log_message "INFO" "Phone OSINT: ${phone}"
}

run_instagram_module() {
  local username="$1"

  show_module_banner instagram
  print_mission "Instagram Lookup"
  print_field "Target username" "$username"
  print_separator

  if declare -F instagram_lookup >/dev/null 2>&1; then
    instagram_lookup "$username"
  elif declare -F lookup_instagram >/dev/null 2>&1; then
    lookup_instagram "$username"
  else
    print_error "Funzione Instagram non trovata in lib/instagram_lookup.sh"
  fi

  log_message "INFO" "Instagram lookup: ${username}"
}

run_roblox_module() {
  local username="$1"

  show_module_banner roblox
  print_mission "Roblox Lookup"
  print_field "Target username" "$username"
  print_separator

  if declare -F roblox_lookup >/dev/null 2>&1; then
    roblox_lookup "$username"
  elif declare -F lookup_roblox >/dev/null 2>&1; then
    lookup_roblox "$username"
  else
    print_error "Funzione Roblox non trovata in lib/roblox_lookup.sh"
  fi

  log_message "INFO" "Roblox lookup: ${username}"
}

run_discord_module() {
  local discord_id="$1"

  show_module_banner discord
  print_mission "Discord Public Lookup"
  print_field "Discord ID" "$discord_id"
  print_separator

  if declare -F run_discord_lookup >/dev/null 2>&1; then
    run_discord_lookup "$discord_id"
  else
    print_error "Funzione run_discord_lookup non trovata in lib/discord_lookup.sh"
  fi

  log_message "INFO" "Discord lookup: ${discord_id}"
}

run_webhook_module() {
  local webhook_target="$1"

  show_module_banner discord
  print_mission "Discord Webhook"
  print_field "Target" "Webhook configurato"
  print_separator

  if declare -F discord_webhook >/dev/null 2>&1; then
    discord_webhook "$webhook_target"
  elif declare -F run_discord_webhook >/dev/null 2>&1; then
    run_discord_webhook "$webhook_target"
  else
    print_error "Funzione webhook non trovata in lib/discord_webhook.sh"
  fi

  log_message "INFO" "Discord webhook controllato"
}

# ============================================================
# Menu OSINT
# ============================================================

osint_menu() {
  local choice
  local target

  while true; do
    show_module_banner username
    print_mission "OSINT / Data Breach / Account Correlation"
    print_separator
    echo "  1) Email OSINT + Breach"
    echo "  2) Username OSINT + Breach"
    echo "  3) Phone OSINT + Breach"
    echo "  4) Indietro"
    print_separator

    read -rp " [?] Scegli: " choice

    case "$choice" in
      1)
        read -rp " [?] Inserisci email: " target

        if ! valid_email "$target"; then
          print_error "Email non valida"
          pause_screen
          continue
        fi

        run_email_osint_module "$target"
        pause_screen
        ;;
      2)
        read -rp " [?] Inserisci username: " target

        if ! valid_username "$target"; then
          print_error "Username non valido"
          pause_screen
          continue
        fi

        run_username_module "$target"
        pause_screen
        ;;
      3)
        read -rp " [?] Inserisci numero di telefono: " target

        if ! valid_phone "$target"; then
          print_error "Numero di telefono non valido"
          pause_screen
          continue
        fi

        run_phone_module "$target"
        pause_screen
        ;;
      4)
        return
        ;;
      *)
        print_error "Scelta non valida"
        pause_screen
        ;;
    esac
  done
}

# ============================================================
# Menu principale
# ============================================================

main_menu() {
  local choice
  local target

  while true; do
    show_main_banner
    print_mission "Samu Recon - Main Menu"
    print_separator
    echo "  1) IP Lookup"
    echo "  2) Domain Lookup"
    echo "  3) Email Lookup"
    echo "  4) OSINT / Data Breach"
    echo "  5) Instagram Lookup"
    echo "  6) Roblox Lookup"
    echo "  7) Discord Lookup"
    echo "  8) Discord Webhook"
    echo "  9) Exit"
    print_separator

    read -rp " [?] Scegli modulo: " choice

    case "$choice" in
      1)
        read -rp " [?] Inserisci IP: " target

        if ! valid_ip "$target"; then
          print_error "IP non valido"
          pause_screen
          continue
        fi

        run_ip_module "$target"
        pause_screen
        ;;
      2)
        read -rp " [?] Inserisci dominio: " target

        if ! valid_domain "$target"; then
          print_error "Dominio non valido"
          pause_screen
          continue
        fi

        run_domain_module "$target"
        pause_screen
        ;;
      3)
        read -rp " [?] Inserisci email: " target

        if ! valid_email "$target"; then
          print_error "Email non valida"
          pause_screen
          continue
        fi

        run_email_lookup_module "$target"
        pause_screen
        ;;
      4)
        osint_menu
        ;;
      5)
        read -rp " [?] Inserisci username Instagram: " target

        if ! valid_username "$target"; then
          print_error "Username non valido"
          pause_screen
          continue
        fi

        run_instagram_module "$target"
        pause_screen
        ;;
      6)
        read -rp " [?] Inserisci username Roblox: " target

        if ! valid_username "$target"; then
          print_error "Username non valido"
          pause_screen
          continue
        fi

        run_roblox_module "$target"
        pause_screen
        ;;
      7)
        read -rp " [?] Inserisci user ID Discord: " target

        if [[ -z "$target" ]]; then
          print_error "Target vuoto"
          pause_screen
          continue
        fi

        run_discord_module "$target"
        pause_screen
        ;;
      8)
        read -rp " [?] Inserisci webhook Discord: " target

        if [[ -z "$target" ]]; then
          print_error "Webhook vuoto"
          pause_screen
          continue
        fi

        run_webhook_module "$target"
        pause_screen
        ;;
      9)
        print_done "Samu Recon chiuso."
        log_message "INFO" "Applicazione chiusa"
        exit 0
        ;;
      *)
        print_error "Scelta non valida"
        pause_screen
        ;;
    esac
  done
}

main_menu