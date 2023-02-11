#!/bin/bash

declare -A pkg_managers=(
  ["apt"]="sudo apt update -yq && sudo apt upgrade -yq && sudo apt autoremove -y && sudo apt autoclean -y"
  ["dnf"]="sudo dnf update -y && sudo dnf autoremove -y && sudo dnf clean all"
  ["pacman"]="sudo pacman -Syu --noconfirm && sudo pacman -Rsn $(pacman -Qdtq) && sudo pacman -Sc --noconfirm"
  ["yum"]="sudo yum update -y && sudo yum autoremove -y && sudo yum clean all"
  ["zypper"]="sudo zypper refresh -y && sudo zypper update -y && sudo zypper autoremove -y && sudo zypper clean -a"
  ["yaourt"]="yaourt -Syu --noconfirm && yaourt -Rsn $(yaourt -Qdtq) && yaourt -Sc --noconfirm"
  ["snap"]="sudo snap refresh"
  ["gem"]="gem update && gem cleanup"
  ["entropy-client"]="entropy-client --update-all --quiet && entropy-client --autoremove --quiet && entropy-client --autoclean --quiet"
  ["flatpak"]="flatpak update --assumeyes && flatpak uninstall --assumeyes --non-interactive $(flatpak list --unused | awk '{print $2}') && flatpak clean --assumeyes"
  ["guix"]="guix pull --quiet && guix package --upgrade-all --quiet && guix package --delete-generations=old"
  ["brew"]="brew update --quiet && brew upgrade --quiet && brew cleanup --quiet"
  ["ipkg"]="ipkg update --quiet && ipkg upgrade --quiet && ipkg autoremove --quiet && ipkg clean --quiet"
  ["netpkg"]="netpkg -u --quiet && netpkg -c --quiet"
  ["nix-channel"]="nix-channel --update --quiet && nix-collect-garbage --delete-old --quiet"
  ["openpkg"]="openpkg update --quiet && openpkg upgrade --quiet && openpkg autoremove --quiet && openpkg clean --quiet"
  ["opkg"]="opkg update --quiet && opkg upgrade --quiet && opkg autoremove --quiet && opkg clean --quiet"
)

for manager in "${!pkg_managers[@]}"; do
  if command -v "$manager" > /dev/null 2>&1; then
    echo "Updating packages using $manager..."
    eval "${pkg_managers[$manager]}"
    break
  fi
done