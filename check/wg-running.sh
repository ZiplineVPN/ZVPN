#!/bin/bash
systemctl is-active --quiet "wg-quick@${SERVER_WG_NIC}"
if [[ $? -ne 0 ]]; then
    echoc cyan "$(color yellow "Wireguard") does $(color red "NOT appear") to be running."
    echoc red "You can check if WireGuard is running with: systemctl status wg-quick@${SERVER_WG_NIC}"
    echoc red_bright "If you get something like \"Cannot find device ${SERVER_WG_NIC}\", please reboot!"
    exit 1
else 
    exit 0
fi
