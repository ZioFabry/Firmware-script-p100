#!/bin/bash

# Echoes executed command
# set -x
# Exit with error if some command fails
# set -e

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

BASEURL="https://raw.githubusercontent.com/ZioFabry/Firmware-script-p100/v0.6.0fix"
FIRMWARE_VERSION="0.60"
GATEWAY_RS_PATH="/etc/helium_gateway"
GATEWAY_REGION="EU"
GATEWAY_URL="https://github.com/helium/gateway-rs/releases/download"
GATEWAY_VER="1.1.1"
GATEWAY_TAR="helium-gateway-${GATEWAY_VER}-armv7-unknown-linux-musleabihf.tar.gz"

echo "Firmware update $FIRMWARE_VERSION"

mkdir -p "$GATEWAY_RS_PATH/"
echo "🍺 mkdir $GATEWAY_RS_PATH/"

rm -rf $GATEWAY_RS_PATH/*
echo "🍺rm -rf $GATEWAY_RS_PATH/*"

# Download the gateway_rs programe
wget "$GATEWAY_URL/v$GATEWAY_VER/$GATEWAY_TAR" -P "$GATEWAY_RS_PATH/"
wait
# Unzip the pack
tar -xvf "$GATEWAY_RS_PATH/$GATEWAY_TAR" -C "$GATEWAY_RS_PATH/"
wait

# Download config
echo "🍺 fetch $BASEURL/$FIRMWARE_VERSION/$GATEWAY_REGION/settings.toml -> $GATEWAY_RS_PATH/settings.toml"
curl -Lf "$BASEURL/$FIRMWARE_VERSION/$GATEWAY_REGION/settings.toml" -o "$GATEWAY_RS_PATH/settings.toml"

# Download the service 
echo "🍺 fetch $BASEURL/$FIRMWARE_VERSION/helium.service -> /lib/systemd/system/helium.service"
curl -Lf "$BASEURL/$FIRMWARE_VERSION/helium.service" -o "/lib/systemd/system/helium.service"

# Update the init
echo "🍺 fetch $BASEURL/$FIRMWARE_VERSION/init.sh -> /home/pi/hnt/script/init.sh"
curl -Lf "$BASEURL/$FIRMWARE_VERSION/init.sh" -o "/home/pi/hnt/script/init.sh"

# Stop miner container if already started
echo "🍺 Removing old Docker if present..."
    docker stop miner || true 
    docker rm miner || true 

echo "🍺 Installing new service..."
    systemctl daemon-reload
# Stop the service of helium
    systemctl stop helium

# Start up the service
    systemctl enable helium
    systemctl start helium

echo "🍺Helium_gateway running and updated"

# Update the lsb_release file
echo "DISTRIB_RELEASE=gw_$GATEWAY_VER" | sudo tee /etc/lsb_release
wait
echo "🍺GW version $GATEWAY_VER updated"
wait

# Update the version file
curl -Lf $BASEURL/$FIRMWARE_VERSION/version -o /home/pi/api/tool/version;
wait
echo "🍺Firmware $FIRMWARE_VERSION updated"
