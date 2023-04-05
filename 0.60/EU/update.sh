#!/bin/bash

# Echoes executed command
# set -x
# Exit with error if some command fails
# set -e

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

BASEURL="https://pisces-firmware.sidcloud.cn"
FIRMWARE_VERSION="0.60"
GATEWAY_RS_PATH="/etc/helium_gateway"
GATEWAY_REGION="EU"
GATEWAY_URL="https://github.com/helium/gateway-rs/releases/download"
GATEWAY_VER="v1.0.0/helium-gateway-1.0.0-armv7-unknown-linux-musleabihf.tar.gz"

echo "update $FIRMWARE_VERSION"

mkdir -p "$GATEWAY_RS_PATH/"
echo "🍺 mkdir $GATEWAY_RS_PATH/"

rm -rf $GATEWAY_RS_PATH/*
echo "🍺rm -rf $GATEWAY_RS_PATH/*"

# Download the gateway_rs programe
wget "$GATEWAY_URL/$GATEWAY_VER" -P "$GATEWAY_RS_PATH/"
wait
# Unzip the pack
tar -xvf "$GATEWAY_RS_PATH/helium-gateway-1.0.0-armv7-unknown-linux-musleabihf.tar.gz" -C "$GATEWAY_RS_PATH/"
wait

# Download config
curl -Lf "$BASEURL/$FIRMWARE_VERSION/$GATEWAY_REGION/settings.toml" -o "$GATEWAY_RS_PATH/settings.toml"

echo "🍺 fetch $BASEURL/$FIRMWARE_VERSION/$GATEWAY_REGION/settings.toml to $GATEWAY_RS_PATH/settings.toml"

# Download the service 
curl -Lf "$BASEURL/$FIRMWARE_VERSION/helium.service" -o "/lib/systemd/system/helium.service"

# Update the init
curl -Lf "$BASEURL/$FIRMWARE_VERSION/init.sh" -o "/home/pi/hnt/script/init.sh"

# Stop miner container if already started
    docker stop miner || true 
    docker rm miner || true 

    systemctl daemon-reload
# Stop the service of helium
    service helium stop 

# Start up the service
    service helium start

echo "Helium_gateway running and updated"

# Update the lsb_release file
echo "DISTRIB_RELEASE=2023.03.30" | sudo tee /etc/lsb_release
wait
echo "version update"
wait

# Update the version file
curl -Lf $BASEURL/$FIRMWARE_VERSION/version -o /home/pi/api/tool/version;
wait
echo "update $FIRMWARE_VERSION success"
