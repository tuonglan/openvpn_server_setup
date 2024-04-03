#!/bin/bash

set -e

# Configure the tempfile & cleanup
#REVOKE_OUTPUT_FILE=""
#cleanup() {
#    # Delete temp file
#    if [ ! -z $REVOKE_OUTPUT_FILE ]; then
#        rm -rf $REVOKE_OUTPUT_FILE
#        echo "Temporary file $REVOKE_OUTPUT_FILE deleted"
#    fi
#}
#trap cleanup EXIT

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
    # Revoke and get serial number
#    REVOKE_OUTPUT_FILE=$(mktemp)
#    easyrsa revoke $CLIENT | tee $REVOKE_OUTPUT_FILE
#
#    # Copy revoked serial to the server
#    revoked_serial=$(grep -oP 'serial-number: \K\w+' $REVOKE_OUTPUT_FILE)
#    cp ${EASYRSA_PKI}/revoked/certs_by_serial/$revoked_serial.crt ${INSTALLATION_DIR}/server/crl/
    easyrsa revoke $CLIENT    # Revoke certificate
    
    # Update crl (certificate revocation list)
    easyrsa gen-crl
    echo "Updating crl.pem, will need root permission to change ownership to 'nobody'"
    sudo cp ${EASYRSA_PKI}/crl.pem ${INSTALLATION_DIR}/server/crl/
    sudo chown nobody ${INSTALLATION_DIR}/server/crl/crl.pem
    echo "Certificates revocation list updated (pki/crl.pem)"

    # Move the revoked one to revoked directory
    mkdir -p ${CONF_DIR}/revoked
    mv ${CONF_DIR}/${CLIENT}.ovpn ${CONF_DIR}/revoked/

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

