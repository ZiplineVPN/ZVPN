#!/bin/bash
systemctl is-active --quiet "wg-quick@${WG_NIC}" &>/dev/null
if [[ $? -ne 0 ]]; then
    echo "false"
else
    echo "true"
fi
