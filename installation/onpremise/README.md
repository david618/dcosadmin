# On Premise Install

These notes describe the Advanced install of Mesospohere DC/OS on premise. The computers have access to Internet.  

## Network 
- Computers should be on same physical network.
- The machines should be configured with Static IP.  

**NOTE:** Don't use an IP in the DHCP servers scope. Most DHCP servers are not aware of static IP assignments and may assign the same IP to another machine; causing IP conflict.

For example: 
- DHCP server runs on 192.168.0.1 and assigns addresses from 192.168.0.2 to 192.168.0.99
- Configuring 11 servers using these IP's and Names
<pre>
192.168.0.130   boot.example.com boot
192.168.0.131   m1.example.com m1
192.168.0.141   a1.example.com a1
192.168.0.142   a2.example.com a2
192.168.0.143   a3.example.com a3
192.168.0.144   a4.example.com a4
192.168.0.145   a5.example.com a5
192.168.0.146   a6.example.com a6
192.168.0.147   a7.example.com a7
192.168.0.148   a8.example.com a8
192.168.0.151   p1.example.com p1
</pre>
- If you have an internal DNS; you can add these to the DNS server; otherwise, add these entries to /etc/hosts on each server
- Be sure the DNS resolves and is resolvable from the network (e.g. DNS 192.168.0.1 and Gateway 192.168.0.1)


## My Virtual Box Test Configuration

Created Virutal Boxes on Three computers (t5810, xps8700, djennings)

- t5810 (8 cpu; 32GB mem)
  - boot (2 cpu; 4GB mem)
  - m1 (4 cpu; 4GB mem)
  - p1 (4 cpu; 4GB mem)
  - a1,a2,a3 (4 cpu; 6GB mem)

- xps8700 (8 cpu; 24GB mem)
  - a4,a5,a6 (4 cpu; 7GB mem)

- djennings (8 cpu, 16GB mem)
  - a7,a8 (4cpu, 7GB mem)

It is important to leave some mem for the base OS; otherwise the computer will become unresponsive. With multiple VM's you can allocate more virtual cpu's than the number of physcial cpu's (e.g. You have a 8 cpus and you create 4 VM's with 4 cpu's each). The physical cpu's are time shared between the VM's; therefore, at some point you will exhaust the computers physcial CPU's.


## Start with OS Install
- Download the DVD iso from [centos.org](https://www.centos.org/download/)
- Burn the iso image to DVD or [USB](https://wiki.centos.org/HowTos/InstallFromUSBkey)
- Use Minimal install 
- Configure using standard partions instead of LVM; be sure to give root drive most of the disk space
- Optionally add a second "Data" drive

## Post Install Configuration

The following commands
- Install bash-completion
- Stop and disable firewall
- Disable selinux
- Modify sudoers to allow wheel group so sudo without password.

As root
<pre>
yum -y install bash-completion
systemctl stop firewalld.service
systemctl disable firewalld.service
sed -i s/=enforcing/=disabled/g /etc/selinux/config
sed -i -e 's/^%wheel/#%wheel/g' -e 's/^# %wheel/%wheel/g' /etc/sudoers
</pre>

You can configure neworking with commands like these.

As root
<pre>
nmcli connection modify enp0s8 ipv4.addresses 192.168.56.141/24
nmcli connection modify enp0s8 ipv4.method manual
nmcli connection modify enp0s8 connection.autoconnect true
hostnamectl set-hostname a1.example.com
</pre>

### Disable Other Network Cards
My computers had another network card that I needed to disable.

As root
<pre>
sudo su -
nmcli connection modify enp0s3 connection.autoconnect false
nmcli connection modify enp0s8 ipv4.dns 192.168.0.1
nmcli connection modify enp0s8 ipv4.gateway 192.168.0.1
reboot
</pre>


**NOTE:** Be sure to add entries to /etc/hosts if you don't have a DNS configured.

## Create Centos User

Create a key pair if you don't have one.

Run the following command.  Change the path to the key (e.g. /home/david/centos.pem). 

<pre>
$ ssh-keygen
</pre>

Leave password blank.

If you have a private key with a password remove the password.

<pre>
mv centos.pem centos.pem.withpassword
openssl rsa -in centos.pem.withpassword -out centos.pem
</pre>

Now on each server run these commands as root to create the user and configure pki access.

<pre>
useradd centos
usermod -aG wheel centos
mkdir /home/centos/.ssh/
chown centos. /home/centos/.ssh/
chmod 700 /home/centos/.ssh
cp centos.pem.pub /home/centos/.ssh/authorized_keys
chown centos. /home/centos/.ssh/authorized_keys
</pre>

You should now be able to login to the servers with the pki key.

<pre>
ssh -i centos.pem centos@m1
</pre>

## Install DCOS

Copy your private key to the boot server.

<pre>
scp -i centos.pem centos.pem centos@boot:~
</pre>

Copy the [install_dcos_onpremise.sh](install_dcos_onpremise.sh) script to the boot server.

<pre>
scp -i centos.pem install_dcos_onpremise.sh centos@boot:~
</pre>

SSH to the boot server. Edit the script. At the top you'll need to set some parameters.

<pre>
ip -r -o addr
1: lo    inet 127.0.0.1/8 scope host lo\       valid_lft forever preferred_lft forever
2: enp0s3    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic enp0s3\       valid_lft 80499sec preferred_lft 80499sec
3: enp0s8    inet 192.168.0.151/24 brd 192.168.0.255 scope global enp0s8\       valid_lft forever preferred_lft forever
4: docker0    inet 172.17.0.1/16 scope global docker0\       valid_lft forever preferred_lft forever
6: spartan    inet 198.51.100.1/32 scope global spartan\       valid_lft forever preferred_lft forever
6: spartan    inet 198.51.100.2/32 scope global spartan\       valid_lft forever preferred_lft forever
6: spartan    inet 198.51.100.3/32 scope global spartan\       valid_lft forever preferred_lft forever
8: d-dcos    inet 9.0.6.129/25 scope global d-dcos\       valid_lft forever preferred_lft forever
9: vtep1024    inet 44.128.0.7/20 scope global vtep1024\       valid_lft forever preferred_lft forever
</pre>

The network device for this system is enp0s8.  

Run the script.

<pre>
$ sudo bash install_dcos_onpremise.sh 1 8 1 
1) Latest Community Edition  3) Version 1.9.0
2) Version 1.9.1	     4) Custom
Which version of DCOS do you want to install: 1
Enter OS Username (centos): 
Enter PKI Filename (centos.pem): 

Install Details
DCOS_URL:  https://downloads.dcos.io/dcos/stable/dcos_generate_config.sh
OS Username:  centos
PKI Filename:  centos.pem
Number of Masters:  1
Number of Agents:  8
Number of Public Agents: 1

Press Enter to Continue or Ctrl-C to abort

Start Boot Setup
Boot Setup should take about 5 minutes. If it takes longer than 10 minutes then use Ctrl-C to exit this Script and review the log files (e.g. boot.log)
master_list
- 192.168.0.131

Boot Setup Complete
Time Elapsed (Seconds):  190

Installing DC/OS.
This should take about 5 minutes or less. If it takes longer than 10 minutes then use Ctrl-C to exit this Script and review the log files (e.g. m1.log)
.................................................................................Boot Server Installation (sec): 190
DCOS Installation (sec): 406
Total Time (sec): 596

DCOS is Ready
</pre>

## Summary
The install completed for my on premise servers and I was able to access the DC/OS dashboard. The Dasbboard showed all 9 of my nodes up and running.  



