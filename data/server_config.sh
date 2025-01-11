#!/bin/bash

set -e

# Get the location of the script
INSTALLATION_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
VPN_NAME=<%=vpn_name%>

# Check command
if [ "$1" != "renew_cert" ] && [ "$1" != "renew_crl"]; then
   echo "The command 1st argument must be one of [renew_cert, renew_crl]"
   exit -1
fi

CMD=${1}
EXPIRATION=${3}

# Set expiration
export EASYRSA_CERT_EXPIRE=${EXPIRATION:-${EASYRSA_CERT_EXPIRE:-<%=default_server_cert_expiration%>}}
export EASYRSA_CRL_DAYS=${EXPIRATION:-${EASYRSA_CRL_DAYS:-<%=default_crl_expiration%>}}

# Set CN name & ey name
export EASYRSA_PKI=${INSTALLATION_DIR}/pki
export KEY_CN=$VPN_NAME
export KEY_NAME=$VPN_NAME

# ---- Generate the client keys ----
echo "Configuring the server $VPN_NAME..."

if [ "$CMD" == "renew_cert" ]; then
    easyrsa renew $VPN_NAME nopass
    cp ${EASYRSA_PKI}/issued/${VPN_NAME}.crt ${INSTALLATION_DIR}/server/
    cp ${EASYRSA_PKI}/private/${VPN_NAME}.key ${INSTALLATION_DIR}/server/

    exit 0
elif [ "$CMD" == "renew_crl" ]; then
    easyrsa gen-crl
    sudo cp ${EASYRSA_PKI}/crl.pem ${INSTALLATION_DIR}/server/crl/crl.pem
    sudo chown nobody ${INSTALLATION_DIR}/server/crl/crl.pem

    exit 0
else
    echo "Invalid command ${CMD}"
    exit -1
fi

