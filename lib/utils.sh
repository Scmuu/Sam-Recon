#!/usr/bin/env bash

# Samu Recon - Utility functions

# Chiede conferma all'utente (y/N)
ask_confirm() {
  local question="$1"
  local response

  read -rp "${question} [y/N]: " response
  [[ "${response,,}" == "y" ]]
}

# Chiede un input all'utente, con opzione per valore di default
ask_input() {
  local prompt="$1"
  local default="${2:-}"
  local result

  if [[ -n "$default" ]]; then
    read -rp "${prompt} [${default}]: " result
    [[ -z "$result" ]] && result="$default"
  else
    read -rp "${prompt}: " result
  fi

  echo "$result"
}

# Stampa un separatore
print_separator() {
  echo -ne "${COLOR_PRIMARY}────────────────────────────────────────${COLOR_RESET}\n"
}

# Stampa un box semplice attorno a un testo
print_box() {
  local text="$1"
  local width=${2:-40}
  local line

  line=$(printf '─%.0s' $(seq 1 $width))

  echo -ne "${COLOR_PRIMARY}╭${line}╮${COLOR_RESET}\n"
  printf "${COLOR_PRIMARY}│${COLOR_RESET} %-${width}s ${COLOR_PRIMARY}│${COLOR_RESET}\n" "$text"
  echo -ne "${COLOR_PRIMARY}╰${line}╯${COLOR_RESET}\n"
}

# Estrae un campo da JSON grezzo (grep-based, semplice)
json_get() {
  local json="$1"
  local key="$2"

  echo "$json" | grep -o "\"${key}\":\"[^\"]*\"" | head -1 | cut -d'"' -f4
}

# Estrae un campo numerico da JSON grezzo
json_get_number() {
  local json="$1"
  local key="$2"

  echo "$json" | grep -o "\"${key}\":[0-9]*" | head -1 | cut -d':' -f2
}

# Estrae un campo booleano da JSON grezzo
json_get_bool() {
  local json="$1"
  local key="$2"

  if echo "$json" | grep -q "\"${key}\":true"; then
    echo "true"
  elif echo "$json" | grep -q "\"${key}\":false"; then
    echo "false"
  else
    echo "null"
  fi
}

# Controlla se un comando esiste
command_exists() {
  command -v "$1" &>/dev/null
}

# Controlla se python3 è disponibile
has_python3() {
  command_exists python3
}

# Controlla se jq è disponibile (per parsing JSON migliore)
has_jq() {
  command_exists jq
}

# Log semplice su file (opzionale)
log_message() {
  local level="$1"
  local message="$2"
  local log_file="${LOG_FILE:-./samu-recon.log}"

  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  echo "[${timestamp}] [${level}] ${message}" >> "$log_file"
}

# Stampa un messaggio di debug (solo se DEBUG=1)
debug_print() {
  [[ "${DEBUG:-0}" == "1" ]] && echo "[DEBUG] $*" >&2
}

# Converte un timestamp Unix in data leggibile (se python3 disponibile)
timestamp_to_date() {
  local ts="$1"

  if has_python3; then
    python3 -c "
from datetime import datetime
ts = int('$ts')
dt = datetime.utcfromtimestamp(ts)
print(dt.strftime('%Y-%m-%d %H:%M:%S UTC'))
"
  else
    echo "N/A (python3 required)"
  fi
}

# Converte millisecondi in data leggibile
timestamp_ms_to_date() {
  local ts_ms="$1"

  if has_python3; then
    python3 -c "
from datetime import datetime
ts_ms = int('$ts_ms')
dt = datetime.utcfromtimestamp(ts_ms / 1000.0)
print(dt.strftime('%Y-%m-%d %H:%M:%S UTC'))
"
  else
    echo "N/A (python3 required)"
  fi
}

# Pulisce lo schermo e stampa header
clear_and_header() {
  clear
  print_waifu_banner
  print_title
  echo
}

# Stampa un messaggio di caricamento
print_loading() {
  local message="$1"
  echo -ne "${COLOR_WARN}[...]${COLOR_RESET} ${message}\n"
}

# Stampa un messaggio di successo
print_done() {
  local message="$1"
  echo -ne "${COLOR_SUCCESS}[DONE]${COLOR_RESET} ${message}\n"
}