#!/bin/bash

# WireGuard Server Start Tool
# Starts the WireGuard server interface with proper checks

# Default variables
WG_INTERFACE="wg0"
WG_CONFIG_DIR="/etc/wireguard"
LOCK_FILE="/var/run/zvpn_wg_start.lock"

# Check if WireGuard is installed
if ! command -v wg >/dev/null 2>&1; then
    echo "Error: WireGuard is not installed"
    exit 1
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run as root"
    exit 1
fi

# Check for existing lock file
if [ -f "$LOCK_FILE" ]; then
    pid=$(cat "$LOCK_FILE")
    if kill -0 "$pid" 2>/dev/null; then
        echo "Error: Another start operation is in progress"
        exit 1
    else
        # Clean up stale lock file
        rm -f "$LOCK_FILE"
    fi
fi

# Create lock file
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

echo "=== ZVPN WireGuard Server Start ==="

# Check if interface already exists and is up
if ip link show "$WG_INTERFACE" &>/dev/null; then
    if ip link show "$WG_INTERFACE" | grep -q "UP"; then
        echo "WireGuard interface is already up and running"
        exit 0
    fi
fi

# Check if configuration exists
if [ ! -f "${WG_CONFIG_DIR}/${WG_INTERFACE}.conf" ]; then
    echo "Error: WireGuard configuration not found"
    echo "Please run 'zvpn tools wireguard server install' first"
    exit 1
fi

# Load parameters if they exist
if [ -f "${WG_CONFIG_DIR}/params" ]; then
    source "${WG_CONFIG_DIR}/params"
fi

# Start interface
echo "Starting WireGuard interface..."
if ! wg-quick up "$WG_INTERFACE"; then
    echo "Error: Failed to start WireGuard interface"
    exit 1
fi

# Verify interface is up
if ! ip link show "$WG_INTERFACE" | grep -q "UP"; then
    echo "Error: Interface failed to come up properly"
    exit 1
fi

# Check if configuration is loaded
if ! wg show "$WG_INTERFACE" >/dev/null 2>&1; then
    echo "Error: Interface is up but configuration is not loaded"
    exit 1
fi

# Enable the service for automatic startup
systemctl enable "wg-quick@${WG_INTERFACE}" &>/dev/null

# Get interface details
echo
echo "Interface Details:"
echo "-----------------"
ip -br addr show "$WG_INTERFACE"

# Show listening port and public key
echo
echo "Server Configuration:"
echo "-------------------"
wg show "$WG_INTERFACE" public-key | xargs echo "Public Key:"
wg show "$WG_INTERFACE" listen-port | xargs echo "Listening Port:"

echo
echo "WireGuard interface started successfully"
echo "Run 'zvpn tools wireguard server status' for more details"

exit 0 