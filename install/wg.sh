#!/bin/bash

makeClient() {
    for DOT_IP in {2..254}; do
        DOT_EXISTS=$(grep -c "${WG_IPV4::-1}${DOT_IP}" "/etc/wireguard/${SERVER_WG_NIC}.conf")
        if [[ ${DOT_EXISTS} == '0' ]]; then
            break
        fi
    done
    CLIENT_NAME="$1"

    BASE_IP=$(echo "$WG_IPV4" | awk -F '.' '{ print $1"."$2"."$3 }')
    CLIENT_WG_IPV4="${BASE_IP}.${DOT_IP}"
    BASE_IP=$(echo "$WG_IPV6" | awk -F '::' '{ print $1 }')
    CLIENT_WG_IPV6="${BASE_IP}::${DOT_IP}"

    CLIENT_PRIV_KEY=$(wg genkey)
    CLIENT_PUB_KEY=$(echo "${CLIENT_PRIV_KEY}" | wg pubkey)
    CLIENT_PRE_SHARED_KEY=$(wg genpsk)
    # Create client file and add the server as a peer
    echo "[Interface]
	PrivateKey = ${CLIENT_PRIV_KEY}
	Address = ${CLIENT_WG_IPV4}/32,${CLIENT_WG_IPV6}/128
	DNS = ${WG_DNS1},${WG_DNS2}

	[Peer]
	PublicKey = ${SERVER_PUB_KEY}
	PresharedKey = ${CLIENT_PRE_SHARED_KEY}
	Endpoint = ${WG_ENDPOINT}
	AllowedIPs = 0.0.0.0/0,::/0" >>"${HOME_DIR}/${WG_NIC}-client-${CLIENT_NAME}.conf"

    # Add the client as a peer to the server
    echo -e "\n### Client ${CLIENT_NAME}
	[Peer]
	PublicKey = ${CLIENT_PUB_KEY}
	PresharedKey = ${CLIENT_PRE_SHARED_KEY}
	AllowedIPs = ${CLIENT_WG_IPV4}/32,${CLIENT_WG_IPV6}/128" >>"/etc/wireguard/${WG_NIC}.conf"

    wg syncconf "${WG_NIC}" <(wg-quick strip "${WG_NIC}")

    qrencode -t ansiutf8 -l L <"${HOME_DIR}/${WG_NIC}-client-${CLIENT_NAME}.conf"

    echo "${HOME_DIR}/${WG_NIC}-client-${CLIENT_NAME}.conf"
    #Now finally write that the .conf file has been created
    #That way if something goes wrong or fails and exits before this point, the script will try again
    #re-using the same IP address the next time it tries to make a client.
    exit 0
}


if ! [[ -e /etc/wireguard/params ]]; then
    apt-get update
    apt-get install -y wireguard iptables resolvconf qrencode

    mkdir /etc/wireguard >/dev/null 2>&1

    chmod 600 -R /etc/wireguard/

  SERVER_PRIV_KEY=$(wg genkey)
  SERVER_PUB_KEY=$(echo "${SERVER_PRIV_KEY}" | wg pubkey)


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

    makeClient default
fi
