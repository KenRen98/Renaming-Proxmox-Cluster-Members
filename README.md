# Renaming-Proxmox-Cluster-Members
Original Author: Michael, see README.MD for original poster.  
Thank you so much for saving our life.

**[Click ME](https://murfy.nz/2023/04/18/renaming-proxmox-cluster-members/) to see original post, this GitHub Repo is in case the page gets deleted.**  
  
**Please Buy him a coffee guys:**  
[![Buy him a Coffee Guys](https://github.com/KenRen98/Renaming-Proxmox-Cluster-Members/blob/main/Buy%20him%20a%20coffee.png?raw=true)](https://www.buymeacoffee.com/murfy)  
**https://www.buymeacoffee.com/murfy  
(The link got from the original site, tell me if it has been updated.)**

## His Solution:  
Posting this here because I have not actually seen viable answers on the internet. It is difficult, but possible to rename cluster members. Create a file “hostname.sh” in the root directory of your cluster member:  
```
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
```
Then **ensure that all VM’s and Containers are evicted!** This is vital. Migrate all of them to another cluster member so you have nothing even shut down.

“chmod +x hostname.sh” to set permissions on this script then run it as “./hostname.sh newhostname” where “newhostname” is the hostname you wish to change to. The host will reboot regardless and should appear back in your Proxmox control panel under the new hostname.

If you get SSH errors on the other cluster members when migrating VM/CT’s back simply restart pveproxy on them (systemctl restart pveproxy) which should fix things up. You’ll need to also adjust your HA settings to include your new host.

Once you’ve confirmed everything to be working just clear out /etc/pve/nodes of your old hostnames – sometimes these can stay and get synced by other cluster members.
