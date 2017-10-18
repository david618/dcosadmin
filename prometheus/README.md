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


## Example Prometheus Queries
- Reference: https://prometheus.io/docs/querying/basics/
- CPU Usage for Mesos Tasks
  - Query: cpu_user_seconds_total
  - From Console: You can see framework_id and id of tasks running on the nodes

- CPU Usage for Elastic (Seconds)
  - Using framework_id="b1c5d0c3-61ff-4db7-9cb3-6f8033c242b6-0002" from previous step
  - Query: cpu_user_seconds_total{framework_id="b1c5d0c3-61ff-4db7-9cb3-6f8033c242b6-0002"}

- CPU Usage by Elastic (# CPU)
  - Using irate function and average and 5 min intervals
  - Query: irate(cpu_user_seconds_total{framework_id="b1c5d0c3-61ff-4db7-9cb3-6f8033c242b6-0002"}[5m])
  - From Graph: You can stack or look at individual usage by id
  - You can see over the weekend periods of usage near 12 cpu/data node

## Returning results as JSON from Promethesus
- Reference: https://prometheus.io/docs/querying/api/
- For example: http://18.221.127.35:9090/api/v1/query?query=irate(cpu_user_seconds_total{framework_id=%22b1c5d0c3-61ff-4db7-9cb3-6f8033c242b6-0002%22}[5m])
  - Returns json similar to what you get in "Console"
- For a range query: http://18.221.127.35:9090/api/v1/query_range?query=irate(cpu_user_seconds_total%7Bframework_id%3D%22b1c5d0c3-61ff-4db7-9cb3-6f8033c242b6-0002%22%7D%5B5m%5D)&start=1507561657.037&end=1507583257.037&step=86&_=1507582317773
  - Returns json used to populate graph. 


## More Example Queries
- CPU
  - Total Allocated
    - Query: cpus_limit 
  - Filter to Framework (e.g. Elastic)
    - Query: cpus_limit{framework_id="b1c5d0c3-61ff-4db7-9cb3-6f8033c242b6-0002"}
  - Total Allocated to Framework 
    - Query: sum(cpus_limit{framework_id="b1c5d0c3-61ff-4db7-9cb3-6f8033c242b6-0002"})  
  - Total Agent CPUs
    - mesos_slave_cpus{job!="m1"}
- Memory
  - Total Allocated GB
    - Query: sum(mem_limit_bytes)/1024/1024/1024 
  - Allocated for Framework (GB)
    - Query: sum(mem_limit_bytes{framework_id="b1c5d0c3-61ff-4db7-9cb3-6f8033c242b6-0002"})/1024/1024/1024
  - Mem Total (Agents)
    - Query: sum(mesos_slave_mem_bytes/1024/1024)
- Disk
  - Disk Used
    - Query: disk_used_bytes{framework_id="b1c5d0c3-61ff-4db7-9cb3-6f8033c242b6-0002"}/1024/1024/1024
    - **NOTE** This does not reflect persistent disk space


## Disk Space Metrics from Mesos

Call to Agents
<pre>
curl 10.10.16.12:5051/monitor/statistics | jq .
</pre>

Return include a disk_statistics section

<pre>
      "disk_statistics": [
        {
          "limit_bytes": 268435456,
          "used_bytes": 1268310016
        },
        {
          "limit_bytes": 524288000000,
          "persistence": {
            "id": "c57d526a-149b-4161-bdae-63745907960e",
            "principal": "sats-sat01-principal"
          },
          "used_bytes": 24494661632
        }
      ],
</pre>

These number were what I saw on disk
<pre>
524288000000/1024/1024/1024 = 487.8GB
24494661632/1024/1024/1024 = 22.8
</pre>

We could modify the mesos_exporter to collect and report these numbers if needed.


## Rest API
Promethesus provides libraries for instrumentalizing code. This would allow us to collect metrics (counts) from each worker node and turn that into rates using Promethesus functions.  

I was able to create a sample client in Java.  

