#!/bin/bash

# Load parameters
if [[ -e /etc/wireguard/params ]]; then
    source /etc/wireguard/params
else
    echo "No WireGuard installation found."
    exit 1
fi

# Function to remove WireGuard configuration and clean up
function uninstallWireGuard() {
    # Stop the WireGuard service
    systemctl stop "wg-quick@${WG_NIC}"
    systemctl disable "wg-quick@${WG_NIC}"

    # Remove WireGuard configuration files
    rm -f "/etc/wireguard/${WG_NIC}.conf"
    rm -f "/etc/wireguard/params"
    
    # Clean up any client configurations in the home directory
    rm -f "${HOME_DIR}/${WG_NIC}-client-"*

    # Remove the WireGuard directory if empty
    rmdir /etc/wireguard 2>/dev/null

    # Remove sysctl settings
    rm -f /etc/sysctl.d/wg.conf
    sysctl --system

    # Optionally, remove WireGuard and its dependencies
    apt-get purge -y wireguard iptables resolvconf qrencode
    apt-get autoremove -y

    echo "WireGuard uninstalled successfully."
}

# Run the uninstallation
uninstallWireGuard
