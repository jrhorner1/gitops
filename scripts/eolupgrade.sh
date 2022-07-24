#!/bin/bash

# Sanity check for root
if [ $(whoami) != "root" ]; then
    echo 'Try: sudo !!'
    exit 1
fi

# Create a backup of /etc/apt/sources.list
cp /etc/apt/sources.list /etc/apt/sources.list.backup
# Change mirror source to old-releases.ubuntu.com since we're running an EOL version
sed -E -i 's|http://ports.ubuntu.com/ubuntu-ports/?|http://old-releases.ubuntu.com/ubuntu/|g' /etc/apt/sources.list

# Update package lists from the new source and install any available updates
export DEBIAN_FRONTEND=noninteractive
apt update
apt upgrade -yq
apt dist-upgrade -yq
# Autoremove any packages no longer required
apt autoremove -yq

# Set default behavoir for release upgrader to "lts"
sed -E -i 's/Prompt=(never|normal|lts)/Prompt=normal/g' /etc/update-manager/release-upgrades

# Bypass unsupported upgrade check in `do-release-upgrade` script
sed -i 's/continue/pass/g' /usr/lib/python3/dist-packages/UpdateManager/Core/MetaRelease.py # line 315

# Perform the upgrade to 21.10 without interactive prompts, autoremove any packages no longer required
do-release-upgrade -f DistUpgradeViewNonInteractive
apt autoremove -yq

# Print release information to terminal to verify
cat /etc/*release

printf "\n%s\n\t%s\n\t%s\n\n" \
"To perform the upgrade to 22.04 LTS, reboot then run the upgrade script in a tmux session:" \
    "tmux new -s release-upgrade" \
    "sudo do-release-upgrade -f DistUpgradeViewNonInteractive"
