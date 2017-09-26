# Prometheus

Metrics tool: [prometheus](https://prometheus.io)

GitHub: [prometheus](https://github.com/prometheus/prometheus)

Mesos Exporter: [mesos_exporter](https://github.com/mesosphere/mesos_exporter)


History
- Roots at Google as Bogmon
- Started in 2012; version 1 2016

[Docs](https://prometheus.io/docs/introduction/overview/)

[An introduction to monitoring and alerting with timeseries at scale, with Prometheus](https://www.youtube.com/watch?v=gNmWzkGViAY)

[Monitoring a Machine with Prometheus: A Brief Introduction](https://www.youtube.com/watch?v=WUkNnY65htQ)

[Course on Prometheus](http://training.robustperception.io/)


## Install 

Download
<pre>
curl -OL https://github.com/prometheus/prometheus/releases/download/v1.7.1/prometheus-1.7.1.linux-amd64.tar.gz
curl -OL https://github.com/prometheus/node_exporter/releases/download/v0.14.0/node_exporter-0.14.0.linux-amd64.tar.gz
</pre>

## Install node_exprter on each Agent
curl -O boot/node_exporter-0.14.0.linux-amd64.tar.gz
tar xvzf node_exporter-0.14.0.linux-amd64.tar.gz
./node_exporter-0.14.0.linux-amd64/node_exporter &

## Edit prometheus.yml

<pre>
global:
  scrape_interval:     60s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 60s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  #external_labels:
      #monitor: 'codelab-monitor'

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first.rules"
  # - "second.rules"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'm1'
    static_configs:
      - targets: ['m1:9100']
  - job_name: 'a1'
    static_configs:
      - targets: ['a1:9100']
  - job_name: 'a2'
    static_configs:
      - targets: ['a2:9100']
  - job_name: 'a3'
    static_configs:
      - targets: ['a3:9100']
  - job_name: 'a4'
    static_configs:
      - targets: ['a4:9100']
  - job_name: 'a5'
    static_configs:
      - targets: ['a5:9100']
  - job_name: 'a6'
    static_configs:
      - targets: ['a6:9100']
  - job_name: 'p1'
    static_configs:
      - targets: ['p1:9100']

</pre>

## Install node-explorer

Placed node_exporter tarbzll in genconf/serve.

<pre>
curl -O boot/node_exporter-0.14.0.linux-amd64.tar.gz
tar xvzf node_exporter-0.14.0.linux-amd64.tar.gz
./node_exporter-0.14.0.linux-amd64/node_exporter &
</pre>

## Install mesos_exporter

Mesosphere provide [mesos_exporter](https://github.com/mesosphere/mesos_exporter) plugin for Prometheus.

### Install Go 

Download go from [golang](https://golang.org/dl/)

You can use curl

<pre>
curl -OL https://storage.googleapis.com/golang/go1.9.linux-amd64.tar.gz

shasum -a256 go1.9.linux-amd64.tar.gz 
d70eadefce8e160638a9a6db97f7192d8463069ab33138893ad3bf31b0650a79  go1.9.linux-amd64.tar.gz

sudo tar -C /usr/local -xvzf go1.9.linux-amd64.tar.gz 
</pre>

Setup Paths

<pre>
export PATH=$PATH:/usr/local/go/bin

mkdir gomesos
export GOBIN="$HOME/gomesos/bin"
export GOPATH="$HOME/gomesos"

go get github.com/mesosphere/mesos_exporter
cp gomesos/bin/mesos_exporter genconf/serve/
</pre>

On Master and Agents

<pre>
curl -O boot/mesos_exporter
chmod u+x mesos_exporter
./mesos_exporter --master 172.17.1.11:5050
./mesos_exporter --slave 172.17.2.9:5051
</pre>

## Sample Queries

Opened boot firewall for access to 9090..

http:<i></i>//52.183.30.1:9090.  Now you can query and graph results.

Some examples
- Disk Usage as Percentage: (1 - (node_filesystem_free{mountpoint="/var/lib/mesos"}/node_filesystem_size{mountpoint="/var/lib/mesos"}))*100
- Total CPU usage: sum without(cpu,instance,job)(irate(node_cpu{mode!="idle"}[5m]))


## Systemd Service
Use could setup system service for [prometheus](prometheus.service) and for [node-exporter](node-exporter.service). 

Additionally you could use mod_proxy to route calls from an Apache Web Server to prometheus. 

<pre>
ProxyPass /graph http://boot:9090/graph
ProxyPassReverse /graph http://boot:9090/graph
ProxyPass /static http://boot:9090/static
ProxyPassReverse /static http://boot:9090/static
ProxyPass /api http://boot:9090/api
ProxyPassReverse /api http://boot:9090/api
</pre>

Tried to load the IP dynamically into service file. Used a script with ExecStartPre to preload the EnvrionmentFile.  Didn't work yet: 

Create this script in /usr/loca/bin/ip-detect
<pre>
#!/bin/bash

set -o nounset -o errexit
echo $(ip addr show eth0 | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1
</pre>

Run chmod to make it executable for all.

Create mesos_exporter_create_env.sh.

<pre>
#!/bin/bash

ENVFILE=/home/centos/mesos_exporter_env

echo MESOS_SERVER=$(ip-detect) > ${ENVFILE}
echo MESOS_PORT=5050 >> ${ENVFILE}
</pre>

Tried this service file

<pre>
Description=Mesos Explorer
After=network.target

[Service]
Type=simple
User=centos
Group=centos

EnvironmentFile=/home/centos/mesos_exporter_env
ExecStartPre=/home/centos/mesos_exporter_create_env.sh

ExecStart=/bin/bash -c "/home/centos/mesos_exporter --master http://${MESOS_SERVER}:${MESOS_PORT}"

[Install]
WantedBy=multi-user.target
</pre>

For now I just hard coded the IP, Port, and Type in a Environment variable.

