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

serverAndCertCheck() {
    if [[ -e /etc/wireguard/params && -e /root/wg0-client-default.conf ]]; then
        echo "true"
    else
        echo "false"
    fi
}