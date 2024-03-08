#!/bin/sh

if [ -z "${GIT_BRANCH}" ]; then
    GIT_BRANCH="main"
fi

echo "Using git branch $GIT_BRANCH"
DOWNLOAD_SERVER="https://raw.githubusercontent.com/Telaqua/gateway_tailscale/$GIT_BRANCH/release"

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

# the gateway architecture also depend of the firmware version
# I beleive that version before 2.2.x use arch ramips_24kec
# version 2.2.x use arch mipsel_24kc
arch=$(opkg print-architecture | sed -n 's/.* \([^ ]*mips[^ ]*\) .*/\1/p')
TAILSCALE_PACKET_NAME="tailscale_1.58.2-1_$arch.ipk"

if [[ "$gateway_model_name" == "RAK7289C" || "$gateway_model_name" == "RAK7249" ]]; then
    echo "Using RAMIPS architecture and using sd card to store the tailscale"
    TAILSCALE_BINARY_PATH="/mnt/mmcblk0p1/tailscale"
    TAILSCALE_SERVER_BINARY_NAME="tailscale.combined.v1.60.0"
elif [[ "$gateway_model_name" == "RAK7289CV2" ]]; then
   echo "Using MIPSEL architecture and using flash to store the tailscale"
    TAILSCALE_BINARY_PATH="/etc/tailscale"

    # This binary is compiled using GOMIPS=softfloat option
    TAILSCALE_SERVER_BINARY_NAME="tailscale.combined.v1.60.0-softfloat"
else 
    echo "Invalid model name (GATEWAY_MODEL) $gateway_model_name"
    exit 1
fi

mkdir -p /mnt/mmcblk0p1/tailscale

# delete old packet, in case it already exist
rm /mnt/mmcblk0p1/tailscale/$TAILSCALE_PACKET_NAME

echo "Downloading packet $TAILSCALE_PACKET_NAME"
wget -P /mnt/mmcblk0p1/tailscale $DOWNLOAD_SERVER/$TAILSCALE_PACKET_NAME

TAILSCALE_BINARY_NAME="tailscale.combined"


# delete old binary, in case it already exist
rm $TAILSCALE_BINARY_PATH/$TAILSCALE_BINARY_NAME
rm $TAILSCALE_BINARY_PATH/$TAILSCALE_SERVER_BINARY_NAME
rm /mnt/mmcblk0p1/tailscale/$TAILSCALE_SERVER_BINARY_NAME

mkdir -p $TAILSCALE_BINARY_PATH

# Downloading the binary on the flash is longer than downloading it on SD Card and
# then moving it on flash memory
echo "Downloading binary $TAILSCALE_BINARY_NAME to $TAILSCALE_BINARY_PATH"
wget -P /mnt/mmcblk0p1/tailscale/ $DOWNLOAD_SERVER/$TAILSCALE_SERVER_BINARY_NAME 

mv /mnt/mmcblk0p1/tailscale/$TAILSCALE_SERVER_BINARY_NAME $TAILSCALE_BINARY_PATH/$TAILSCALE_BINARY_NAME
chmod +x $TAILSCALE_BINARY_PATH/$TAILSCALE_BINARY_NAME


echo "Installing packet $TAILSCALE_PACKET_NAME"
opkg install /mnt/mmcblk0p1/tailscale/$TAILSCALE_PACKET_NAME
rm /mnt/mmcblk0p1/tailscale/$TAILSCALE_PACKET_NAME

# As side effect the packet installation will create
# some files for /usr/bin/tailscale and  /usr/bin/tailscaled
echo "Remove initial files /usr/bin/tailscale[d]"
rm /usr/sbin/tailscale
rm /usr/sbin/tailscaled

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
    

    # Replace underscores with dashes 
    # as underscore are not allowed in dns name
    gateway_hostname="${gateway_hostname//_/-}"

    tailscale_hostname="$gateway_eui"."$gateway_hostname"
    echo "Add the device $tailscale_hostname to the network"
    tailscale up --hostname="$tailscale_hostname" --authkey="$TAILSCALE_TOKEN" --ssh
else
    echo "TAILSCALE_TOKEN not define, skipping authentication"
fi
