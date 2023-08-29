#!/bin/bash

# Check if the user provided a new hostname
if [ -z "$1" ]; then
    echo "Usage: $0 <new_hostname>"
    exit 1
fi

# Set new hostname
new_hostname=$1

# Check if the script is running with root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

# Change hostname in /etc/hosts
old_hostname=$(hostname)
sed -i "s/$old_hostname/$new_hostname/g" /etc/hosts

# Change hostname in /etc/hostname
echo "$new_hostname" > /etc/hostname

# Change hostname in the Proxmox cluster configuration
if [ -f "/etc/pve/corosync.conf" ]; then
    sed -i "s/$old_hostname/$new_hostname/g" /etc/pve/corosync.conf
fi

# Change hostname in /etc/pve/storage.cfg
if [ -f "/etc/pve/storage.cfg" ]; then
    sed -i "s/$old_hostname/$new_hostname/g" /etc/pve/storage.cfg
fi

# Change hostname in /etc/pve/priv/authorized_keys
if [ -f "/etc/pve/priv/authorized_keys" ]; then
    sed -i "s/$old_hostname/$new_hostname/g" /etc/pve/priv/authorized_keys
fi

# Change hostname in /etc/postfix/main.cf
if [ -f "/etc/postfix/main.cf" ]; then
    sed -i "s/$old_hostname/$new_hostname/g" /etc/postfix/main.cf
fi

# Change hostname in /etc/mailname
if [ -f "/etc/mailname" ]; then
    echo "$new_hostname" > /etc/mailname
fi

# Copy the contents of the old hostname folder to the new hostname folder and remove the old folder in /etc/pve/nodes
if [ -d "/etc/pve/nodes/$old_hostname" ]; then
    mkdir -p "/etc/pve/nodes/$new_hostname"
    cp -a "/etc/pve/nodes/$old_hostname/." "/etc/pve/nodes/$new_hostname/"
    rm -rf "/etc/pve/nodes/$old_hostname"
fi

# Restart corosync and pve-cluster services to apply the changes
systemctl restart corosync
systemctl restart pve-cluster

# Restart postfix service to apply changes in main.cf
systemctl restart postfix

# Display the new hostname
echo "Hostname changed to: $new_hostname"

# Reboot the host to apply changes completely
echo "Rebooting the host..."
reboot