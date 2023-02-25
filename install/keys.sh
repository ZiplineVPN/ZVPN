CACHE_FILE="/etc/zvpn-cache/cache"

# Check if the cache file exists
if [ -f "$CACHE_FILE" ]; then
  # Load the cached data from the file
  source "$CACHE_FILE"
else
  # Generate new keys and store them in the cache file
  echo "Generating new keys for this server..."
  SERVER_PRIV_KEY=$(wg genkey)
  SERVER_PUB_KEY=$(echo "${SERVER_PRIV_KEY}" | wg pubkey)
  echo "Done generating keys."
  echo "Writing keys to cache file..."
  echo "SERVER_PRIV_KEY=\"$SERVER_PRIV_KEY\"" > "$CACHE_FILE"
  echo "SERVER_PUB_KEY=\"$SERVER_PUB_KEY\"" >> "$CACHE_FILE"
fi