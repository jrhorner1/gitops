#!/bin/bash

# Reference: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management

# Sanity check for root
if [ $(whoami) != "root" ]; then
    echo 'Try: sudo !!'
    exit 1
fi

# Define variables
path=/etc/apt/sources.list.d
oldrepo=packages_cloud_google_com_apt.list
repo=kubernetes.list

# Remove old source if present
if [ -f ${path}/${oldrepo} ]; then
    rm ${path}/${oldrepo}
fi

# Install prerequisite packages if not already present
apt update
apt install -y apt-transport-https ca-certificates curl

# Download the Google Cloud public signing key
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

# Add the kubernetes repository
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" > ${path}/${repo}
