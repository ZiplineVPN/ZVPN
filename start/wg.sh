#!/bin/bash
systemctl is-active --quiet "wg-quick@${WG_NIC}"
if [[ $? -ne 0 ]]; then
    systemctl start "wg-quick@${WG_NIC}"
    systemctl enable "wg-quick@${WG_NIC}"
    exit 0
fi
exit 1
