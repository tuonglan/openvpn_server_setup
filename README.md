# Preparation
## Install easyrsa
https://github.com/OpenVPN/easy-rsa

## Build openvpn server image
Ex: git@github.com:tuonglan/docker-openvpn-server.git

## Set environment variables
VPN_NAME - Ex: seoul_raps4
VPN_SUBNET_PREFIX - Ex: 192.168.1
VPN_PORT - Ex: 1194
VPN_SERVER_IMAGE - Ex: kylemanna/openvpn:latest

# Setup

## Create directory for the server's configuration
The directory will have client's config, server's config and CA
Ex: mkdir /etc/openvpn/seoul_rasp4

## Generate the configurations
Run command: ./setup_ca_environment.sh <config dir> <type>
Ex: `./setup_ca_environment.sh /etc/openvpn/seoul_rasp4 subnet`

## Start the openvpn server container
Ex:
```
    rasp4-bmt-subnet54:
        image: <openvpn Docker image>
        hostname: "seoul-raps4"
        ports: 
          - "1194:1194/udp"
        environment:
          - ALLOWED_SUBNETS=192.168.50.0/24;10.255.255.0/24
        volumes:
          - "/etc/openvpn/seoul_rasp4/server:/server"
          - "/var/log/openvpn/seoul_rasp4:/var/log/openvpn"
        devices:
          - "/dev/net/tun:/dev/net/tun"
        cap_add:
          - NET_ADMIN
        restart: always
        logging:
            driver: "json-file"
            options:
                max-size: "5m"
                max-file: 10
        command: "./start-openvpn-server.sh seoul_rasp4.conf"
```


# Openvpn Certifications Management
Move to the directory created by setup_ca_environment.sh above
Ex:
  `cd /etc/openvpn/seoul_raps4`

## Generate clients' configurations
Ex:
  `./client_config.sh make lando`

The openvpn config file will be created in clients/configs/lando.ovpn
Copy the file to mobile device or run command "openvpn --config <ovpn file>" and tada.

## Renew clients' configurations
Ex:
  `./client_config.sh review lando`

Review actual creates ovpn file so update the file in other device is necessary.

## Revoke client's configurations
Ex:
  `./client_config.sh revoke lando`

## Renew server's certificate
Usually after 2 years the server's certificate will be expired.
The renewal will generate new certificate using the same CA
Ex:
  `./server_config.sh renew`
  
After renewal, restart the docker container for new certificate being effective.


