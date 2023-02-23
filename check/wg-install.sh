#!/bin/bash
bolors=$(curl -kLSs https://git.nicknet.works/Nackloose/Bolors/raw/branch/main/bolors.sh)
eval "$bolors"
echoc yellow "Checking for $(color cyan Wireguard)..."
if [[ -e /etc/wireguard/params ]]; then
    echoc cyan "Wireguard $(color green "Installed!")"
    exit 0
else
    echoc cyan "Wireguard $(color red "NOT Installed!")"
    exit 1
fi
