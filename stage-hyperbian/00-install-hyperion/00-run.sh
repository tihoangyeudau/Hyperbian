#!/bin/bash -e

# Select the appropriate download path
HYPERION_DOWNLOAD_URL="https://github.com/tihoangyeudau/hyperion.ng/releases/download"
HYPERION_RELEASES_URL="https://api.github.com/repos/tihoangyeudau/hyperion.ng/releases"

# Get the latest version
HYPERION_LATEST_VERSION=$(curl -sL "$HYPERION_RELEASES_URL" | grep "tag_name" | head -1 | cut -d '"' -f 4)
HYPERION_RELEASE=$HYPERION_DOWNLOAD_URL/$HYPERION_LATEST_VERSION/Ambilight-WiFi-$HYPERION_LATEST_VERSION-Linux-armv6l.deb

# Download latest release
echo 'Downloading Ambilight WiFi + rpi fan ........................'
mkdir -p "$ROOTFS_DIR"/tmp
curl -L $HYPERION_RELEASE --output "$ROOTFS_DIR"/tmp/ambilight-wifi.deb
curl -sS -L --get https://github.com/tihoangyeudau/rpi-fan/releases/download/1.0.0/rpi-fan.tar.gz | tar --strip-components=0 -C ${ROOTFS_DIR}/usr/share/ rpi-fan -xz

# Copy service file
cp rpi-fan.service ${ROOTFS_DIR}/etc/systemd/system/rpi-fan.service

# Enable SPI and force HDMI output
sed -i "s/^#dtparam=spi=on.*/dtparam=spi=on/" ${ROOTFS_DIR}/boot/config.txt
sed -i "s/^#hdmi_force_hotplug=1.*/hdmi_force_hotplug=1/" ${ROOTFS_DIR}/boot/config.txt

# Modify /usr/lib/os-release
sed -i "s/Raspbian/HyperBian/gI" ${ROOTFS_DIR}/usr/lib/os-release
sed -i "s/^NAME=.*$/NAME=\"HyperBian ${HYPERION_LATEST_VERSION}\"/g" ${ROOTFS_DIR}/usr/lib/os-release
sed -i "s/^VERSION=.*$/VERSION=\"${HYPERION_LATEST_VERSION}\"/g" ${ROOTFS_DIR}/usr/lib/os-release
sed -i "s/^HOME_URL=.*$/HOME_URL=\"https:\/\/www.facebook.com\/rainbowmusicled\/\"/g" ${ROOTFS_DIR}/usr/lib/os-release

# Custom motd
rm "${ROOTFS_DIR}"/etc/motd
rm "${ROOTFS_DIR}"/etc/update-motd.d/10-uname
install -m 755 files/motd-hyperbian "${ROOTFS_DIR}"/etc/update-motd.d/10-hyperbian

# Remove the "last login" information
sed -i "s/^#PrintLastLog yes.*/PrintLastLog no/" ${ROOTFS_DIR}/etc/ssh/sshd_config

on_chroot << EOF
echo 'Installing Ambilight WiFi ........................'
apt install /tmp/ambilight-wifi.deb
rm /tmp/ambilight-wifi.deb
echo 'Registering Ambilight WiFi ........................'
systemctl -q enable ambilightwifid@.service
systemctl -q enable rpi-fan.service
EOF