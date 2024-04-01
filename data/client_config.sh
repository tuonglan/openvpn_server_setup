#!/bin/bash

set -e

# Get the location of the script
INSTALLATION_DIR=<%=installation_dir%>
KEY_DIR=${INSTALLATION_DIR}/clients/keys
CONF_DIR=${INSTALLATION_DIR}/clients/configs

# Check command
if [ "$1" != "make" ] && [ "$1" != "renew" ] && [ "$1" != "revoke" ]; then
   echo "The command (1st argument must be one of [make, renew, revoke]"
   exit -1
fi

# If the cliient name is NULL 
if [ -z "$2" ]; then
    echo "The client name can't be NULL (2st argument)"
    exit -1
fi

CMD=${1}
CLIENT=${2}

# Set CN name & ey name
export EASYRSA_PKI=${INSTALLATION_DIR}/pki
export KEY_CN=client_$CLIENT
export KEY_NAME=$CLIENT

# ---- Generate the client keys ----
echo "Generating the client keys..."

if [ "$CMD" == "make" ]; then
    easyrsa build-client-full $CLIENT nopass
elif [ "$CMD" == "renew" ]; then
    easyrsa renew $CLIENT nopass
elif [ "$CMD" == "revoke" ]; then
    easyrsa revoke $CLIENT
    exit 0
else
    echo "Invalid command ${CMD}"
    exit -1
fi
cp ${EASYRSA_PKI}/issued/${CLIENT}.crt ${KEY_DIR}/
cp ${EASYRSA_PKI}/private/${CLIENT}.key ${KEY_DIR}/

# ---- Create the Client config from the signed keys ----
echo "Making the openvpn configuration key for ${CLIENT}..."

cat ${CONF_DIR}/base.conf <(echo -e '<ca>') \
    ${INSTALLATION_DIR}/server/ca.crt <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/${CLIENT}.crt <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${CLIENT}.key <(echo -e '</key>\n<tls-auth>') \
    ${INSTALLATION_DIR}/server/ta.key <(echo -e '</tls-auth>') \
    > ${CONF_DIR}/${CLIENT}.ovpn

