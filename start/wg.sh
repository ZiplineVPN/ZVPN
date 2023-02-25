#!/bin/bash
systemctl is-active --quiet "wg-quick@${WG_NIC}" &>/dev/null
if [[ $? -ne 0 ]]; then
    systemctl start "wg-quick@${WG_NIC}" &>/dev/null
    systemctl enable "wg-quick@${WG_NIC}" &>/dev/null
    exit "true"
fi
exit "false"
