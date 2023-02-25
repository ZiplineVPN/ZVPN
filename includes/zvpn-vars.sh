VPS_IP=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | awk '{print $1}' | head -1)
VPS_NIC="$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)"
WG_NIC="wg0"
WG_IPV4="10.66.66.1"
WG_IPV6="fd42:42:42::1"
WG_DNS1="8.8.8.8"
WG_DNS2="8.8.4.4"
WG_PORT=$(shuf -i49152-65535 -n1)
WG_ENDPOINT="${VPS_IP}:${WG_PORT}"
HOME_DIR="/root"
WG_INSTALLED=$(serverAndCertCheck)

ZVPN_CACHE_FILE="/etc/zvpn/includes/zvpn-runtime.sh"

# Check if the cache file exists
if [ -f "$ZVPN_CACHE_FILE" ]; then
  # Load the cached data from the file
  source "$ZVPN_CACHE_FILE"
else
  # Generate new keys and store them in the cache file
  echo "Generating new keys for this server..."
  echo "Done generating keys."
  echo "Writing keys to cache file..."
  echo "SERVER_PRIV_KEY=\"$SERVER_PRIV_KEY\"" > "$ZVPN_CACHE_FILE"
  echo "SERVER_PUB_KEY=\"$SERVER_PUB_KEY\"" >> "$ZVPN_CACHE_FILE"
fi