#!/usr/bin/env bash

lookup_ip_ipapi() {
  local ip="$1"
  local json
  local url

  if [[ -z "$ip" ]]; then
    return 1
  fi

  url="http://ip-api.com/json/${ip}?fields=status,message,query,continent,continentCode,country,countryCode,region,regionName,city,district,zip,lat,lon,timezone,isp,org,as,asname,reverse,mobile,proxy,hosting"

  json=$(
    curl -s \
      --connect-timeout 5 \
      --max-time 12 \
      -A "Samu-Recon/1.0" \
      "$url" \
      2>/dev/null
  )

  if [[ -z "$json" ]]; then
    return 1
  fi

  # Se jq è installato, è il parsing più affidabile.
  if command -v jq >/dev/null 2>&1; then
    local status

    status=$(printf '%s' "$json" | jq -r '.status // empty' 2>/dev/null)

    if [[ "$status" != "success" ]]; then
      return 1
    fi

    cat <<EOF
status=$(printf '%s' "$json" | jq -r '.status // empty')
query=$(printf '%s' "$json" | jq -r '.query // empty')
continent=$(printf '%s' "$json" | jq -r '.continent // empty')
continentCode=$(printf '%s' "$json" | jq -r '.continentCode // empty')
country=$(printf '%s' "$json" | jq -r '.country // empty')
countryCode=$(printf '%s' "$json" | jq -r '.countryCode // empty')
region=$(printf '%s' "$json" | jq -r '.region // empty')
regionName=$(printf '%s' "$json" | jq -r '.regionName // empty')
city=$(printf '%s' "$json" | jq -r '.city // empty')
district=$(printf '%s' "$json" | jq -r '.district // empty')
zip=$(printf '%s' "$json" | jq -r '.zip // empty')
lat=$(printf '%s' "$json" | jq -r '.lat // empty')
lon=$(printf '%s' "$json" | jq -r '.lon // empty')
timezone=$(printf '%s' "$json" | jq -r '.timezone // empty')
isp=$(printf '%s' "$json" | jq -r '.isp // empty')
org=$(printf '%s' "$json" | jq -r '.org // empty')
as=$(printf '%s' "$json" | jq -r '.as // empty')
asname=$(printf '%s' "$json" | jq -r '.asname // empty')
reverse=$(printf '%s' "$json" | jq -r '.reverse // empty')
mobile=$(printf '%s' "$json" | jq -r '.mobile // false')
proxy=$(printf '%s' "$json" | jq -r '.proxy // false')
hosting=$(printf '%s' "$json" | jq -r '.hosting // false')
EOF

    return 0
  fi

  # Fallback senza jq.
  local status
  status=$(printf '%s' "$json" | grep -oP '"status"\s*:\s*"\K[^"]+' | head -n 1)

  if [[ "$status" != "success" ]]; then
    return 1
  fi

  local query continent continentCode country countryCode
  local region regionName city district zip lat lon timezone
  local isp org as asname reverse mobile proxy hosting

  query=$(printf '%s' "$json" | grep -oP '"query"\s*:\s*"\K[^"]+' | head -n 1)
  continent=$(printf '%s' "$json" | grep -oP '"continent"\s*:\s*"\K[^"]+' | head -n 1)
  continentCode=$(printf '%s' "$json" | grep -oP '"continentCode"\s*:\s*"\K[^"]+' | head -n 1)
  country=$(printf '%s' "$json" | grep -oP '"country"\s*:\s*"\K[^"]+' | head -n 1)
  countryCode=$(printf '%s' "$json" | grep -oP '"countryCode"\s*:\s*"\K[^"]+' | head -n 1)
  region=$(printf '%s' "$json" | grep -oP '"region"\s*:\s*"\K[^"]+' | head -n 1)
  regionName=$(printf '%s' "$json" | grep -oP '"regionName"\s*:\s*"\K[^"]+' | head -n 1)
  city=$(printf '%s' "$json" | grep -oP '"city"\s*:\s*"\K[^"]+' | head -n 1)
  district=$(printf '%s' "$json" | grep -oP '"district"\s*:\s*"\K[^"]+' | head -n 1)
  zip=$(printf '%s' "$json" | grep -oP '"zip"\s*:\s*"\K[^"]+' | head -n 1)
  lat=$(printf '%s' "$json" | grep -oP '"lat"\s*:\s*\K-?[0-9.]+' | head -n 1)
  lon=$(printf '%s' "$json" | grep -oP '"lon"\s*:\s*\K-?[0-9.]+' | head -n 1)
  timezone=$(printf '%s' "$json" | grep -oP '"timezone"\s*:\s*"\K[^"]+' | head -n 1)
  isp=$(printf '%s' "$json" | grep -oP '"isp"\s*:\s*"\K[^"]+' | head -n 1)
  org=$(printf '%s' "$json" | grep -oP '"org"\s*:\s*"\K[^"]+' | head -n 1)
  as=$(printf '%s' "$json" | grep -oP '"as"\s*:\s*"\K[^"]+' | head -n 1)
  asname=$(printf '%s' "$json" | grep -oP '"asname"\s*:\s*"\K[^"]+' | head -n 1)
  reverse=$(printf '%s' "$json" | grep -oP '"reverse"\s*:\s*"\K[^"]+' | head -n 1)

  if printf '%s' "$json" | grep -qP '"mobile"\s*:\s*true'; then
    mobile="true"
  else
    mobile="false"
  fi

  if printf '%s' "$json" | grep -qP '"proxy"\s*:\s*true'; then
    proxy="true"
  else
    proxy="false"
  fi

  if printf '%s' "$json" | grep -qP '"hosting"\s*:\s*true'; then
    hosting="true"
  else
    hosting="false"
  fi

  cat <<EOF
status=${status}
query=${query}
continent=${continent}
continentCode=${continentCode}
country=${country}
countryCode=${countryCode}
region=${region}
regionName=${regionName}
city=${city}
district=${district}
zip=${zip}
lat=${lat}
lon=${lon}
timezone=${timezone}
isp=${isp}
org=${org}
as=${as}
asname=${asname}
reverse=${reverse}
mobile=${mobile}
proxy=${proxy}
hosting=${hosting}
EOF
}

