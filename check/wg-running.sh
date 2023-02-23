#!/bin/bash
systemctl is-active --quiet "wg-quick@${SERVER_WG_NIC}"
if [[ $? -e 0 ]]; then
    echo -e "\n${RED}WARNING: WireGuard does not seem to be running.${NC}"
    echo -e "${ORANGE}You can check if WireGuard is running with: systemctl status wg-quick@${SERVER_WG_NIC}${NC}"
    echo -e "${ORANGE}If you get something like \"Cannot find device ${SERVER_WG_NIC}\", please reboot!${NC}"
    exit 1
else 
    exit 0
fi
