#!/bin/bash

# Get the location of the script
INSTALLATION_DIR=<%=installation_dir%>
KEY_DIR=${INSTALLATION_DIR}/clients/keys
CONF_DIR=${INSTALLATION_DIR}/clients/configs

# If the cliient name is NULL 
if [ -z "$1" ]; then
    echo "The client name can't be NULL (1st argument)"
    exit -1
fi

# Set CN name & ey name
export EASYRSA_PKI=${INSTALLATION_DIR}/pki
export KEY_CN=client_$1
export KEY_NAME=$1

# ---- Generate the client keys ----
echo "Generating the client keys..."

easyrsa build-client-full $1 nopass
cp ${EASYRSA_PKI}/issued/${1}.crt ${KEY_DIR}/
cp ${EASYRSA_PKI}/private/${1}.key ${KEY_DIR}/

# ---- Create the Client config from the signed keys ----
echo "Making the openvpn configuration key for ${1}..."

cat ${CONF_DIR}/base.conf <(echo -e '<ca>') \
    ${INSTALLATION_DIR}/server/ca.crt <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/${1}.crt <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${1}.key <(echo -e '</key>\n<tls-auth>') \
    ${INSTALLATION_DIR}/server/ta.key <(echo -e '</tls-auth>') \
    > ${CONF_DIR}/${1}.ovpn

