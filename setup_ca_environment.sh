#!/bin/bash

# Must include the argument
if [ -z "$1" ]; then
    echo "First argument must be target location"
    exit -1
fi

# Init the values
VPN_NAME=${VPN_NAME:-ovpn_server}
VPN_SUBNET=${VPN_SUBNET:-10.8.52.0}

# Make the directoriesa
echo "Making the directories & files"
DIR=$1
mkdir -p ${DIR}/server ${DIR}/pki ${DIR}/clients/configs ${DIR}/clients/keys

# Init the PKI
echo "Init the PKI"
export EASYRSA_PKI=${DIR}/pki
easyrsa init-pki
easyrsa build-ca nopass

# Init the servera
echo "Generate the server certificate"
easyrsa build-server-full $VPN_NAME nopass
easyrsa gen-dh
openvpn --genkey --secret ${DIR}/server/ta.key

# Finalize the data
echo "Finalize the data"
cp data/base.conf ${DIR}/clients/configs/
cp ${DIR}/pki/dh.pem ${DIR}/server/
cp ${DIR}/pki/ca.crt ${DIR}/server/

cp data/make_client_config.sh ${DIR}/
sed -i "s|<%=installation_dir%>|${DIR}|g" ${DIR}/make_client_config.sh

cp data/server.conf ${DIR}/server/${VPN_NAME}.conf
sed -i "s|<%=vpn_name%>|${VPN_NAME}|g" ${DIR}/server/${VPN_NAME}.conf
sed -i "s|<%=vpn_subnet%>|${VPN_SUBNET}|g" ${DIR}/server/${VPN_NAME}.conf
