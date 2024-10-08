#!/bin/bash

set -e

# Must include the argument
if [ -z "$1" ]; then
    echo "First argument must be target location"
    exit -1
fi

if [ -z "$2" ]; then
    echo "Second argument must be server type: [default|subnet]"
    exit -1
fi

# Init the values
export VPN_NAME=${VPN_NAME:-ovpn_server}
export VPN_SUBNET_PREFIX=${VPN_SUBNET_PREFIX:-10.5.53}
export VPN_ADDRESS=${VPN_ADDRESS:-lando.com}
export VPN_PORT=${VPN_PORT:-11194}
export VPN_SERVER_IMAGE=${VPN_SERVER_IMAGE}

# Dependencies
export VPN_TYPE=$2
export VPN_SUBNET=${VPN_SUBNET_PREFIX}.0
export VPN_SUBNET_GATEWAY=${VPN_SUBNET_PREFIX}.1
export VPN_IP_POOL_START=${VPN_SUBNET_PREFIX}.11
export VPN_IP_POOL_END=${VPN_SUBNET_PREFIX}.255

USER_ID=$(id -u $USER)
GROUP_ID=$(id -g $USER)

# Check if Openvpn image env variable is set
if [ -z "$VPN_SERVER_IMAGE" ]; then
    echo "VPN_SERVER_IMAGE is not set properly: $VPN_SERVER_IMAGE"
    exit -1
fi

# Make the directoriesa
echo "Making the directories & files"
DIR=$1
mkdir -p ${DIR}/server ${DIR}/server/ccd ${DIR}/server/crl ${DIR}/pki ${DIR}/clients/configs ${DIR}/clients/keys

# Init the PKI
echo "Init the PKI"
export EASYRSA_PKI=${DIR}/pki
easyrsa init-pki
easyrsa build-ca nopass

# Init the servera
echo "Generate the server certificate"
easyrsa build-server-full $VPN_NAME nopass
easyrsa gen-dh
sudo docker run --rm -it -u $USER_ID:$GROUP_ID -v ${DIR}:${DIR} ${VPN_SERVER_IMAGE} openvpn --genkey secret ${DIR}/server/ta.key
easyrsa gen-crl

# Finalize the data
echo "Finalize the data"
cp ${DIR}/pki/dh.pem ${DIR}/server/
cp ${DIR}/pki/ca.crt ${DIR}/server/
cp ${DIR}/pki/issued/${VPN_NAME}.crt ${DIR}/server/
cp ${DIR}/pki/private/${VPN_NAME}.key ${DIR}/server/
cp ${EASYRSA_PKI}/crl.pem ${DIR}/server/crl/

echo "Updating crl.pem, will need root permission to change ownership to 'nobody'"
sudo chown nobody ${DIR}/server/crl/crl.pem

cp data/base.conf ${DIR}/clients/configs/
sed -i "s|<%=vpn_address%>|${VPN_ADDRESS}|g" ${DIR}/clients/configs/base.conf
sed -i "s|<%=vpn_port%>|${VPN_PORT}|g" ${DIR}/clients/configs/base.conf
sed -i "s|<%=vpn_subnet%>|${VPN_SUBNET}|g" ${DIR}/clients/configs/base.conf

# Create config files
cp data/client_config.sh ${DIR}/
sed -i "s|<%=installation_dir%>|${DIR}|g" ${DIR}/client_config.sh
cp data/server_config.sh ${DIR}/
sed -i "s|<%=vpn_name%>|${VPN_NAME}|g" ${DIR}/server_config.sh

#cp data/server.conf ${DIR}/server/${VPN_NAME}.conf
#sed -i "s|<%=vpn_name%>|${VPN_NAME}|g" ${DIR}/server/${VPN_NAME}.conf
#sed -i "s|<%=vpn_subnet%>|${VPN_SUBNET}|g" ${DIR}/server/${VPN_NAME}.conf
envsubst < data/server-${VPN_TYPE}.conf > ${DIR}/server/${VPN_NAME}.conf
