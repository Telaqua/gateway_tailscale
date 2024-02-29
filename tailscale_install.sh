#!/bin/sh

DOWNLOAD_SERVER="https://download.telaqua.fr"

# extract the gateway information
gateway_model_name=$(uci show einfo.dev.name | grep -o "'[^']*'" | sed "s/'//g")
gateway_eui=$(uci show einfo.dev.gw_eui | grep -o "'[^']*'" | sed "s/'//g")
gateway_hostname=$HOSTNAME

if [[ "$GATEWAY_MODEL" == "RAK7289C" || "$GATEWAY_MODEL" == "RAK7249" ]]; then
    echo "Using RAMIPS architecture and using sd card to store the tailscale"
    TAILSCALE_PACKET_NAME="tailscale_1.58.2-1_ramips_24kec.ipk"
    TAILSCALE_BINARY_PATH="/mnt/mmcblk0p1/tailscale/"
elif [[ "$GATEWAY_MODEL" == "RAK7289CV2" ]]; then
   echo "Using MIPSEL architecture and using flash to store the tailscale"
    TAILSCALE_PACKET_NAME="tailscale_1.58.2-1_mipsel_24kc.ipk"
    TAILSCALE_BINARY_PATH="/etc/tailscale/"
else 
    echo "Invalid model name (GATEWAY_MODEL) $GATEWAY_MODEL"
    exit 1
fi

TAILSCALE_BINARY_NAME="tailscale.combined"
echo "Downloading packet $PACKET_NAME"
wget -P /mnt/mmcblk0p1/tailscale $DOWNLOAD_SERVER/$PACKET_NAME
echo "Downloading binary $TAILSCALE_BINARY_NAME to $TAILSCALE_BINARY_PATH"
wget -P $TAILSCALE_BINARY_PATH $DOWNLOAD_SERVER/$TAILSCALE_BINARY_NAME

echo "Installing packet $PACKET_NAME"
opkg install /mnt/mmcblk0p1/tailscale/$TAILSCALE_PACKET_NAME
rm /mnt/mmcblk0p1/tailscale/$TAILSCALE_PACKET_NAME

# As side effect the packet installation will create
# some files for /etc/init.d/tailscale and /etc/init.d/tailscaled
echo "Remove initials /etc/init.d/tailscale[d]"
rm /etc/init.d/tailscale
rm /etc/init.d/tailscaled

ehco "Linking binaries to $TAILSCALE_BINARY_PATH/$TAILSCALE_BINARY_NAME"
ln -s "$TAILSCALE_BINARY_PATH/$TAILSCALE_BINARY_NAME" /usr/sbin/tailscaled
ln -s "$TAILSCALE_BINARY_PATH/$TAILSCALE_BINARY_NAME" /usr/sbin/tailscale

echo "Enable tailscale"
/etc/init.d/tailscale enable

echo "Starting tailscale"
/etc/init.d/tailscale start

# Check if a token has been given to the script as 
# env variable
if [ "$TAILSCALE_TOKEN" ]; then
    echo "TAILSCALE_TOKEN defined, authentication in progress ..."
    tailscale_hostname="$gateway_eui"-"$gateway_hostname"
    echo "Add the device $tailscale_hostname to the network"
    tailscale up --hostname="$tailscale_hostname" --authkey="$TAILSCALE_TOKEN" --ssh
else
    echo "TAILSCALE_TOKEN not define, skipping authentication"
fi
