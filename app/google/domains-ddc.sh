#!/bin/sh

HOSTNAME="host.yourdomain.com"
USERNAME="username"
PASSWORD="password"

LOG_FILE="/tmp/ddns/ddns.log"

#END SETUP

while true; do

    PUBLIC_IP=$(curl -s -k https://domains.google.com/checkip)
    DDNS_IP=$(nvram get ddns_ipaddr)

    if [ "$PUBLIC_IP" != "$DDNS_IP" ]; then

        URL="https://domains.google.com/nic/update?hostname=${HOSTNAME}&myip=${PUBLIC_IP}"
        RESP=$(curl -s -k --user "${USERNAME}:${PASSWORD}" "$URL")

        case $RESP in
            "good ${PUBLIC_IP}" | "nochg ${PUBLIC_IP}")
                nvram set ddns_ipaddr=${PUBLIC_IP}
                nvram commit
                echo "`date`: ${HOSTNAME} successfully updated to ${PUBLIC_IP}." >> ${LOG_FILE}
                ;;
            "nohost")
                echo "`date`: The host ${HOSTNAME} does not exist, or does not have Dynamic DNS enabled." >> ${LOG_FILE}
                sleep 3600
                ;;
            "badauth")
                echo "`date`: The username / password combination is not valid for the host ${HOSTNAME}." >> ${LOG_FILE}
                sleep 3600
                ;;
            "notfqdn")
                echo "`date`: The supplied hostname ${HOSTNAME} is not a valid fully-qualified domain name." >> ${LOG_FILE}
                exit
                ;;
            "badagent")
                echo "`date`: Your Dynamic DNS client is making bad requests. Ensure the user agent is set in the request." >> ${LOG_FILE}
                exit
                ;;
            "abuse")
                echo "`date`: Dynamic DNS access for the hostname ${HOSTNAME} has been blocked." >> ${LOG_FILE}
                exit
                ;;
            "911")
                echo "`date`: An error happened on Googles end. Wait 5 minutes and retry." >> ${LOG_FILE}
                sleep 300
                ;;
            *)
                echo "`date`: $RESP" >> ${LOG_FILE}
                sleep 3600
        esac

    fi

    sleep 60

done