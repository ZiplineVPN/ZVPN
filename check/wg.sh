
if [[ -e /etc/wireguard/params ]]; then
	echo "Wireguard Installed."
    echo 0
else
    echo "Wireguard Not Installed."
    exit 1
fi