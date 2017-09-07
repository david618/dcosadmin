#!/bin/bash

#******************* SET THESE BEFORE RUNNING ****************************

# Set the URL to DCOS config script
DCOS_URL=dcos_generate_config.sh

# Set ADMIN_PASSWORD to "" to disable oauth Authentication; otherwise specify password for "admin" login
ADMIN_PASSWORD=""

# Set the Azure username and the name of the private PKI file for that user; the PKI file should allow access without a password
USERNAME=azureuser
PKIFILE=azureuser

# Define the number of Masters, Agents, and public Agents
NUM_MASTERS=1
NUM_AGENTS=5
NUM_PUBLIC_AGENTS=1

# Define a password for Mesospher admin account 
ADMIN_PASSWORD=adminadmin

# DOCKER RPMS
DOCKER_ENGINE_SELINUX=docker-engine-selinux-1.13.1-1.el7.centos.noarch.rpm
DOCKER_ENGINE=docker-engine-1.13.1-1.el7.centos.x86_64.rpm

# NETWORK_DEVICE (For Azure and AWS eth0 worked)
NETWORK_DEVICE=eth0

# DCOS installs in /var/lib/mesos
# For Active Agents consider adding a data drive and monting it to /var/lib/mesos
# The drive should be formated as xfs with ftype=1 (e.g. mkfs -t xfs -n ftype=1 /dev/sdc1


# Update hosts files add entries for each node
# Masters: m1, m2, ...
# Private Agents: a1, a2, ...
# Public Agents: p1, p2, ...

# Set RESET to "YES" and run to RESET
RESET=NO

#************** SCRIPT BEGINS HERE *******************************

if [ "${RESET}" == "YES" ]; then
    echo "resetting"
    rm -f *.log
    rm -f docker.repo
    rm -f overlay.conf
    rm -f override.conf
    rm -f install.sh
    rm -rf genconf
    rm -f dcos-genconf*.tar
    rm -f dcos_generate*.sh
    CONTAINER=$(docker ps | grep nginx | cut -d ' ' -f 1)
    docker stop $CONTAINER
    docker rm $CONTAINER
    echo "You might see an error message about docker; that's ok."
    exit 0
fi

# Verify PKIFILE exists
if [ ! -e $PKIFILE ]; then
    echo "This PKI file does not exist: " + $PKIFILE
    exit 3
fi

# Setup Boot Log File
boot_log="boot.log"

# Start Time
echo "Start Boot Setup"
echo "Boot Setup should take about 2 minutes. If it takes longer than 10 minutes then use Ctrl-C to exit this Script and review the log files (e.g. boot.log)"
st=$(date +%s)

# Create genconf directory
if [[ ! -e genconf ]]; then
   mkdir genconf
fi

# Create ip-detect
ip_detect="#!/usr/bin/env bash
set -o nounset -o errexit
export PATH=/usr/sbin:/usr/bin:$PATH
echo \$(ip addr show ${NETWORK_DEVICE} | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)"

echo "$ip_detect" > genconf/ip-detect

# Get IP of boot server
bootip=$(bash ./genconf/ip-detect)

# Create overlay.conf
overlay="overlay"

echo "$overlay" > overlay.conf

# Create override.conf
# Added insecure-registry; however, this is only required if you install private-repo
override="[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --storage-driver=overlay --insecure-registry ${bootip}:5000"

echo "$override" > override.conf

# Create install.bat
install="#!/bin/bash

mkdir /tmp/dcos
cd /tmp/dcos
curl -O $bootip/overlay.conf
curl -O $bootip/override.conf
curl -O $bootip/dcos_install.sh
curl -O $bootip/$DOCKER_ENGINE
curl -O $bootip/$DOCKER_ENGINE_SELINUX

groupadd nogroup

cp /tmp/dcos/overlay.conf /etc/modules-load.d/

mkdir /etc/systemd/system/docker.service.d
cp /tmp/dcos/override.conf /etc/systemd/system/docker.service.d/

rpm -Uvh /tmp/dcos/$DOCKER_ENGINE_SELINUX
rpm -Uvh /tmp/dcos/$DOCKER_ENGINE

systemctl daemon-reload
systemctl start docker
systemctl enable docker

systemctl stop dnsmasq
systemctl disable dnsmasq

sed -i -e 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
setenforce permissive

sed -i '$ i vm.max_map_count=262144' /etc/sysctl.conf
sysctl -w vm.max_map_count=262144

bash dcos_install.sh \$1"

echo "$install" > install.sh

# Copy files

cp overlay.conf /etc/modules-load.d/

mkdir /etc/systemd/system/docker.service.d

cp override.conf /etc/systemd/system/docker.service.d/

boot_log="boot.log"

