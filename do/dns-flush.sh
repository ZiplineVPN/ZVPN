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

flushed=false

for manager in "${!network_managers[@]}"; do
  if command -v "$manager" >/dev/null 2>&1; then
    echo "Flushing DNS cache for $manager..."
    eval "${network_managers[$manager]}"
    flushed=true
  fi
done

if [ "$flushed" = false ]; then
  echo "No supported network manager was found."
fi