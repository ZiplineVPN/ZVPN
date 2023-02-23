#!/bin/bash
bolors=$(curl -kLSs https://git.nicknet.works/Nackloose/Bolors/raw/branch/main/bolors.sh)
eval "$bolors"
echoc cyan "Checking for $(color yellow Wireguard)..."
if [[ -e /etc/wireguard/params ]]; then
    echoc yellow "Wireguard $(color green "Installed!")"
    exit 0
else
    echoc yellow "Wireguard $(color red "NOT Installed!")"
    exit 1
fi
