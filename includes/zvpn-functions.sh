makeClient() {
    DOT_IP="$1"
    checkClientExists "$DOT_IP"
    if [[ $? -ne 0 ]]; then
        exit 1
    fi

    if [[ -n "$2" ]]; then
        CLIENT_NAME="$2"
    else
        CLIENT_NAME="client-$DOT_IP"
    fi

    BASE_IP=$(echo "$SERVER_WG_IPV4" | awk -F '.' '{ print $1"."$2"."$3 }')
    CLIENT_WG_IPV4="${BASE_IP}.${DOT_IP}"
    BASE_IP=$(echo "$SERVER_WG_IPV6" | awk -F '::' '{ print $1 }')
    CLIENT_WG_IPV6="${BASE_IP}::${DOT_IP}"

    CLIENT_PRIV_KEY=$(wg genkey)
    CLIENT_PUB_KEY=$(echo "${CLIENT_PRIV_KEY}" | wg pubkey)
    CLIENT_PRE_SHARED_KEY=$(wg genpsk)
    # Create client file and add the server as a peer
    echo "[Interface]
	PrivateKey = ${CLIENT_PRIV_KEY}
	Address = ${CLIENT_WG_IPV4}/32,${CLIENT_WG_IPV6}/128
	DNS = ${CLIENT_DNS_1},${CLIENT_DNS_2}

	[Peer]
	PublicKey = ${SERVER_PUB_KEY}
	PresharedKey = ${CLIENT_PRE_SHARED_KEY}
	Endpoint = ${ENDPOINT}
	AllowedIPs = 0.0.0.0/0,::/0" >>"${HOME_DIR}/${SERVER_WG_NIC}-client-${CLIENT_NAME}.conf"

    # Add the client as a peer to the server
    echo -e "\n### Client ${CLIENT_NAME}
	[Peer]
	PublicKey = ${CLIENT_PUB_KEY}
	PresharedKey = ${CLIENT_PRE_SHARED_KEY}
	AllowedIPs = ${CLIENT_WG_IPV4}/32,${CLIENT_WG_IPV6}/128" >>"/etc/wireguard/${SERVER_WG_NIC}.conf"

    wg syncconf "${SERVER_WG_NIC}" <(wg-quick strip "${SERVER_WG_NIC}")

    qrencode -t ansiutf8 -l L <"${HOME_DIR}/${SERVER_WG_NIC}-client-${CLIENT_NAME}.conf"

    echo "${HOME_DIR}/${SERVER_WG_NIC}-client-${CLIENT_NAME}.conf"
    #Now finally write that the .conf file has been created
    #That way if something goes wrong or fails and exits before this point, the script will try again
    #re-using the same IP address the next time it tries to make a client.
    exit 0
}

checkClientExists() {
    DOT_EXISTS=$(grep -c "${SERVER_WG_IPV4::-1}${1}" "/etc/wireguard/${SERVER_WG_NIC}.conf")
    if [[ ${DOT_EXISTS} == '0' ]]; then
        exit 0
    fi
    exit 1
}

makeMassClients() {

    if [[ -z $1 ]]; then
        echo "You must specify the number of clients to make"
        exit 1
    fi

    NUMBER_OF_CLIENTS=$1
    clients_made=0

    for DOT_IP in {2..254}; do
        makeClient "$DOT_IP"
        if [[ $? -eq 0 ]]; then
            clients_made=$((clients_made + 1))
            echo "Client $clients_made made at $DOT_IP"
        fi

        if [[ $clients_made -eq $NUMBER_OF_CLIENTS ]]; then
            echo "All clients made!"
            exit 0
        fi

        if [[ $DOT_IP -eq 254 ]]; then
            echo "Reached the end of address space."
            exit 2
        fi
    done
}

serverAndCertCheck() {
    if [[ -e /etc/wireguard/params && -e /root/wg0-client-default.conf ]]; then
        echo "true"
    else
        echo "false"
    fi
}
