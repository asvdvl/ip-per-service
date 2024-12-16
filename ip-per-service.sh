#!/bin/bash

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <network_interface> <path_to_ips_file>"
    exit 1
fi

IFACE="$1"
IPS_FILE=$(cat "$2")

for IP in $IPS; do
    if ! ip -6 addr show dev "$IFACE" | grep -q "${IP%%/*}"; then
        ip -6 addr add "$IP" dev "$IFACE"
        echo "Added $IP"
    fi
done

missing=${#IPS}
until (( missing == 0 )); do
    present=0
    missing=0

    for IP in $IPS; do
        if ip -6 addr show dev "$IFACE" | grep -q "${IP%%/*}"; then
            let present++;
        else
            let missing++;
        fi
    done

    echo "missing $missing; present $present"
    sleep 1
done