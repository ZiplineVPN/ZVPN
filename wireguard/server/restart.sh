#!/bin/bash

# WireGuard Server Restart Tool
# Safely restarts the WireGuard server interface

# Default variables
WG_INTERFACE="wg0"
WG_CONFIG_DIR="/etc/wireguard"
LOCK_FILE="/var/run/zvpn_wg_restart.lock"

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
        echo "Error: Another restart operation is in progress"
        exit 1
    else
        # Clean up stale lock file
        rm -f "$LOCK_FILE"
    fi
fi

# Create lock file
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

echo "=== ZVPN WireGuard Server Restart ==="

# Check if interface exists
if ! ip link show "$WG_INTERFACE" &>/dev/null; then
    echo "Error: Interface $WG_INTERFACE does not exist"
    exit 1
fi

# Save current connections
echo "Saving current connection states..."
CONNECTIONS=$(wg show "$WG_INTERFACE" dump)

# Stop interface
echo "Stopping WireGuard interface..."
if ! wg-quick down "$WG_INTERFACE"; then
    echo "Error: Failed to stop WireGuard interface"
    exit 1
fi

# Small delay to ensure clean shutdown
sleep 2

# Start interface
echo "Starting WireGuard interface..."
if ! wg-quick up "$WG_INTERFACE"; then
    echo "Error: Failed to start WireGuard interface"
    echo "Attempting recovery..."
    wg-quick up "$WG_INTERFACE"
    if [ $? -ne 0 ]; then
        echo "Recovery failed. Manual intervention may be required."
        exit 1
    fi
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

echo "WireGuard interface successfully restarted"

# Compare connections
NEW_CONNECTIONS=$(wg show "$WG_INTERFACE" dump)
if [ "$CONNECTIONS" = "$NEW_CONNECTIONS" ]; then
    echo "All previous connections restored"
else
    echo "Warning: Connection state may have changed"
    echo "Run 'zvpn tools wireguard server status' to verify connections"
fi

exit 0 