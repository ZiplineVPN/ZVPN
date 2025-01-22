#!/bin/bash

# DNS Cache Flush Tool
# Flushes DNS caches for various network managers

declare -A network_managers=(
    ["nmcli"]="sudo nmcli networking off && sudo systemctl stop NetworkManager.service && sudo systemctl start NetworkManager.service && sudo nmcli networking on"
    ["systemd-resolved"]="sudo systemd-resolve --flush-caches"
    ["dnsmasq"]="sudo /etc/init.d/dnsmasq restart"
    ["avahi-daemon"]="sudo systemctl restart avahi-daemon.service"
    ["nscd"]="sudo service nscd restart"
    ["unbound"]="sudo unbound-control reload"
    ["pdnsd"]="sudo pdnsd-ctl empty-cache"
    ["resolvconf"]="sudo resolvconf -f"
    ["dnsmasq-base"]="sudo service dnsmasq restart"
)

# Initialize status flag
flushed=false

# Header
echo "=== ZVPN DNS Cache Flush Tool ==="
echo "Detecting available network managers..."

# Attempt to flush DNS for each available manager
for manager in "${!network_managers[@]}"; do
    if command -v "$manager" >/dev/null 2>&1; then
        echo "Found $manager, attempting to flush DNS cache..."
        if eval "${network_managers[$manager]}" >/dev/null 2>&1; then
            echo "✓ Successfully flushed DNS cache for $manager"
            flushed=true
        else
            echo "✗ Failed to flush DNS cache for $manager"
        fi
    fi
done

# Final status
if [ "$flushed" = false ]; then
    echo "No supported network managers were found."
    exit 1
else
    echo "DNS cache flush operations completed."
    exit 0
fi 