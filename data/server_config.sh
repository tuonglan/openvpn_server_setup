#!/bin/bash

set -e

# Get the location of the script
INSTALLATION_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VPN_NAME=<%=vpn_name%>

# Check command
if [ "$1" != "renew" ]; then
   echo "The command (1st argument must be one of [renew]"
   exit -1
fi

CMD=${1}

# Set CN name & ey name
export EASYRSA_PKI=${INSTALLATION_DIR}/pki
export KEY_CN=$VPN_NAME
export KEY_NAME=$VPN_NAME

# ---- Generate the client keys ----
echo "Configuring the server $VPN_NAME..."

if [ "$CMD" == "renew" ]; then
    easyrsa renew $VPN_NAME nopass
else
    echo "Invalid command ${CMD}"
    exit -1
fi

cp ${EASYRSA_PKI}/issued/${VPN_NAME}.crt ${INSTALLATION_DIR}/server/
cp ${EASYRSA_PKI}/private/${VPN_NAME}.key ${INSTALLATION_DIR}/server/