# Assumes you downloaded rpm's and they arein the same directory as scripta
echo $DOCKER_ENGINE_SELINUX
rpm -Uvh $DOCKER_ENGINE_SELINUX >> $boot_log 2>&1
rpm -Uvh $DOCKER_ENGINE > $boot_log 2>&1

systemctl daemon-reload >> $boot_log 2>&1
systemctl start docker >> $boot_log 2>&1
systemctl enable docker >> $boot_log 2>&1

setenforce permissive >> $boot_log 2>&1

# Assumes DCOS has already been downloaded and is in same directory as script
dcos_cmd=$(basename $DCOS_URL)
echo $dcos_cmd

bash $dcos_cmd --help >> $boot_log 2>&1

search=$(cat /etc/resolv.conf | grep search | cut -d ' ' -f2)
ns=$(cat /etc/resolv.conf | grep nameserver | cut -d ' ' -f2)

master_list=""
for (( i=1; i<=$NUM_MASTERS; i++))
do
        server="m$i"
        ip=$(getent hosts $server | cut -d ' ' -f1)
	echo "$server $ip" >> $boot_log
	master_list="$master_list""- "$ip$'\n'	
done

echo 'search: ' + $search >> $boot_log
echo 'nameserver: ' + $ns >> $boot_log

# create the config.yaml

pw=$(bash $dcos_cmd --hash-password $ADMIN_PASSWORD)	
pwlines="""superuser_password_hash: $pw
superuser_username: admin"""

config_yaml="---
bootstrap_url: http://$bootip:80
cluster_name: 'trinity'
exhibitor_storage_backend: static
ip_detect_filename: /genconf/ip-detect
oauth_enabled: true
master_discovery: static
check_time: 'false'
dns_search: $search
master_list:
"$master_list"
resolvers:
- $ns
$pwlines"

echo "$config_yaml" > genconf/config.yaml

bash $dcos_cmd >> $boot_log 2>&1

# Copy files to serve folder 
mv install.sh genconf/serve/
mv override.conf genconf/serve/
mv overlay.conf genconf/serve/
cp $DOCKER_ENGINE_SELINUX genconf/serve/
cp $DOCKER_ENGINE genconf/serve/

RESULT=$?
if [ $RESULT -ne 0 ]; then
	echo "Move files to genconf/serve folder failed!. Check boot.log for more details"
	exit 4
fi 

# Start up the ngins image to host the installers for DCOS; Assumes you have nginx.tar.gz in the local directory
docker load < nginx.tar.gz
docker run -d -p 80:80 -v $PWD/genconf/serve:/usr/share/nginx/html:ro nginx >> $boot_log 2>&1

echo "Boot Setup Complete"
boot_fin=$(date +%s)
et=$(expr $boot_fin - $st)
echo "Time Elapsed (Seconds):  $et"
echo "This should take about 5 to 10 minutes or less. If it takes longer than 10 minutes then use Ctrl-C to exit this Script and review the log files (e.g. m1.log)"
echo "Installing DC/OS." 



DCOSTYPE=master
for (( i=1; i<=$NUM_MASTERS; i++))
do
        SERVER="m$i"
        ssh -t -t -o "StrictHostKeyChecking no" -i $PKIFILE $USERNAME@$SERVER "sudo curl -O boot/install.sh;sudo bash install.sh $DCOSTYPE" >$SERVER.log 2>$SERVER.log &
done

DCOSTYPE=slave
for (( i=1; i<=$NUM_AGENTS; i++))
do
        SERVER="a$i"
        ssh -t -t -o "StrictHostKeyChecking no" -i $PKIFILE $USERNAME@$SERVER "sudo curl -O boot/install.sh;sudo bash install.sh $DCOSTYPE" >$SERVER.log 2>$SERVER.log &
done

DCOSTYPE=slave_public
for (( i=1; i<=$NUM_AGENTS; i++))
do
        SERVER="p$i"
        ssh -t -t -o "StrictHostKeyChecking no" -i $PKIFILE $USERNAME@$SERVER "sudo curl -O boot/install.sh;sudo bash install.sh $DCOSTYPE" >$SERVER.log 2>$SERVER.log &
done


# Watch Masters; when 80 becomes active on all then end

MSUM=100
until [ "$MSUM" == "0" ]; do
    printf '.'
    sleep 5
        MSUM=0
    for (( i=1; i<=$NUM_MASTERS; i++))
    do
                SERVER="m$i"
        curl --output /dev/null --head --silent http://$SERVER:80
        MTMP=$?
            MSUM=$((MSUM + MTMP))
    done
done

dcos_fin=$(date +%s)
et2=$(expr $dcos_fin - $boot_fin) # Number of seconds it took from boot finished until DCOS ready
et3=$(expr $et + $et2)

echo "Boot Server Installation (sec): $et"
echo "DCOS Installation (sec): $et2"
echo "Total Time (sec): $et3"
echo 
echo "DCOS is Ready"


