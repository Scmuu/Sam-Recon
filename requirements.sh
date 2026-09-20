#!/usr/bin/env bash

# ============================================================
# Samu Recon - Installer requisiti multi-distro
# Kali/Debian/Ubuntu, Fedora, Arch Linux
# ============================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_ok() {
  printf '[OK] %s\n' "$1"
}

print_info() {
  printf '[*] %s\n' "$1"
}

print_warn() {
  printf '[!] %s\n' "$1"
}

print_error() {
  printf '[ERROR] %s\n' "$1"
}

install_apt() {
  print_info "Sistema rilevato: Kali / Debian / Ubuntu"

  sudo apt update

  sudo apt install -y \
    bash \
    curl \
    grep \
    sed \
    gawk \
    coreutils \
    ca-certificates \
    python3 \
    python3-pip \
    jq \
    python3-phonenumbers
}

install_dnf() {
  print_info "Sistema rilevato: Fedora"

  sudo dnf install -y \
    bash \
    curl \
    grep \
    sed \
    gawk \
    coreutils \
    ca-certificates \
    python3 \
    python3-pip \
    jq \
    python3-phonenumbers
}

install_pacman() {
  print_info "Sistema rilevato: Arch Linux"

  sudo pacman -Syu --needed \
    bash \
    curl \
    grep \
    sed \
    gawk \
    coreutils \
    ca-certificates \
    python \
    python-pip \
    jq \
    python-phonenumbers
}

if command -v apt >/dev/null 2>&1; then
  install_apt
elif command -v dnf >/dev/null 2>&1; then
  install_dnf
elif command -v pacman >/dev/null 2>&1; then
  install_pacman
else
  print_error "Gestore pacchetti non supportato."
  echo "Installa manualmente: bash curl grep sed gawk coreutils python3 pip jq phonenumbers"
  exit 1
fi

echo
print_info "Creo cartelle risultati..."

mkdir -p \
  "${ROOT_DIR}/results" \
  "${ROOT_DIR}/results/sherlock"

if [[ -f "${ROOT_DIR}/recon.sh" ]]; then
  chmod +x "${ROOT_DIR}/recon.sh"
  print_ok "recon.sh reso eseguibile"
else
  print_warn "recon.sh non trovato"
fi

chmod +x "${ROOT_DIR}/requirements.sh" 2>/dev/null || true

echo
print_info "Verifico comandi richiesti..."

for command in bash curl grep sed awk jq; do
  if command -v "$command" >/dev/null 2>&1; then
    print_ok "${command}: $(command -v "$command")"
  else
    print_error "${command} mancante"
  fi
done

echo
if python3 -c "import phonenumbers" >/dev/null 2>&1; then
  print_ok "Python phonenumbers installato"
elif python -c "import phonenumbers" >/dev/null 2>&1; then
  print_ok "Python phonenumbers installato"
else
  print_error "Python phonenumbers non trovato"
  exit 1
fi

echo
echo "============================================================"
echo " Samu Recon: requisiti installati"
echo "============================================================"
echo
echo "Avvio:"
echo
echo "  cd \"${ROOT_DIR}\""
echo "  ./recon.sh"
echo
