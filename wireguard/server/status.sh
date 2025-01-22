#!/bin/bash

# WireGuard Server Status Tool
# Shows comprehensive server status

# Default variables
WG_INTERFACE="wg0"
WG_CONFIG_DIR="/etc/wireguard"

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

# Print header
echo "=== ZVPN WireGuard Server Status ==="

# Check if interface exists
if ! ip link show "$WG_INTERFACE" &>/dev/null; then
    echo "Status: Interface $WG_INTERFACE does not exist"
    exit 1
fi

# Get interface status
if ip link show "$WG_INTERFACE" | grep -q "UP"; then
    echo "Interface Status: UP"
else
    echo "Interface Status: DOWN"
fi

# Get interface details
echo
echo "Interface Details:"
echo "-----------------"
ip -br addr show "$WG_INTERFACE"

# Get listening port and server public key
echo
echo "Server Configuration:"
echo "-------------------"
wg show "$WG_INTERFACE" public-key | xargs echo "Public Key:"
wg show "$WG_INTERFACE" listen-port | xargs echo "Listening Port:"

# Get interface statistics
echo
echo "Network Statistics:"
echo "-----------------"
rx_bytes=$(cat "/sys/class/net/$WG_INTERFACE/statistics/rx_bytes" 2>/dev/null)
tx_bytes=$(cat "/sys/class/net/$WG_INTERFACE/statistics/tx_bytes" 2>/dev/null)
if [ ! -z "$rx_bytes" ] && [ ! -z "$tx_bytes" ]; then
    echo "Total Received: $(numfmt --to=iec-i --suffix=B $rx_bytes)"
    echo "Total Sent: $(numfmt --to=iec-i --suffix=B $tx_bytes)"
fi

# Get active connections
echo
echo "Active Connections:"
echo "-----------------"
wg show "$WG_INTERFACE"

# Get system resources
echo
echo "System Resources:"
echo "---------------"
cpu_usage=$(ps -p $(pidof wg-crypt-wg0) -o %cpu= 2>/dev/null || echo "N/A")
mem_usage=$(ps -p $(pidof wg-crypt-wg0) -o %mem= 2>/dev/null || echo "N/A")
echo "CPU Usage: $cpu_usage%"
echo "Memory Usage: $mem_usage%"

exit 0 