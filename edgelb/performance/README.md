# Performance

Tested using http-kafka from the [rt](https://github.com/david618/rt) project.

## Created Marathon App

Deployed [http-kafka](./http-kafka.json) app on DC/OS.

## Install Test Tool

Installed [rttest](https://github.com/david618/rttest) on public agent. 

## Download Test Data

Used data created with [planes](https://github.com/david618/planes).

Dataset can be downloaded from s3 using curl.

`curl -O https://s3.amazonaws.com/rttestdata/planes/lat88/planes00001`

Downloaded to rttest folder.

## Installed Kafka

Installed on p1

### Download 

```
curl -O http://apache.org/dist/kafka/0.11.0.2/kafka_2.11-0.11.0.2.tgz
tar xvzf kafka_2.11-0.11.0.2.tgz
ln -s kafka_2.11-0.11.0.2 kafka
```

### Configure

```
sudo mkdir /mnt/resource/kafka
sudo chown azureuser. /mnt/resource/kafka
vi kafka/config/server.properties
```

- Change `/tmp/kafka-logs` to `/mnt/resource/kafka/kafka-logs`
- Add line: `delete.topic.enable=true`

### Start

```
./kafka/bin/zookeeper-server-start.sh ./kafka/config/zookeeper.properties 1>zoo.log 2>&1 &
./kafka/bin/kafka-server-start.sh ./kafka/config/server.properties 1>kafka.log 2>&1 &
```


## Added an EdgeLB Pool for App

Tested using [VIP based EdgeLB Pool](./http-kafka-lb-vip.json) the throughput was very slow.  Less than 100/s.

Tested using [Marathon based EdgeLB Pool](./http-kafka-lb-marathon.json) rates between 6,000 to 7,000/s.

Deployed the pull using "dcos" command line tool.   For example: `dcos edgelb create http-kafka-lb-marathon.json`

The haproxy stats for this pool are on port 10009 (e.g. `http://dj50.westus2.cloudapp.azure.com:10009/haproxy?stats`)


## HAProxy Configuration

Added to /etc/haproxy/haproxy.cfg

```
defaults
   log global
   mode http
   option httplog
   option dontlognull
   timeout connect 5000
   timeout client 50000
   timeout server 50000

frontend http_kafka_front
   bind *:10003
   stats uri /haproxy?stats

   default_backend http_kafka_back

backend http_kafka_back
   balance roundrobin
   server http-kafka http-kafka.marathon.l4lb.thisdcos.directory:7000 check

```

The haproxy stats for this install of haproxy is on port 10003 (e.g. `http://dj50.westus2.cloudapp.azure.com:10003/haproxy?stats`)


## Test Results

### Configuration

- httpd-kafka: 3 instances with 1cpu/2GBmem per instance
- Total Resources: 3 cpu and 6GB mem

### Monitor Output
```
java -cp target/rttest.jar com.esri.rttest.mon.KafkaTopicMon p1:9092 planes2
```

### EdgeLB

```
java -cp target/rttest.jar com.esri.rttest.send.Http http://p1:10001 planes00001 30000 1000000 64
java -cp target/rttest.jar com.esri.rttest.send.Http http://p1:10001 planes00001 30000 10000000 64
```

- Send Rate:  5,855
- Output Rate: 5,966

### HAProxy 

```
java -cp target/rttest.jar com.esri.rttest.send.Http http://p1:10003 planes00001 30000 1000000 64
```

- Send Rate: 6,867/s
- Output Rate: 6,985/s

### Direct
```
java -cp target/rttest.jar com.esri.rttest.send.Http http://app[http-kafka] planes00001 30000 5000000 64
```

- Send: 11,400
- Output: 11,959

## Results 

This table contains Output Rates test results from different Clusters

|Test Number|EdgeLB Rate|HAProxy Rate|Direct Rate|
|-----------|-----------|------------|-----------|
|1          |5,966/s    |6,985/s     |11,959/s   |
|2          |6,845/s    |7,880/s     |13,315/s   |
|3          |6,386/s    |7,442/s     |13,337/s   |

Observations
- Direct access is about two times faster than via HAProxy or EdgeLB
- HAProxy is about 15% faster than EdgeLB

