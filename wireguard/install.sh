#!/bin/bash

# WireGuard Installation Tool
# Performs idempotent installation of WireGuard server

# Default variables
WG_CONFIG_DIR="/etc/wireguard"
WG_INTERFACE="wg0"
INSTALL_LOCK="/var/run/zvpn_wg_install.lock"
CLIENT_DIR="/root/wg-clients"

# Function to check system requirements
check_requirements() {
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        echo "Error: Please run as root"
        exit 1
    fi

    # Check if another installation is in progress
    if [ -f "$INSTALL_LOCK" ]; then
        pid=$(cat "$INSTALL_LOCK")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Error: Another installation is in progress"
            exit 1
        else
            rm -f "$INSTALL_LOCK"
        fi
    fi
}

# Function to create lock file
create_lock() {
    echo $$ > "$INSTALL_LOCK"
    trap 'rm -f "$INSTALL_LOCK"' EXIT
}

# Function to check if WireGuard is already installed
check_existing() {
    if command -v wg >/dev/null 2>&1; then
        if [ -f "${WG_CONFIG_DIR}/params" ]; then
            echo "WireGuard is already installed and configured"
            exit 0
        fi
    fi
}

# Function to install WireGuard
install_wireguard() {
    echo "Installing WireGuard..."
    
    # Install WireGuard and dependencies
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y wireguard iptables resolvconf qrencode
    elif command -v yum >/dev/null 2>&1; then
        yum install -y epel-release
        yum install -y wireguard-tools iptables qrencode
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Sy --noconfirm wireguard-tools qrencode
    else
        echo "Error: Unsupported package manager"
        exit 1
    fi
}

# Function to configure WireGuard
configure_wireguard() {
    # Create WireGuard configuration directory
    mkdir -p "$WG_CONFIG_DIR"
    chmod 700 "$WG_CONFIG_DIR"

    # Create client directory
    mkdir -p "$CLIENT_DIR"
    chmod 700 "$CLIENT_DIR"

    # Generate server keys
    SERVER_PRIVATE_KEY=$(wg genkey)
    SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)
    
    # Save parameters
    cat > "${WG_CONFIG_DIR}/params" << EOF
SERVER_PRIVATE_KEY=$SERVER_PRIVATE_KEY
SERVER_PUBLIC_KEY=$SERVER_PUBLIC_KEY
WG_INTERFACE=$WG_INTERFACE
EOF
    chmod 600 "${WG_CONFIG_DIR}/params"

    # Create server configuration
    cat > "${WG_CONFIG_DIR}/${WG_INTERFACE}.conf" << EOF
[Interface]
PrivateKey = ${SERVER_PRIVATE_KEY}
Address = 10.66.66.1/24
ListenPort = 51820
SaveConfig = true

# Enable IP forwarding
PostUp = sysctl -w net.ipv4.ip_forward=1
PostUp = iptables -A FORWARD -i %i -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF
    chmod 600 "${WG_CONFIG_DIR}/${WG_INTERFACE}.conf"

    # Enable and start WireGuard
    systemctl enable "wg-quick@${WG_INTERFACE}"
    systemctl start "wg-quick@${WG_INTERFACE}"
}

# Main installation process
echo "=== ZVPN WireGuard Installation ==="

check_requirements
create_lock
check_existing

echo "Starting WireGuard installation..."
install_wireguard

echo "Configuring WireGuard..."
configure_wireguard

echo "Verifying installation..."
if ! systemctl is-active --quiet "wg-quick@${WG_INTERFACE}"; then
    echo "Error: WireGuard service failed to start"
    exit 1
fi

echo "WireGuard installation completed successfully"
echo "Server public key: $SERVER_PUBLIC_KEY"
echo "Interface: $WG_INTERFACE"
echo "Configuration directory: $WG_CONFIG_DIR"

exit 0 