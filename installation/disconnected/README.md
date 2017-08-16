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

Moved the private key (named "azureuser")
<pre>
scp -i azureuser azureuser azureuser@djofflineboot:.
ssh -i azureuser azureuser@djofflineboot
</pre>

## Move Installers to Boot Server

**NOTE:** For air-gap systems the files would need to be copied to media and physically copied to the server.

These instructions outline how I moved the files from s3 bucket down to the boot server.  

<pre>
sudo yum -y install epel-release
sudo yum install -y python2-pip

pip install --upgrade --user awscli
aws configure
</pre>

Provided ID and Key
<pre>

aws s3 sync s3://djennings . 
</pre>

Overview of items on s3://djennings
- dcos/trinity installers 
- dcos command line tool
- docker-engine rpm
- docker images
  - Trinity apps
  - local-universe 
  - nginx
- templates.tgz for Marathon-LB 
  
## Install Packages

These base packages are required and should be available from the base repo.
<pre>
sudo yum install -y ipset unzip libtool-ltdl libseccomp policycoreutils-python 
</pre>

You can use the run_cluster_cmd.sh (Bash Script) to run installer on all the nodes. 

Edit the script and set the username and pkifile.

The following command will do the installs on 1 master (m1), 3 private agents (a1,a2,a3), and 1 public agents (p1). 

<pre>
sudo bash run_cluster_cmd.sh 1 3 1 'sudo yum install -y ipset unzip libtool-ltdl libseccomp policycoreutils-python'
</pre>


The master (m1) will also need java.

<pre>
sudo bash run_cluster_cmd.sh 1 0 0 'sudo yum -y install java-1.8.0-openjdk'
</pre>



## Configure for Off Line Testing
Modified NSG for agent, public agent, master; Outbound security rules
- allow-172-17;Priority 100; Destination CIDR 172.17.0.0/16; Port Range *; Action Allow
- deny-all;Priority 110; Destination Any; Port Range *; Action Deny

After these changes the nodes should be able to access services from each other; however, they cannot access the www

## Run DCOS Installation Script

Install Pre-reqs on Boot

<pre>
sudo yum install -y ipset unzip libtool-ltdl libseccomp policycoreutils-python 
sudo rpm -Uvh docker-engine-selinux-1.13.1-1.el7.centos.noarch.rpm 
sudo rpm -Uvh docker-engine-1.13.1-1.el7.centos.x86_64.rpm 
sudo systemctl start docker
</pre>

Modify [install_dcos_disconnected.sh](install_dcos_disconnected.sh) as needed setting parameters at top of script.

<pre>
$ sudo bash install_dcos_disconnected.sh
</pre>

## Setup Local Universe

Reference these [instructions](https://github.com/mesosphere/universe/tree/version-3.x/docker/local-universe) if something goes wrong.

The Local Universe could be setup on any server.  I'm using m1 here because it's available and it works.

Move files to the m1 server.

<pre>

scp -i azureuser local-universe.tar.gz m1:.

ssh -i azureuser m1
sudo docker load -i local-universe.tar.gz
sudo su -

vi /etc/systemd/system/dcos-local-universe-http.service
</pre>

Add these lines
<pre>
[Unit]
Description=DCOS: Serve the local universe (HTTP)
After=docker.service

[Service]
Restart=always
StartLimitInterval=0
RestartSec=15
TimeoutStartSec=120
TimeoutStopSec=15
ExecStartPre=-/usr/bin/docker kill %n
ExecStartPre=-/usr/bin/docker rm %n
ExecStart=/usr/bin/docker run --rm --name %n -p 8082:80 mesosphere/universe nginx -g "daemon off;"

[Install]
WantedBy=multi-user.target
</pre>

Create registry.service

<pre>
vi /etc/systemd/system/dcos-local-universe-registry.service
</pre>

Add these line
<pre>
[Unit]
Description=DCOS: Serve the local universe (Docker registry)
After=docker.service

[Service]
Restart=always
StartLimitInterval=0
RestartSec=15
TimeoutStartSec=120
TimeoutStopSec=15
ExecStartPre=-/usr/bin/docker kill %n
ExecStartPre=-/usr/bin/docker rm %n
ExecStart=/usr/bin/docker run --rm --name %n -p 5000:5000 -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key mesosphere/universe registry serve /etc/docker/registry/config.yml

[Install]
WantedBy=multi-user.target
</pre>

Load the service
<pre>
systemctl daemon-reload
systemctl start dcos-local-universe-http
systemctl start dcos-local-universe-registry
systemctl enable dcos-local-universe-http
systemctl enable dcos-local-universe-registry
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
sudo bash run_cluster_cmd.sh 0 3 1 'sudo mkdir -p /etc/docker/certs.d/master.mesos:5000; sudo curl -o /etc/docker/certs.d/master.mesos:5000/ca.crt http://master.mesos:8082/certs/domain.crt; sudo systemctl restart docker'
</pre>

## Preload Docker Images on Agents

The following are instructions on how I deployed the docker images on the agents.

<pre>
sudo docker ps
sudo docker stop {Name of nginx App used by dcos installer}

mkdir images
mv realtime* images/
mv docker-load.sh images/
mv readme.txt images/
mv templates.tgz images/
sudo docker run -d -p 80:80 -v /home/azureuser/images:/usr/share/nginx/html:ro nginx
</pre>

Edit images/docker-load.sh as needed.

<pre>
cd ~
sudo bash run_cluster_cmd.sh 0 3 1 'curl -O boot/docker-load.sh;sudo bash docker-load.sh'
</pre>

This takes several minutes. With some adjusement the script could be paralized to load images on all servers at same time.

## Run Application Installer

Edited the [install_trinity_disconnected.sh](install_trinity_disconnected.sh) and set parameters at the top of script as needed.

For some reason; this command needs to be ran from a server within the cluster (e.g. m1). 

<pre>

scp -i azureuser install_trinity_disconnected.sh m1:.
scp -i azureuser dcos m1:.
ssh -i azureuser m1

sudo yum -y install java-1.8.0-openjdk
sudo bash install_trinity_disconnected.sh
</pre>
