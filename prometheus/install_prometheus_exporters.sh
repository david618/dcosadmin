#!/bin/bash


useradd prometheus
mkdir /opt/prometheus
cd /opt/prometheus
curl -O boot/node_exporter
curl -O boot/mesos_exporter
chmod u+x node_exporter
chmod u+x mesos_exporter


if [ ! -z $(ss -ntlup | grep 5050) ]; then
  typ=master
  pt=5050
else
  typ=slave
  pt=5051
fi

mesos_exporter_env="MESOS_SERVER=${HOSTNAME}
MESOS_PORT=${pt}
MESOS_TYPE=${typ}
"

echo "${mesos_exporter_env}" > /opt/prometheus/mesos_exporter_env

chown -R prometheus. /opt/prometheus


node_exporter="Description=Node Explorer
After=network.target

[Service]
Type=simple
User=prometheus
Group=prometheus

ExecStart=/opt/prometheus/node_exporter

[Install]
WantedBy=multi-user.target"

echo "${node_exporter}" > /etc/systemd/system/node_exporter.service

mesos_exporter="Description=Mesos Explorer
After=network.target

[Service]
Type=simple
User=prometheus
Group=prometheus

EnvironmentFile=/opt/prometheus/mesos_exporter_env
ExecStart=
ExecStart=/opt/prometheus/mesos_exporter --\${MESOS_TYPE} http://\${MESOS_SERVER}:\${MESOS_PORT}

[Install]
WantedBy=multi-user.target"

echo "${mesos_exporter}" > /etc/systemd/system/mesos_exporter.service


systemctl start node_exporter
systemctl start mesos_exporter
