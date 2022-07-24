#!/bin/bash

# Sanity check for root
if [ $(whoami) != "root" ]; then
    echo 'Try: sudo !!'
    exit 1
fi

# Change mirror source to old-releases.ubuntu.com since we're running an EOL version
sed -i 's|http://ports.ubuntu.com/ubuntu-ports/|http://old-releases.ubuntu.com/ubuntu/|g' /etc/apt/sources.list

# Update package lists from the new source and install any available updates
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
# Autoremove any packages no longer required
apt autoremove -y

# Bypass unsupported upgrade check in `do-release-upgrade` script
sed -i 's/continue/pass/g' /usr/lib/python3/dist-packages/UpdateManager/Core/MetaRelease.py # line 315

printf "\n%s\n\t%s\n\t%s\n\n" \
"To perform the upgrade, create a tmux session and run the interactive upgrade script:" \
    "tmux new -s release-upgrade" \
    "sudo do-release-upgrade"
