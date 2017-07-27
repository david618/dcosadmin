# Disconnected Installation of DCOS

These instructions cover the installation of DCOS 1.9.1 EE on servers not connected to the Internet.  

They follow the instructions for [Advanced](https://docs.mesosphere.com/1.9/installing/custom/advanced/) installation of DC/OS.

## Create Servers
- Operation System: CentOS 7.3
  -- Azure: CentOS-based 7.3  Publisher Rogue Wave Software (formerly OpenLogic)
  -- AWS: https://wiki.centos.org/Cloud/AWS
- Created a "boot" server to support installation
- Created Master server(s)
- Created Private agents
- Created Public agent(s)

The installers assumes the servers can be referred to by short names. 

In Azure this is accomplished via the template; for AWS you can add entries to /etc/hosts file on the boot server.  
- Masters named m1, m2, ...
- Private Agents named a1, a2, ...
- Public Agents named p1, p2, ...

To facilitate creation of server I created an Azure ARM template and AWS Cloudformation template.

The testing outlined in below were done on Azure. 
- Resource Group: djoffline
- Boot Server Name: djofflineboot

The specfic command lines provided are intended as a guide; they will need to be tweaked for specific installation and testing.

**NOTE**: Used [run_cluster_cmd.sh](../../scripts/run_cluster_cmd.sh) to facilitate running commands on all the agents.

Moved the private key (named "azureuser")
<pre>
scp -i azureuser azureuser azureuser@djofflineboot:.
ssh -i azureuser azureuser@djofflineboot
</pre>


## Move Installers to Boot Server

**NOTE:** For air-gap systems the files would need to be copied to media and physically copied to the server.

These instructions outline how I moved the files from s3 bucket down to the boot server.  

**NOTE:** I created a folder in /mnt/resources because Azure root folder was very small for my DS3_V2 instance.

<pre>
sudo yum -y install epel-release
sudo yum install -y python2-pip

pip install --upgrade --user awscli
aws configure
</pre>

Provided ID and Key
<pre>

sudo mkdir /mnt/resources/s3
sudo chown azureuser. /mnt/resource/s3
cd /mnt/resource/s3
aws s3 sync s3://djennings . 
</pre>

The items in s3
- dcos/trinity installers 
- dcos command line tool
- docker-engine rpm
- docker images
  - Trinity apps
  - local-universe 
  - nginx
- templates.tgz for Marathon-LB 
- 
  
## Install Packages

These base packages are required and should be available from the base repo.
<pre>
sudo yum install -y ipset unzip libtool-ltdl libseccomp policycoreutils-python 
</pre>

You can use the run_cluster_cmd.sh (Bash Script) to run installer on all the nodes. I put a copy of the script in my home folder where my private key was also at.

Edit the script and set the username and pkifile.

The following command will do the installs on 1 master (m1), 5 private agents (a1,a2,a3), and 1 public agents (p1). 

<pre>
sudo bash run_cluster_cmd.sh 1 3 1 'sudo yum install -y ipset unzip libtool-ltdl libseccomp policycoreutils-python'
</pre>

## Configure for Off Line Testing
Modified NSG for agent, public agent, master; Outbound security rules
- allow-172-17;Priority 100; Destination CIDR 172.17.0.0/16; Port Range *; Action Allow
- deny-all;Priority 110; Destination Any; Port Range *; Action Deny

After these changes the nodes should be able to access services from each other; however, they cannot access the www

## Run DCOS Installation Script

Modified [install_dcos_disconnected.sh](install_dcos_disconnected.sh) as needed setting parameters at top of script.

<pre>
$ sudo bash install_dcos_disconnected.sh
</pre>

## Setup Local Universe

Move files to m1 (Master Server 1)

<pre>
$ scp -i azureuser local-universe.tar.gz m1:.
$ ssh -i azureuser m1


$ sudo docker load -i local-universe.tar.gz

$ sudo su -

# vi /etc/systemd/system/dcos-local-universe-http.service
[Unit]
Description=DCOS: Serve the (http) local universe
After=docker.service

[Service]
Restart=always
StartLimitInterval=0
RestartSec=15
TimeoutStartSec=120
TimeoutStopSec=15
ExecStart=/usr/bin/docker run --rm --name %n -p 8082:80 mesosphere/universe nginx -g "daemon off;"
:wq

# vi /etc/systemd/system/dcos-local-universe-registry.service
[Unit]
Description=DCOS: Serve the (http) local universe
After=docker.service

[Service]
Restart=always
StartLimitInterval=0
RestartSec=15
TimeoutStartSec=120
TimeoutStopSec=15
ExecStart=/usr/bin/docker run --rm --name %n -p 5000:5000 -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key mesosphere/universe registry serve /etc/docker/registry/config.yml
:wq

# systemctl daemon-reload

# systemctl start dcos-local-universe-http
# systemctl start dcos-local-universe-registry

# systemctl enable dcos-local-universe-http
# systemctl enable dcos-local-universe-registry

</pre>

From Enterprise DCOS WebUI

Settings

Package Repositories

Remove the default Universe

Add Repository
- Local Universe
- http://master.mesos:8082/repo
- 0

On each Private and Public Agent

<pre>
# mkdir -p /etc/docker/certs.d/master.mesos:5000
# curl -o /etc/docker/certs.d/master.mesos:5000/ca.crt http://master.mesos:8082/certs/domain.crt
# systemctl restart docker
</pre>

Return to boot server

Using cluster_cmd_azure.sh 

<pre>
$ sudo bash cluster_cmd_azure.sh 0 5 1 'sudo mkdir -p /etc/docker/certs.d/master.mesos:5000; sudo curl -o /etc/docker/certs.d/master.mesos:5000/ca.crt http://master.mesos:8082/certs/domain.crt; sudo systemctl restart docker'
</pre>

## Preload Docker Images on Agents

The following are instructions on how I deployed the docker images on the agents.

<pre>
# docker ps
# docker stop {Name of nginx App used by dcos installer}

# sudo docker run -d -p 80:80 -v /mnt/resource/azureuser/:/usr/share/nginx/html:ro nginx
</pre>

Created script to import the installer

<pre>
# vi /mnt/resource/azureuser/load_images.sh
#!/bin/bash

mkdir /mnt/resource/azureuser
chown azureuser. /mnt/resource/azureuser

cd /mnt/resource/azureuser
curl -sO http://boot/analysis.tar.gz
curl -sO http://boot/map.tar.gz
curl -sO http://boot/monitoring.tar.gz
curl -sO http://boot/receiver.tar.gz
curl -sO http://boot/service.tar.gz
curl -sO http://boot/sit.tar.gz
curl -sO http://boot/taskmanager.tar.gz
curl -sO http://boot/proxy.tar.gz

systemctl stop dcos-docker-gc.timer

docker load -i analysis.tar.gz
docker load -i map.tar.gz
docker load -i monitoring.tar.gz
docker load -i receiver.tar.gz
docker load -i service.tar.gz
docker load -i sit.tar.gz
docker load -i taskmanager.tar.gz
docker load -i proxy.tar.gz
:wq
</pre>

On each agent

<pre>
curl -O boot/load_images.sh
sudo bash load_images.sh 
</pre>

Using cluster_cmd_azure.sh

<pre>
sudo bash cluster_cmd_azure.sh 0 5 0 'curl -O boot/load_images.sh;sudo bash load_images.sh'
</pre>

This took several minutes

## Run Application Installer

Edited the [install_trinity_disconnected.sh](install_trinity_disconnected.sh) and set parameters at the top of script as needed.

<pre>
$ scp -i azureuser install_trinity_disconnected.sh m1:.
$ scp -i azureuser dcos m1:.
$ ssh -i azureuser m1

$ sudo bash install_trinity_disconnected.sh
</pre>
