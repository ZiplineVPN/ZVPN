#!/bin/bash

# WireGuard Uninstallation Tool
# Safely removes WireGuard server and all configurations

# Default variables
WG_CONFIG_DIR="/etc/wireguard"
WG_INTERFACE="wg0"
UNINSTALL_LOCK="/var/run/zvpn_wg_uninstall.lock"
CLIENT_DIR="/root/wg-clients"

# Function to check requirements
check_requirements() {
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        echo "Error: Please run as root"
        exit 1
    fi

    # Check if another uninstallation is in progress
    if [ -f "$UNINSTALL_LOCK" ]; then
        pid=$(cat "$UNINSTALL_LOCK")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Error: Another uninstallation is in progress"
            exit 1
        else
            rm -f "$UNINSTALL_LOCK"
        fi
    fi
}

# Function to create lock file
create_lock() {
    echo $$ > "$UNINSTALL_LOCK"
    trap 'rm -f "$UNINSTALL_LOCK"' EXIT
}

# Function to check if WireGuard is installed
check_installed() {
    if ! command -v wg >/dev/null 2>&1; then
        echo "WireGuard is not installed"
        exit 0
    fi
}

# Function to backup configurations
backup_configs() {
    if [ -d "$WG_CONFIG_DIR" ] || [ -d "$CLIENT_DIR" ]; then
        BACKUP_DIR="/root/wg-backup-$(date +%Y%m%d-%H%M%S)"
        echo "Creating backup at $BACKUP_DIR..."
        mkdir -p "$BACKUP_DIR"
        
        # Backup WireGuard configs
        if [ -d "$WG_CONFIG_DIR" ]; then
            cp -r "$WG_CONFIG_DIR" "$BACKUP_DIR/"
        fi
        
        # Backup client configs
        if [ -d "$CLIENT_DIR" ]; then
            cp -r "$CLIENT_DIR" "$BACKUP_DIR/"
        fi
        
        echo "Backup completed"
    fi
}

# Function to remove WireGuard
remove_wireguard() {
    echo "Stopping WireGuard service..."
    systemctl stop "wg-quick@${WG_INTERFACE}" 2>/dev/null
    systemctl disable "wg-quick@${WG_INTERFACE}" 2>/dev/null

    echo "Removing configurations..."
    rm -rf "$WG_CONFIG_DIR"
    rm -rf "$CLIENT_DIR"

    echo "Cleaning up system rules..."
    # Remove any remaining iptables rules
    iptables -D FORWARD -i "$WG_INTERFACE" -j ACCEPT 2>/dev/null
    iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null

    echo "Uninstalling WireGuard..."
    if command -v apt-get >/dev/null 2>&1; then
        apt-get purge -y wireguard wireguard-tools
        apt-get autoremove -y
    elif command -v yum >/dev/null 2>&1; then
        yum remove -y wireguard-tools
        yum autoremove -y
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Rns --noconfirm wireguard-tools
    fi
}

# Main uninstallation process
echo "=== ZVPN WireGuard Uninstallation ==="

check_requirements
create_lock
check_installed

echo "Starting WireGuard uninstallation..."

# Confirm uninstallation
read -p "This will remove WireGuard and all configurations. Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled"
    exit 1
fi

backup_configs
remove_wireguard

echo "WireGuard uninstallation completed successfully"
if [ -n "$BACKUP_DIR" ]; then
    echo "Your configurations have been backed up to: $BACKUP_DIR"
fi

exit 0 