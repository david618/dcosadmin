# Kafka


## Install Kafka

Requires java. (yum -y install java-1.8.0-openjdk)

**Note:** You might need to update the following with the latest verion of kafka at http://apache.org/dist/kafka.

<pre>
curl -O http://apache.org/dist/kafka/0.11.0.2/kafka_2.11-0.11.0.2.tgz
tar xvzf kafka_2.11-0.11.0.2.tgz
ln -s kafka_2.11-0.11.0.2 kafka
</pre>


Configure for delete topic.

Add this line to server.properties

<pre>
delete.topic.enable=true
</pre>

## Create Gateway in Trinity

Assuming you named the Gateway "gw01".

## List Topics
<pre>
./kafka/bin/kafka-topics.sh --zookeeper m1:2181/dcos-service-hub-gw01 --list
</pre>

## Describe Topic

<pre>
./kafka/bin/kafka-topics.sh --zookeeper m1:2181/dcos-service-hub-gw01 --describe --topic poll-satellites
</pre>

You should see output like
<pre>
Topic:poll-satellites   PartitionCount:1        ReplicationFactor:1     Configs:
        Topic: poll-satellites  Partition: 0    Leader: 2       Replicas: 2     Isr: 2
</pre>


## List Groups

<pre>
./kafka/bin/kafka-consumer-groups.sh --bootstrap-server broker.hub-gw01.l4lb.thisdcos.directory:9092  --list
</pre>


## Delete Topic

<pre>
./kafka/bin/kafka-topics.sh --zookeeper m1:2181/dcos-service-hub-gw01 --delete --topic poll-satellites
</pre>

