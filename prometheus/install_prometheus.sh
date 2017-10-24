#!/bin/bash

if [ "$#" -ne 5 ];then
        echo "Usage: $0 <username> <pkifile> <numMasters> <numAgents> <numPublicAgents>"
        echo "Example: $0 centos centos.pem 1 3 1"
        exit 99
fi

USERNAME=$1
PKIFILE=$2
NUM_MASTERS=$3
NUM_AGENTS=$4
NUM_PUBLIC_AGENTS=$5

if [ ! -e $PKIFILE ]; then
        echo "This PKI file does not exist: " + $PKIFILE
        exit 3
fi

re='^[0-9]+$'

if ! [[ $NUM_MASTERS =~ $re ]] ; then
        echo "Usage: $0 <numMasters> <numAgents> <numPublicAgents>"
        echo "numMasters must be a number"
        exit 91
fi

if ! [[ $NUM_AGENTS =~ $re ]] ; then
        echo "Usage: $0 <numMasters> <numAgents> <numPublicAgents>"
        echo "numAgents must be a number"
        exit 92
fi

if ! [[ $NUM_PUBLIC_AGENTS =~ $re ]] ; then
        echo "Usage: $0 <numMasters> <numAgents> <numPublicAgents>"
        echo "numPublicAgents must be a number"
        exit 93
fi

yum -y install httpd mod_ssl

sed -i -e 's/Listen 80/Listen 81/g' /etc/httpd/conf/httpd.conf

mod_proxy="ProxyRequests off
ProxyPass /graph http://boot:9090/graph
ProxyPassReverse /graph http://boot:9090/graph
ProxyPass /static http://boot:9090/static
ProxyPassReverse /static http://boot:9090/static
ProxyPass /api http://boot:9090/api
ProxyPassReverse /api http://boot:9090/api"

echo "${mod_proxy}" > /etc/httpd/conf.d/proxy.conf

systemctl start httpd
systemctl enable httpd

# Install Exporters (node and mesos on DC/OS servers)
useradd prometheus
mkdir /opt/prometheus
cd /opt/prometheus
curl -O https://s3.us-east-2.amazonaws.com/djenningsrt/mesos_exporter.tgz
curl -O https://s3.us-east-2.amazonaws.com/djenningsrt/node_exporter-0.14.0.linux-amd64.tar.gz
curl -O https://s3.us-east-2.amazonaws.com/djenningsrt/prometheus-1.7.1.linux-amd64.tar.gz

# Unpack 
tar xvzf mesos_exporter.tgz
tar xvzf node_exporter-0.14.0.linux-amd64.tar.gz
tar xvzf prometheus-1.7.1.linux-amd64.tar.gz

ln -s prometheus-1.7.1.linux-amd64 prometheus
chown -R prometheus. prometheus-1.7.1.linux-amd64/
chown -h prometheus. prometheus

cd -
cp /opt/prometheus/node_exporter-0.14.0.linux-amd64/node_exporter genconf/serve/
cp /opt/prometheus/mesos_exporter genconf/serve/

install_exporters="#!/bin/bash

useradd prometheus
mkdir /opt/prometheus
cd /opt/prometheus
curl -O boot/node_exporter
curl -O boot/mesos_exporter
chmod u+x node_exporter
chmod u+x mesos_exporter

if [ ! -z \$(ss -ntlup | grep 5050) ]; then
  typ=master
  pt=5050
else
  typ=slave
  pt=5051
fi

mesos_exporter_env=\"MESOS_SERVER=\${HOSTNAME}
MESOS_PORT=\${pt}
MESOS_TYPE=\${typ}
\"

echo \"\${mesos_exporter_env}\" > /opt/prometheus/mesos_exporter_env

chown -R prometheus. /opt/prometheus

node_exporter=\"[Unit]
Description=Node Explorer
After=network.target

[Service]
Type=simple
User=prometheus
Group=prometheus

ExecStart=/opt/prometheus/node_exporter

[Install]
WantedBy=multi-user.target\"

echo \"\${node_exporter}\" > /etc/systemd/system/node_exporter.service

mesos_exporter=\"[Unit]
Description=Mesos Explorer
After=network.target

[Service]
Type=simple
User=prometheus
Group=prometheus

EnvironmentFile=/opt/prometheus/mesos_exporter_env
ExecStart=
ExecStart=/opt/prometheus/mesos_exporter --\\\${MESOS_TYPE} http://\\\${MESOS_SERVER}:\\\${MESOS_PORT}

[Install]
WantedBy=multi-user.target\"

echo \"\${mesos_exporter}\" > /etc/systemd/system/mesos_exporter.service


systemctl start node_exporter
systemctl start mesos_exporter
"

echo "${install_exporters}" > genconf/serve/install_prometheus_exporters.sh

CMD="sudo curl -O boot/install_prometheus_exporters.sh;sudo bash install_prometheus_exporters.sh"

PCF=/opt/prometheus/prometheus/prometheus.yml


OFFSET=0
PREFIX="m"
for (( i=1; i<=$NUM_MASTERS; i++))
do
        SERVER=${PREFIX}$(( $OFFSET + $i ))
        echo $SERVER
        ssh -t -t -o "StrictHostKeyChecking no" -i $PKIFILE $USERNAME@$SERVER "$CMD"
        echo "  - job_name: '${SERVER}'" >> ${PCF}
        echo "    static_configs:" >> ${PCF}
	echo "      - targets: ['${SERVER}:9105','${SERVER}:9100']" >> ${PCF}
done

PREFIX="a"
for (( i=1; i<=$NUM_AGENTS; i++))
do
        SERVER=${PREFIX}$(( $OFFSET + $i ))
        echo $SERVER
        ssh -t -t -o "StrictHostKeyChecking no" -i $PKIFILE $USERNAME@$SERVER "$CMD"
        echo "  - job_name: '${SERVER}'" >> ${PCF}
        echo "    static_configs:" >> ${PCF}
	echo "      - targets: ['${SERVER}:9105','${SERVER}:9100']" >> ${PCF}
done

PREFIX="p"
for (( i=1; i<=$NUM_PUBLIC_AGENTS; i++))
do
        SERVER=${PREFIX}$(( $OFFSET + $i ))
        echo $SERVER
        ssh -t -t -o "StrictHostKeyChecking no" -i $PKIFILE $USERNAME@$SERVER "$CMD"
        echo "  - job_name: '${SERVER}'" >> ${PCF}
        echo "    static_configs:" >> ${PCF}
	echo "      - targets: ['${SERVER}:9105','${SERVER}:9100']" >> ${PCF}
done


prom_service="[Unit]
Description=Prometheus
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
WorkingDirectory=/opt/prometheus/prometheus
ExecStart=/opt/prometheus/prometheus/prometheus -config.file /opt/prometheus/prometheus/prometheus.yml

[Install]
WantedBy=multi-user.target"

echo "${prom_service}" > /etc/systemd/system/prometheus.service

systemctl enable prometheus.service
systemctl start prometheus.service
