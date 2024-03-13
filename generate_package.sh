#!/bin/sh

export package=tailscale_1.58.2-1_mipsel_24kc.ipk
export release=23.05.2
export arch=mipsel_24kc 

rm -rf "${package}"
rm -rf ${package%%.ipk}

# download .ipk
wget https://downloads.openwrt.org/releases/${release}/packages/${arch}/packages/${package}
mkdir ${package%%.ipk}
pushd ${package%%.ipk}
tar -xvf ../${package}

# data
mkdir data
pushd data
tar -xvf ../data.tar.gz

# Change respawn parameter to keep the process running
sed -i "s/procd_set_param respawn.*/procd_set_param respawn 5 10 0/g" etc/init.d/tailscale
echo -e '#!/bin/sh\ntrue\n' > usr/sbin/${package%%_*}
tar --numeric-owner --group=0 --owner=0 -czf ../data.tar.gz *
popd
size=$(du -sb data | awk '{ print $1 }')
rm -rf data

# control
mkdir control
pushd control
tar -xvf ../control.tar.gz
sed -i "s/^Installed-Size.*/Installed-Size: ${size}/g" control

tar --numeric-owner --group=0 --owner=0 -czf ../control.tar.gz *
popd


mkdir ../release
TAILSCALE_MIPS_PACKAGE_NAME="tailscale_1.58.2-1_mipsel_24kc.ipk"
TAILSCALE_RAMIPS_PACKAGE_NAME="tailscale_1.58.2-1_ramips_24kec.ipk"
# repack .ipk
tar --numeric-owner --group=0 --owner=0 -cvzf ../release/${TAILSCALE_MIPS_PACKAGE_NAME} debian-binary data.tar.gz control.tar.gz


pushd control
# Generate ramips packages
# Change architecture to ramips
sed -i 's/Architecture: mipsel_24kc/Architecture: ramips_24kec/' control

tar --numeric-owner --group=0 --owner=0 -czf ../control.tar.gz *
popd
rm -rf control

# repack .ipk
tar --numeric-owner --group=0 --owner=0 -cvzf ../release/${TAILSCALE_RAMIPS_PACKAGE_NAME} debian-binary data.tar.gz control.tar.gz
popd

rm -rf "${package}"
rm -rf ${package%%.ipk}
