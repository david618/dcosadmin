# Mesos Metrics

Mesos info can be retried via [Mesos HTTP Endpoints](http://mesos.apache.org/documentation/latest/endpoints/)

## Slaves
<pre>
curl -s m1:5050/slaves | jq
</pre>

Provides information about each slave cpu,mem,ports

Get the id and hostname (ip) for each slave
<pre>
curl -s m1:5050/slaves | jq '{"id":.slaves[].id,"host":.slaves[].hostname}'
</pre>


## Slave Monitor Statistics

<pre>
curl -s a6:5051/monitor/statistics | jq
</pre>

To calculate cpus usage take two samples a and b. 

<pre>

cpus_total_usage = (
                    (b.cpus_system_time_secs - a.cpus_system_time_secs) +
                    (b.cpus_user_time_secs - a.cpus_user_time_secs)) / 
                    (b.timestamp - a.timestamp)
                   )
cpu_percent      = cpus_total_usage / cpu_limit * 100%
</pre>

## Tasks

Task status; resources, container id, ip, 

<pre>
curl -s m1:5050/tasks
</pre>
