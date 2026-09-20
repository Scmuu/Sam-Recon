#!/usr/bin/env bash

COLOR_RESET="\e[0m"
COLOR_PRIMARY="\e[38;5;75m"
COLOR_SECONDARY="\e[38;5;198m"
COLOR_SUCCESS="\e[38;5;119m"
COLOR_WARN="\e[38;5;226m"
COLOR_ERROR="\e[38;5;196m"

print_title() {
  echo -ne "${COLOR_PRIMARY}╔════════════════════════════════════════╗${COLOR_RESET}\n"
  echo -ne "${COLOR_PRIMARY}║${COLOR_RESET}       SAMU RECON OSINT CLI         ${COLOR_PRIMARY}║${COLOR_RESET}\n"
  echo -ne "${COLOR_PRIMARY}╚════════════════════════════════════════╝${COLOR_RESET}\n"
}

print_mission() {
  local mission_name="$1"
  echo -ne "\n${COLOR_SECONDARY}[MISSION]${COLOR_RESET} ${COLOR_PRIMARY}${mission_name}${COLOR_RESET}\n"
}

print_field() {
  local label="$1"
  local value="$2"
  echo -ne "  ${COLOR_SECONDARY}${label}:${COLOR_RESET} ${value}\n"
}

print_success() {
  echo -ne "${COLOR_SUCCESS}[OK]${COLOR_RESET} $1\n"
}

print_error() {
  echo -ne "${COLOR_ERROR}[ERROR]${COLOR_RESET} $1\n"
}