run_ip_lookup() {
  local ip="$1"
  local results
  local line
  local key
  local value

  if [[ -z "$ip" ]]; then
    print_error "IP vuoto"
    return 1
  fi

  print_loading "Ricerca informazioni IP"

  results=$(lookup_ip_ipapi "$ip")

  if [[ -z "$results" ]]; then
    print_error "Nessun dato IP trovato o richiesta non riuscita"
    return 1
  fi

  print_done "Informazioni IP trovate"

  while IFS='=' read -r key value; do
    case "$key" in
      query) print_field "IP" "$value" ;;
      continent) print_field "Continente" "$value" ;;
      continentCode) print_field "Codice continente" "$value" ;;
      country) print_field "Paese" "$value" ;;
      countryCode) print_field "Codice paese" "$value" ;;
      region) print_field "Codice regione" "$value" ;;
      regionName) print_field "Regione" "$value" ;;
      city) print_field "Citta" "$value" ;;
      district) print_field "Distretto" "$value" ;;
      zip) print_field "CAP" "$value" ;;
      lat) print_field "Latitudine" "$value" ;;
      lon) print_field "Longitudine" "$value" ;;
      timezone) print_field "Fuso orario" "$value" ;;
      isp) print_field "ISP" "$value" ;;
      org) print_field "Organizzazione" "$value" ;;
      as) print_field "ASN" "$value" ;;
      asname) print_field "Nome ASN" "$value" ;;
      reverse) print_field "Reverse DNS" "$value" ;;
      mobile) print_field "Rete mobile" "$value" ;;
      proxy) print_field "Proxy/VPN/Tor" "$value" ;;
      hosting) print_field "Hosting/Datacenter" "$value" ;;
    esac
  done <<< "$results"

  print_field "Nota geolocalizzazione" "Stima dell'IP; non localizzazione GPS precisa."

  if declare -F log_message >/dev/null 2>&1; then
    log_message "INFO" "IP lookup completato per ${ip}"
  fi
}