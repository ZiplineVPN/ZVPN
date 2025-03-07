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