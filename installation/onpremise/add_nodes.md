# Add Node to Existing Cluster

## Copy pub key to the SERVER
<pre>
scp -i centos.pem.pub root@(SERVER):~
</pre>

## Install software 
<pre>
ssh root@(SERVER)
systemctl stop firewalld.service
systemctl disable firewalld.service
sed -i s/=enforcing/=disabled/g /etc/selinux/config
sed -i -e 's/^%wheel/#%wheel/g' -e 's/^# %wheel/%wheel/g' /etc/sudoers
</pre>

## Create and Configure User
<pre>
useradd centos
usermod -aG wheel centos
mkdir /home/centos/.ssh/
chown centos. /home/centos/.ssh/
chmod 700 /home/centos/.ssh
cp centos.pem.pub /home/centos/.ssh/authorized_keys
chown centos. /home/centos/.ssh/authorized_keys
</pre>

## Reboot Required SELinux Change
<pre>
reboot
</pre>

## Update /etc/hosts file 

On boot then run script to push to other servers.

Below is an example script.  This script assumes IP's start with 10 and have short name (e.g. m1) at end

<pre>
#!/bin/bash

for a in $(cat /etc/hosts | grep ^10 | cut -d ' ' -f4 | grep -v boot)
do
        echo Updating /etc/hosts on $a
        scp -i centos.pem /etc/hosts centos@${server}:~
        ssh -t -i centos.pem centos@${server}  'sudo cp /home/centos/hosts /etc/hosts'
done
</pre>

## Install DC/OS
<pre>
sudo curl -O boot/install.sh

sudo bash install.sh slave
</pre>

To add a public agent change "slave" to "slave_public".  

