#!/bin/bash

# System Update Tool
# Updates system packages using available package managers

declare -A pkg_managers=(
    ["apt"]="sudo apt update -yq && sudo apt upgrade -yq && sudo apt autoremove -y && sudo apt autoclean -y"
    ["pacman"]="sudo pacman -Syu --noconfirm && sudo pacman -Qdtq | xargs sudo pacman -Rsn --noconfirm && sudo pacman -Sc --noconfirm"
    ["dnf"]="sudo dnf update -y && sudo dnf autoremove -y && sudo dnf clean all"
    ["yum"]="sudo yum update -y && sudo yum autoremove -y && sudo yum clean all"
    ["zypper"]="sudo zypper refresh -y && sudo zypper update -y && sudo zypper autoremove -y && sudo zypper clean -a"
    ["brew"]="brew update --quiet && brew upgrade --quiet && brew cleanup --quiet"
    ["snap"]="sudo snap refresh"
    ["flatpak"]="flatpak update --assumeyes && flatpak uninstall --unused --assumeyes && flatpak cleanup --assumeyes"
)

# Initialize counters
total_updated=0
total_failed=0

# Header
echo "=== ZVPN System Update Tool ==="
echo "Detecting available package managers..."

# Update for each available package manager
for manager in "${!pkg_managers[@]}"; do
    if command -v "$manager" >/dev/null 2>&1; then
        echo "Found $manager, attempting system update..."
        if eval "${pkg_managers[$manager]}" >/dev/null 2>&1; then
            echo "✓ Successfully updated system using $manager"
            ((total_updated++))
        else
            echo "✗ Failed to update system using $manager"
            ((total_failed++))
        fi
    fi
done

# Final status
echo
echo "Update Summary:"
echo "-------------"
echo "Successful updates: $total_updated"
echo "Failed updates: $total_failed"

if [ $total_updated -eq 0 ]; then
    echo "No supported package managers were found or updates failed."
    exit 1
else
    echo "System update operations completed."
    exit 0
fi 