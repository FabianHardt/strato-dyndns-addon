#!/usr/bin/with-contenv bashio

CERT_DIR=/data/letsencrypt
WORK_DIR=/data/workdir

# Let's encrypt
LE_UPDATE="0"

# StratoDynDNS
if bashio::config.has_value "ipv4"; then IPV4=$(bashio::config 'ipv4'); else IPV4=""; fi
if bashio::config.has_value "ipv6_interface_id"; then IPV6_IID=$(bashio::config 'ipv6_interface_id'); else IPV6_IID=""; fi
DOMAINS=$(bashio::config 'domains | join(",")')
WAIT_TIME=$(bashio::config 'seconds')
ALGO=$(bashio::config 'lets_encrypt.algo')
STRATO_USER=$(bashio::config 'stratoUserName')
STRATO_PASSWORD=$(bashio::config 'stratoPassword')


# Start nginx server
cp /share/nginx/nginx.conf /etc/nginx/http.d/default.conf
nginx

function expand_ipv6() {
    local ip="$1" left right out i
    local -a groups=() l=() r=()

    if [[ "${ip}" == *::* ]]; then
        left="${ip%%::*}"
        right="${ip#*::}"
        [[ -n "${left}" ]] && IFS=: read -ra l <<< "${left}"
        [[ -n "${right}" ]] && IFS=: read -ra r <<< "${right}"
        groups=("${l[@]}")
        for ((i = ${#l[@]} + ${#r[@]}; i < 8; i++)); do groups+=(0); done
        groups+=("${r[@]}")
    else
        IFS=: read -ra groups <<< "${ip}"
    fi

    [[ ${#groups[@]} -eq 8 ]] || return 1
    for i in "${groups[@]}"; do [[ "${i}" =~ ^[0-9a-fA-F]{1,4}$ ]] || return 1; done

    out=$(printf '%x:' "${groups[@]/#/0x}")
    echo "${out%:}"
}

# Current /64 prefix (detected via the host's public IPv6) combined with the configured interface ID
function build_ipv6() {
    local public iid
    public=$(expand_ipv6 "$(curl -6 -s -m 10 https://api6.ipify.org)") || return 1
    iid=$(expand_ipv6 "${IPV6_IID}") || return 1
    echo "$(cut -d: -f1-4 <<< "${public}"):$(cut -d: -f5-8 <<< "${iid}")"
}

# Function that performs a renew
function le_renew() {
    local domain_args=()
    local domains=''
    local aliases=''

    domains=$(bashio::config 'domains')

    # Prepare domain for Let's Encrypt
    for domain in ${domains}; do
        for alias in $(jq --raw-output --exit-status "[.aliases[]|{(.alias):.domain}]|add.\"${domain}\" | select(. != null)" /data/options.json) ; do
            aliases="${aliases} ${alias}"
        done
    done


    aliases="$(echo "${aliases}" | tr ' ' '\n' | sort | uniq)"

    bashio::log.info "Renew certificate for domains: $(echo -n "${domains}") and aliases: $(echo -n "${aliases}")"

    for domain in $(echo "${domains}" "${aliases}" | tr ' ' '\n' | sort | uniq); do
        domain_args+=("--domain" "${domain}")
    done

    dehydrated --cron --algo "${ALGO}" --hook ./hooks.sh --challenge http-01 "${domain_args[@]}" --out "${CERT_DIR}" --config "${WORK_DIR}/config" || true
    LE_UPDATE="$(date +%s)"
}

# Register/generate certificate if terms accepted
if bashio::config.true 'lets_encrypt.accept_terms'; then
    # Init folder structs
    mkdir -p "${CERT_DIR}"
    mkdir -p "${WORK_DIR}"

    # Clean up possible stale lock file
    if [ -e "${WORK_DIR}/lock" ]; then
        rm -f "${WORK_DIR}/lock"
        bashio::log.warning "Reset dehydrated lock file"
    fi

    # Generate new certs
    if [ ! -d "${CERT_DIR}/live" ]; then
        # Create empty dehydrated config file so that this dir will be used for storage
        touch "${WORK_DIR}/config"

        dehydrated --register --accept-terms --config "${WORK_DIR}/config"
    fi
fi

# Prepare WELLKNOWN="/share/www"
echo 'WELLKNOWN="/share/www"' > "${WORK_DIR}/config"

# Run StratoDynDNS
while true; do

    [[ ${IPV4} != *:/* ]] && ipv4=${IPV4} || ipv4=$(curl -s -m 10 "${IPV4}")
    myip=${ipv4}

    if [[ -n ${IPV6_IID} && ${ipv4} != none ]]; then
        # With an explicit IPv6 in myip, Strato no longer auto-detects IPv4, so it must be sent too
        [[ -z ${ipv4} ]] && ipv4=$(curl -4 -s -m 10 https://api.ipify.org)
        if ipv6=$(build_ipv6) && [[ ${ipv4} == *.* ]]; then
            myip="${ipv4},${ipv6}"
        else
            bashio::log.warning "IPv6 detection failed, updating IPv4 only"
            myip=${ipv4}
        fi
    fi

    if [[ -z ${myip} || ${myip} == *.* ]]; then
        if answer="$(curl -s -u "${STRATO_USER}:${STRATO_PASSWORD}" "https://dyndns.strato.com/nic/update?hostname=${DOMAINS}&myip=${myip}")" && [ "${answer}" != 'KO' ]; then
            if [[ "${answer}" == *NOCHANGE* ]]; then
   		bashio::log.debug "${answer}"
	    else
		bashio::log.info "${answer}"
      	    fi
        else
            bashio::log.warning "${answer}"
        fi
    fi

    now="$(date +%s)"
    if bashio::config.true 'lets_encrypt.accept_terms' && [ $((now - LE_UPDATE)) -ge 43200 ]; then
        le_renew
    fi

    sleep "${WAIT_TIME}"
done
