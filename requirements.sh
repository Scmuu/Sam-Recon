#!/usr/bin/env bash

# ============================================================
# Samu Recon - Installer requisiti multi-distro
# Supporta: Kali/Debian/Ubuntu, Fedora, Arch Linux
# ============================================================

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${ROOT_DIR}/.venv"
PYTHON_REQUIREMENTS="${ROOT_DIR}/requirements.txt"

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

find_python() {
  if command -v python3 >/dev/null 2>&1; then
    command -v python3
  elif command -v python >/dev/null 2>&1; then
    command -v python
  else
    return 1
  fi
}

install_apt() {
  print_info "Rilevato sistema apt: Debian, Ubuntu o Kali"

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
    python3-venv \
    jq
}

install_dnf() {
  print_info "Rilevato sistema dnf: Fedora"

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
    python3-virtualenv \
    jq
}

install_pacman() {
  print_info "Rilevato sistema pacman: Arch Linux"

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
    jq
}

# ------------------------------------------------------------
# Installa requisiti di sistema
# ------------------------------------------------------------

if command -v apt >/dev/null 2>&1; then
  install_apt
elif command -v dnf >/dev/null 2>&1; then
  install_dnf
elif command -v pacman >/dev/null 2>&1; then
  install_pacman
else
  print_error "Gestore pacchetti non supportato."
  echo "Installa manualmente: bash curl grep sed gawk coreutils python3 pip jq"
  exit 1
fi

print_ok "Requisiti di sistema installati"

# ------------------------------------------------------------
# Trova Python
# ------------------------------------------------------------

PYTHON_BIN="$(find_python)" || {
  print_error "Python 3 non trovato dopo l'installazione"
  exit 1
}

print_ok "Python trovato: ${PYTHON_BIN}"

# ------------------------------------------------------------
# Crea requirements.txt se mancante
# ------------------------------------------------------------

if [[ ! -f "$PYTHON_REQUIREMENTS" ]]; then
  print_warn "requirements.txt non trovato: lo creo"

  cat > "$PYTHON_REQUIREMENTS" <<'EOF'
# Samu Recon - Dipendenze Python
phonenumbers>=8.13.0
EOF
fi

# ------------------------------------------------------------
# Ambiente virtuale e librerie Python
# ------------------------------------------------------------

if [[ ! -d "$VENV_DIR" ]]; then
  print_info "Creo ambiente virtuale Python: .venv"
  "$PYTHON_BIN" -m venv "$VENV_DIR"
else
  print_ok "Ambiente virtuale già presente: .venv"
fi

# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"

print_info "Aggiorno pip"
python -m pip install --upgrade pip setuptools wheel

print_info "Installo dipendenze Python"
python -m pip install -r "$PYTHON_REQUIREMENTS"

if python -c "import phonenumbers" >/dev/null 2>&1; then
  print_ok "Libreria phonenumbers installata"
else
  print_error "phonenumbers non è installata"
  exit 1
fi

# ------------------------------------------------------------
# Cartelle e permessi
# ------------------------------------------------------------

mkdir -p \
  "${ROOT_DIR}/results" \
  "${ROOT_DIR}/results/sherlock"

if [[ -f "${ROOT_DIR}/recon.sh" ]]; then
  chmod +x "${ROOT_DIR}/recon.sh"
  print_ok "recon.sh è eseguibile"
else
  print_warn "recon.sh non trovato in ${ROOT_DIR}"
fi

chmod +x "${ROOT_DIR}/requirements.sh" 2>/dev/null || true

# ------------------------------------------------------------
# Verifica finale
# ------------------------------------------------------------

echo
print_info "Verifica comandi"

for command in bash curl grep sed awk jq; do
  if command -v "$command" >/dev/null 2>&1; then
    print_ok "${command}: $(command -v "$command")"
  else
    print_error "${command} mancante"
  fi
done

echo
echo "============================================================"
echo " Samu Recon: setup completato"
echo "============================================================"
echo
echo "Per avviare:"
echo
echo "  cd \"${ROOT_DIR}\""
echo "  source .venv/bin/activate"
echo "  ./recon.sh"
echo