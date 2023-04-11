#!/bin/bash

# check if running as root
if [ $(whoami) != "root" ]; then
    echo 'Try: sudo !!'
    exit 1
fi

# VARS
TARGETDEV=/dev/sda
RASPIOS_URL=https://downloads.raspberrypi.org/raspios_lite_arm64/images
RASPIOS_DIR=raspios_lite_arm64-2023-02-22 # Directory date doesnt match image date
RASPIOS_IMG=2023-02-21-raspios-bullseye-arm64-lite.img
MNTBOOT=/mnt/boot
MNTROOT=/mnt

HOSTNAME="${HOSTNAME:=""}"
IP="${IP:=""}"
CIDR="${CIDR:="24"}"
GATEWAY="${GATEWAY:="$(echo $IP | sed -r 's/^([0-9]{,3}\.[0-9]{,3}\.[0-9]{,3}\.)[0-9]{,3}/\11/')"}"
if [ $(echo $HOSTNAME | grep "\.") == "" ]; then
    DOMAIN=${DOMAIN:=""}
else
    DOMAIN="${DOMAIN:="$(echo $HOSTNAME | sed -r 's/^[a-z0-9\-_]+\.([a-z0-9\-_.]+)$/\1/')"}"
fi
DNS_SEARCH=${DNS_SEARCH:="${DOMAIN}"}
if [[ ${IP} != "" ]]; then
    DNS_ADDRS="${DNS_ADDRS:="$(echo ${IP} | sed -r 's/([0-9]{,3}\.[0-9]{,3}\.[0-9]{,3})\.[0-9]{,3}/\1.1/')"}"
else
    DNS_ADDRS="${DNS_ADDRS:="$(grep "nameserver" /etc/resolv.conf | sed -r 's/^(nameserver|NAMESERVER) ([0-9]{,3}\.[0-9]{,3}\.[0-9]{,3}\.[0-9]{,3})/\2/' | awk '{printf("%s ", $0)}' | sed -r 's/(.+) (.+)/\1, \2/')"}"
fi
AUTH_KEYS="${AUTH_KEYS:=""}" # path to authorized keys file to copy to host

# check if pi os image exists
if [ ! -f "$RASPIOS_IMG" ]; then
    # if not: download image, checksums, and signature
    echo "Downloading signature..."
    curl -O ${RASPIOS_URL}/${RASPIOS_DIR}/${RASPIOS_IMG}.xz.sig
    echo "Downloading image..."
    curl -O ${RASPIOS_URL}/${RASPIOS_DIR}/${RASPIOS_IMG}.xz
    # Retrieve Raspberry Pi Downloads key from the Ubuntu keyserver 
    # Key ID retrieved from here: https://www.raspberrypi.org/raspberrypi_downloads.gpg.key
    RASPIOS_KEY="54C3DD610D9D1B4AF82A37758738CD6B956F460C"
    echo "Retrieving signature keys from the Ubuntu keyserver..."
    gpg --keyid-format long --keyserver hkp://keyserver.ubuntu.com --recv-keys ${RASPIOS_KEY}
    gpg --keyid-format long --list-keys --with-fingerprint ${RASPIOS_KEY}
    # Verify the downloaded image
    echo "Verifying the image..."
    gpg --keyid-format long --verify ${RASPIOS_IMG}.xz.sig ${RASPIOS_IMG}.xz
    if [ ! $? -eq 0 ]; then
        echo "Signature doesn't match."
        exit 1
    fi
    echo "Decompressing the image..."
    xz -d ${RASPIOS_IMG}.xz
fi

# check if target device exists
if [ ! -e $TARGETDEV ]; then
    echo "Plugin the ssd, nerd."
    exit 1
fi
# flash the Pi OS image
echo "Writing image to ${TARGETDEV}..."
dd status=progress if=$RASPIOS_IMG of=$TARGETDEV bs=4M

# resize the root partition and add storage partition
echo "Resizing ${TARGETDEV}2 and adding storage partition..."
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $TARGETDEV
p # print the partion table
d # delete a partition
2 # select partition 2
n # new partition
p # primary partition
2 # partion number 2
532480 # begining of the original partition 
+20G # extend partition to 20gb
p # print partition table again
n # create a new partition
p # primary partition
3 # partition number 3
 # default beginning of partition
 # default extend to the full capacity
p # print partitions
w # write changes
q # quit
EOF

# Re-read the partition table
if [[ ! -e /dev/sda3 ]]; then
    echo "Re-readting partition table..."
    partprobe
fi

# Mount target device, root first then boot
echo "Mounting ${TARGETDEV} partitions..."
mount ${TARGETDEV}2 $MNTROOT
mount ${TARGETDEV}1 $MNTBOOT

# Format storage partition with ext4 filesystem
mkfs.ext4 ${TARGETDEV}3 
# Add a label to storage volume
e2label ${TARGETDEV}3 storage

# Set the hostname
if [ ${HOSTNAME} != "" ]; then
    echo "Setting hostname to ${HOSTNAME}..."
    echo ${HOSTNAME} > $MNTROOT/etc/hostname
    sed -ri "s/raspberrypi/${HOSTNAME}/" $MNTROOT/etc/hosts
fi

# Static IP configuration
if [ ${IP} != "" ]; then
    # Disable dhcpcd
    DHCPCD_SVC=${MNTROOT}/etc/systemd/system/multi-user.target.wants/dhcpcd.service
    if [[ -f "${DHCPCD_SVC}" ]]; then
        rm ${DHCPCD_SVC}
    fi
    # Mask dhcpcd
    ln -sf ${MNTROOT}/etc/systemd/system/dhcpcd.service /dev/null
    # Configure static IP
    echo "Configuring static IP..."
    cat <<EOF > ${MNTROOT}/etc/network/interfaces
auto eth0
iface eth0 inet static 
    address ${IP}/${CIDR}
    gateway ${GATEWAY}
EOF
    # Configure DNS 
    echo "Configuring DNS..."
    echo "" > ${MNTROOT}/etc/resolv.conf
    echo "domain ${DOMAIN}" >> ${MNTROOT}/etc/resolv.conf
    for DNS_ADDR in "${DNS_ADDRS[@]}"; do
        echo "nameserver ${DNS_ADDR}" >> ${MNTROOT}/etc/resolv.conf
    done
    echo "search ${DNS_SEARCH}" >> ${MNTROOT}/etc/resolv.conf
fi

# Enable SSH on first boot
touch ${MNTBOOT}/ssh

# SSH Authorized Keys configuration
if [ ${AUTH_KEYS} != "" ]; then
    USER=pi
    USER_HOME=${MNTROOT}/home/${USER}
    SSH_DIR=${USER_HOME}/.ssh
    
    if [[ ! -d ${SSH_DIR} ]]; then
        echo "Creating ${USER} home and .ssh directories..."
        mkdir -p ${SSH_DIR}
        chown -R 1000:1000 ${USER_HOME}
        chmod 750 ${USER_HOME}
        chmod 700 ${SSH_DIR}
    fi

    echo "Configuring SSH Authorized Keys..."
    cp ${AUTH_KEYS} ${SSH_DIR}/authorized_keys
    chown 1000:1000 ${SSH_DIR}/authorized_keys
    chmod 600 ${SSH_DIR}/authorized_keys
fi

# unmount target device, boot first then root
echo "Unmounting ${TARGETDEV}..."
umount $MNTBOOT
umount $MNTROOT