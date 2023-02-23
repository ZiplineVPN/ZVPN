#!/bin/bash
bolors=$(curl -kLSs https://git.nicknet.works/Nackloose/Bolors/raw/branch/main/bolors.sh)
eval "$bolors"
echoc green "Checking for $(color red Wireguard)...")}"
if [[ -e /etc/wireguard/params ]]; then
    echo "Wireguard Installed."
    exit 0
else
    echo "Wireguard Not Installed."
    exit 1
fi
