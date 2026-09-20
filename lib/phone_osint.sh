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

phone_print_section() {
  local title="$1"
  print_separator
  printf '  %s\n' "$title"
  print_separator
}

normalize_phone() {
  local phone="$1"
  printf '%s' "$phone" | tr -d '[:space:]().-'
}

lookup_phone_hudsonrock() {
  local phone="$1"

  curl -s \
    --max-time 12 \
    -H "Accept: application/json" \
    --get \
    --data-urlencode "search_value=${phone}" \
    "https://cavalier.hudsonrock.com/api/json/v2/osint/search" \
    2>/dev/null || echo "{}"
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

phone_metadata() {
  local phone="$1"

  python3 - "$phone" <<'PY'
import sys

try:
    import phonenumbers
    from phonenumbers import (
        carrier,
        geocoder,
        timezone,
        PhoneNumberFormat,
        PhoneNumberType,
    )
except ImportError:
    print("ERROR=PHONENUMBERS_NOT_INSTALLED")
    raise SystemExit(0)

raw = sys.argv[1].strip()

try:
    parsed = phonenumbers.parse(raw, None)
except phonenumbers.NumberParseException as exc:
    print("ERROR=" + str(exc))
    raise SystemExit(0)

valid = phonenumbers.is_valid_number(parsed)
possible = phonenumbers.is_possible_number(parsed)

region = phonenumbers.region_code_for_number(parsed) or "N/A"
country_code = str(parsed.country_code)
international = phonenumbers.format_number(parsed, PhoneNumberFormat.INTERNATIONAL)
e164 = phonenumbers.format_number(parsed, PhoneNumberFormat.E164)
national = phonenumbers.format_number(parsed, PhoneNumberFormat.NATIONAL)

number_type = phonenumbers.number_type(parsed)
type_map = {
    PhoneNumberType.FIXED_LINE: "Fisso",
    PhoneNumberType.MOBILE: "Mobile",
    PhoneNumberType.FIXED_LINE_OR_MOBILE: "Fisso o mobile",
    PhoneNumberType.TOLL_FREE: "Numero verde",
    PhoneNumberType.PREMIUM_RATE: "Premium",
    PhoneNumberType.SHARED_COST: "Costo condiviso",
    PhoneNumberType.VOIP: "VoIP",
    PhoneNumberType.PERSONAL_NUMBER: "Numero personale",
    PhoneNumberType.PAGER: "Pager",
    PhoneNumberType.UAN: "UAN",
    PhoneNumberType.VOICEMAIL: "Segreteria",
    PhoneNumberType.UNKNOWN: "Sconosciuto",
}
type_label = type_map.get(number_type, "Sconosciuto")

location = geocoder.description_for_number(parsed, "it") or "N/D"
original_carrier = carrier.name_for_number(parsed, "it") or "N/D"
timezones = ", ".join(timezone.time_zones_for_number(parsed)) or "N/D"

print(f"VALID={'Si' if valid else 'No'}")
print(f"POSSIBLE={'Si' if possible else 'No'}")
print(f"COUNTRY_CODE=+{country_code}")
print(f"REGION={region}")
print(f"TYPE={type_label}")
print(f"INTERNATIONAL={international}")
print(f"E164={e164}")
print(f"NATIONAL={national}")
print(f"GEO={location}")
print(f"TIMEZONE={timezones}")
print(f"CARRIER={original_carrier}")
PY
}

run_phone_osint() {
  local input_phone="$1"
  local normalized_phone
  local metadata
  local line
  local key
  local value
  local breach_json
  local exposure_count

  if [[ -z "$input_phone" ]]; then
    print_error "Numero di telefono vuoto"
    return 1
  fi

  normalized_phone=$(normalize_phone "$input_phone")

  if [[ ! "$normalized_phone" =~ ^\+?[0-9]{6,15}$ ]]; then
    print_error "Formato numero non valido"
    print_field "Esempio" "+393331234567"
    return 1
  fi

  if [[ "$normalized_phone" != +* ]]; then
    print_warn "Usa il formato internazionale: ad esempio +393331234567"
  fi

  phone_print_section "PHONE NUMBER METADATA"
  print_field "Numero inserito" "$input_phone"
  print_field "Numero normalizzato" "$normalized_phone"
  print_separator

  print_loading "Analisi prefisso, tipo, area e carrier"

  metadata=$(phone_metadata "$normalized_phone")

  if [[ "$metadata" == *"ERROR=PHONENUMBERS_NOT_INSTALLED"* ]]; then
    print_error "Modulo Python phonenumbers non installato"
    print_field "Installa con" "python3 -m pip install --user phonenumbers"
  elif [[ "$metadata" == ERROR=* ]]; then
    print_error "Numero non analizzabile"
    print_field "Dettaglio" "${metadata#ERROR=}"
  else
    while IFS='=' read -r key value; do
      case "$key" in
        VALID)
          print_field "Numero valido" "$value"
          ;;
        POSSIBLE)
          print_field "Formato possibile" "$value"
          ;;
        COUNTRY_CODE)
          print_field "Prefisso paese" "$value"
          ;;
        REGION)
          print_field "Paese / regione" "$value"
          ;;
        TYPE)
          print_field "Tipo linea" "$value"
          ;;
        INTERNATIONAL)
          print_field "Formato internazionale" "$value"
          ;;
        E164)
          print_field "Formato E.164" "$value"
          ;;
        NATIONAL)
          print_field "Formato nazionale" "$value"
          ;;
        GEO)
          print_field "Area indicativa" "$value"
          ;;
        TIMEZONE)
          print_field "Fuso orario" "$value"
          ;;
        CARRIER)
          print_field "Gestore originario" "$value"
          ;;
      esac
    done <<< "$metadata"

    print_field "Nota carrier" "Potrebbe non essere il gestore attuale per via della portabilita."
    print_field "Nota geolocalizzazione" "Area da prefisso; non e GPS e non localizza il dispositivo."
  fi

  phone_print_section "EXPOSURE METADATA"
  print_loading "Breach exposure lookup"

  breach_json=$(lookup_phone_hudsonrock "$normalized_phone")
  exposure_count=$(json_get_number "$breach_json" "entries_count")

  if [[ -n "$exposure_count" ]] &&
     [[ "$exposure_count" =~ ^[0-9]+$ ]] &&
     (( exposure_count > 0 )); then

    print_warn "Sono presenti record di esposizione"
    print_field "Record exposure" "$exposure_count"
    print_field "Nota" "Mostrati solo metadati; nessuna password o credenziale."
  else
    print_field "Exposure lookup" "Nessun record verificabile"
  fi

  print_separator
  print_done "Phone OSINT completato per: ${normalized_phone}"

  if declare -F log_message >/dev/null 2>&1; then
    log_message "INFO" "Phone OSINT completato per ${normalized_phone}"
  fi
}