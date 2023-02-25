#!/bin/bash
if ! [[ -e /etc/wireguard/params ]]; then
    apt-get update
    apt-get install -y wireguard iptables resolvconf qrencode

    mkdir /etc/wireguard >/dev/null 2>&1

    chmod 600 -R /etc/wireguard/


    ZVPN_CACHE_FILE="/etc/zvpn/includes/zvpn-runtime.sh"

    # Check if the cache file exists
    if [ -f "$ZVPN_CACHE_FILE" ]; then
    # Load the cached data from the file
    source "$ZVPN_CACHE_FILE"
    else
    # Generate new keys and store them in the cache file
    echo "Generating new keys for this server..."
    SERVER_PRIV_KEY=$(wg genkey)
    SERVER_PUB_KEY=$(echo "${SERVER_PRIV_KEY}" | wg pubkey)
    echo "Done generating keys."
    echo "Writing keys to cache file..."
    echo "SERVER_PRIV_KEY=\"$SERVER_PRIV_KEY\"" > "$ZVPN_CACHE_FILE"
    echo "SERVER_PUB_KEY=\"$SERVER_PUB_KEY\"" >> "$ZVPN_CACHE_FILE"
    fi

    # Save WireGuard settings

    echo "SERVER_PUB_IP=${VPS_IP}
	SERVER_PUB_NIC=${VPS_NIC}
	SERVER_WG_NIC=${WG_NIC}
	SERVER_WG_IPV4=${WG_IPV4}
	SERVER_WG_IPV6=${WG_IPV6}
	SERVER_PORT=${WG_PORT}
	SERVER_PRIV_KEY=${SERVER_PRIV_KEY}
	SERVER_PUB_KEY=${SERVER_PUB_KEY}
	CLIENT_DNS_1=${WG_DNS1}
	CLIENT_DNS_2=${WG_DNS2}" >/etc/wireguard/params

    echo "[Interface]
	Address = ${WG_IPV4}/24,${WG_IPV6}/64
	ListenPort = ${WG_PORT}
	PrivateKey = ${SERVER_PRIV_KEY}" >"/etc/wireguard/${WG_NIC}.conf"

    if pgrep firewalld; then
        FIREWALLD_IPV4_ADDRESS=$(echo "${WG_IPV4}" | cut -d"." -f1-3)".0"
        FIREWALLD_IPV6_ADDRESS=$(echo "${WG_IPV6}" | sed 's/:[^:]*$/:0/')
        echo "PostUp = firewall-cmd --add-port ${WG_PORT}/udp && firewall-cmd --add-rich-rule='rule family=ipv4 source address=${FIREWALLD_IPV4_ADDRESS}/24 masquerade' && firewall-cmd --add-rich-rule='rule family=ipv6 source address=${FIREWALLD_IPV6_ADDRESS}/24 masquerade'
		PostDown = firewall-cmd --remove-port ${WG_PORT}/udp && firewall-cmd --remove-rich-rule='rule family=ipv4 source address=${FIREWALLD_IPV4_ADDRESS}/24 masquerade' && firewall-cmd --remove-rich-rule='rule family=ipv6 source address=${FIREWALLD_IPV6_ADDRESS}/24 masquerade'" >>"/etc/wireguard/${WG_NIC}.conf"
    else
        echo "PostUp = iptables -A FORWARD -i ${VPS_NIC} -o ${WG_NIC} -j ACCEPT; iptables -A FORWARD -i ${WG_NIC} -j ACCEPT; iptables -t nat -A POSTROUTING -o ${VPS_NIC} -j MASQUERADE; ip6tables -A FORWARD -i ${WG_NIC} -j ACCEPT; ip6tables -t nat -A POSTROUTING -o ${VPS_NIC} -j MASQUERADE
		PostDown = iptables -D FORWARD -i ${VPS_NIC} -o ${WG_NIC} -j ACCEPT; iptables -D FORWARD -i ${WG_NIC} -j ACCEPT; iptables -t nat -D POSTROUTING -o ${VPS_NIC} -j MASQUERADE; ip6tables -D FORWARD -i ${WG_NIC} -j ACCEPT; ip6tables -t nat -D POSTROUTING -o ${VPS_NIC} -j MASQUERADE" >>"/etc/wireguard/${WG_NIC}.conf"
    fi

    echo "net.ipv4.ip_forward = 1
	net.ipv6.conf.all.forwarding = 1" >/etc/sysctl.d/wg.conf
    sysctl --system
    systemctl start "wg-quick@${WG_NIC}"
    systemctl enable "wg-quick@${WG_NIC}"
fi
