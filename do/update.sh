#!/bin/bash

declare -A pkg_managers=(
  ["apt"]="sudo apt update -yq && sudo apt upgrade -yq && sudo apt autoremove -y && sudo apt autoclean -y"
  ["pacman"]="sudo pacman -Syu --noconfirm && sudo pacman -Qdtq | xargs sudo pacman -Rsn --noconfirm && sudo pacman -Sc --noconfirm"
  ["dnf"]="sudo dnf update -y && sudo dnf autoremove -y && sudo dnf clean all"
  ["yum"]="sudo yum update -y && sudo yum autoremove -y && sudo yum clean all"
  ["zypper"]="sudo zypper refresh -y && sudo zypper update -y && sudo zypper autoremove -y && sudo zypper clean -a"
  ["brew"]="brew update --quiet && brew upgrade --quiet && brew cleanup --quiet"
  ["snap"]="sudo snap refresh"
  ["yaourt"]="yaourt -Syu --noconfirm && yaourt -Qdtq | xargs yaourt -Rsn && yaourt -Sc --noconfirm"
  ["flatpak"]="flatpak update --assumeyes && flatpak uninstall --unused --assumeyes && flatpak cleanup --assumeyes"
  ["gem"]="gem update && gem cleanup"
  ["entropy-client"]="entropy-client --update-all --quiet && entropy-client --autoremove --quiet && entropy-client --autoclean --quiet"
  ["guix"]="guix pull --quiet && guix package --upgrade-all --quiet && guix package --delete-generations=old"
  ["ipkg"]="ipkg update --quiet && ipkg upgrade --quiet && ipkg autoremove --quiet && ipkg clean --quiet"
  ["netpkg"]="netpkg -u --quiet && netpkg -c --quiet"
  ["nix-channel"]="nix-channel --update --quiet && nix-collect-garbage --delete-old --quiet"
  ["openpkg"]="openpkg update --quiet && openpkg upgrade --quiet && openpkg autoremove --quiet && openpkg clean --quiet"
  ["opkg"]="opkg update --quiet && opkg upgrade --quiet && opkg autoremove --quiet && opkg clean --quiet"
)

for manager in "${!pkg_managers[@]}"; do
  if (command -v "$manager" > /dev/null 2>&1) || false; then
    echo "Updating packages using $manager..."
    eval "${pkg_managers[$manager]}"
    break
  fi
done