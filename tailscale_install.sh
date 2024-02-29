#!/bin/sh

#DOWNLOAD_SERVER="https://download.telaqua.fr"
DOWNLOAD_SERVER="https://raw.githubusercontent.com/mickalaqua/gateway_scaleway/dev/release"

# extract the gateway information
gateway_model_name=$(uci show einfo.dev.name | grep -o "'[^']*'" | sed "s/'//g")
gateway_eui=$(uci show einfo.dev.gw_eui | grep -o "'[^']*'" | sed "s/'//g")
gateway_hostname=$HOSTNAME


# When the model name not found using uci, it means that it should be a RAK7289C or RAK7249
# Check the model name using einfo
if [ -z "$gateway_model_name" ]; then
    gateway_model_name="$(einfo show | grep DEV_NAME | sed 's/.*"\([^"]*\)".*/\1/')"
    gateway_eui="$(einfo show | grep GATEWAY_EUI | sed 's/.*"\([^"]*\)".*/\1/')"
fi

echo "gateway hostname $gateway_hostname"
echo "gateway eui $gateway_eui"
echo "gateway model name $gateway_model_name"

if [[ "$gateway_model_name" == "RAK7289C" || "$gateway_model_name" == "RAK7249" ]]; then
    echo "Using RAMIPS architecture and using sd card to store the tailscale"
    TAILSCALE_PACKET_NAME="tailscale_1.58.2-1_ramips_24kec.ipk"
    TAILSCALE_BINARY_PATH="/mnt/mmcblk0p1/tailscale/"
elif [[ "$gateway_model_name" == "RAK7289CV2" ]]; then
   echo "Using MIPSEL architecture and using flash to store the tailscale"
    TAILSCALE_PACKET_NAME="tailscale_1.58.2-1_mipsel_24kc.ipk"
    TAILSCALE_BINARY_PATH="/etc/tailscale/"
else 
    echo "Invalid model name (GATEWAY_MODEL) $gateway_model_name"
    exit 1
fi

echo "Downloading packet $PACKET_NAME"
wget -P /mnt/mmcblk0p1/tailscale $DOWNLOAD_SERVER/$PACKET_NAME

TAILSCALE_BINARY_NAME="tailscale.combined"
TAILSCALE_SERVER_BINARY_NAME="tailscale.combined.v1.60.0"
echo "Downloading binary $TAILSCALE_BINARY_NAME to $TAILSCALE_BINARY_PATH"
wget -P $TAILSCALE_BINARY_PATH $DOWNLOAD_SERVER/$TAILSCALE_SERVER_BINARY_NAME 
mv $TAILSCALE_BINARY_PATH/$TAILSCALE_SERVER_BINARY_NAME $TAILSCALE_BINARY_PATH/$TAILSCALE_BINARY_NAME


echo "Installing packet $PACKET_NAME"
opkg install /mnt/mmcblk0p1/tailscale/$TAILSCALE_PACKET_NAME
rm /mnt/mmcblk0p1/tailscale/$TAILSCALE_PACKET_NAME

# As side effect the packet installation will create
# some files for /usr/bin/tailscale and  /usr/bin/tailscaled
echo "Remove initial files /usr/bin/tailscale[d]"
rm /usr/bin/tailscale
rm /usr/bin/tailscaled

echo "Linking binaries to $TAILSCALE_BINARY_PATH/$TAILSCALE_BINARY_NAME"
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
