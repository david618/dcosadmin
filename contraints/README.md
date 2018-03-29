
# Using Constraints

## Using Mesos Attributes and Constraints.

On each agent define an attribute.

For example create an attribute “AGENTSET” with a value of SIT

<pre>
# vi /opt/mesosphere/etc/mesos-slave
MESOS_ATTRIBUTES=AGENTSET:SIT
</pre>

You could set other machines with other values.

<pre>
MESOS_ATTRIBUTES=AGENTSET:SAT
MESOS_ATTRIBUTES=AGENTSET:BAT
# rm -f /var/lib/mesos/slave/meta/slaves/latest
# systemctl restart dcos-mesos-slave.service
# systemctl status dcos-mesos-slave.service
</pre>

When you create an app set a Constraint.

For Example: 

<pre>
AGENTSET:LIKE:SIT
</pre>

The task will only deploy to Agents with the Attribute AGENTSET value is SIT

_NOTE: If you do not set a constraint for a task the task will deploy on any agent with the resources available._ 

I could create a script to set an attribute for a given list of nodes either at creation time or after creation.

## Using Resource Settings in Mesos

On the agent

<pre>
# vi /opt/mesosphere/etc/mesos-slave
</pre>

Add a line to set the default role for this agent.

<pre>
MESOS_DEFAULT_ROLE=sit
</pre>

Restart the Service

<pre>
# rm -f /var/lib/mesos/slave/meta/slaves/latest
# systemctl restart dcos-mesos-slave.service
# systemctl status dcos-mesos-slave.service
</pre>

The DCOS Marathon is configured with --mesos-role=slave_public.  Marathon only supports a single role in this configuration so when you deploy tasks you can set Accepted Resource Roles to “slave_public” and the task will be deployed to a DCOS defined public agent or if blank or \* it will deploy to a private agent. If you try to use “sit” the app will not deploy.  

You can deploy Marathon on Marathon and give it the new mesos-role defined during deployment.  On this Marathon you can use the role you defined “sit”.  Then you can define Accepted Resourc Roles set to “sit” and it works.

References:
https://support.mesosphere.com/hc/en-us/articles/206474745-How-to-reserve-resources-for-certain-frameworks-in-Mesos-cluster-

http://mesos.apache.org/documentation/latest/configuration/ 

http://mesos.apache.org/documentation/latest/attributes-resources/

http://mesos.apache.org/documentation/latest/roles/ 

http://mesos.apache.org/documentation/latest/endpoints/

https://mesosphere.github.io/marathon/docs/command-line-flags.html 


## Using Bash to Set MESOS_ATTRIBUTES

You can manually set the attribute on agents; however, if you have several you can use these bash scripts to set MESOS_ATTRIBUTES on them all at once.

Create setattribute.sh script.

<pre>
#!/bin/bash
USERNAME=azureuser
PKIFILE=azureuser
FILE=/opt/mesosphere/etc/mesos-slave
if [ "$#" -ne 2 ];then
        echo "Usage: $0 <attribute-name> <attribute-value>"
        exit 99
fi
ATTRNAME=$1
ATTRVAL=$2
MA=$(grep "^MESOS_ATTRIBUTES" $FILE)
if [ "$?" == "0" ]
then
        echo "Replace the Attribute"
        sed -i "s/$MA/MESOS_ATTRIBUTES=${ATTRNAME}:${ATTRVAL}/" $FILE
else
        echo "Append to file"
        echo MESOS_ATTRIBUTES=${ATTRNAME}:${ATTRVAL} >> $FILE
fi
rm -f /var/lib/mesos/slave/meta/slaves/latest
systemctl restart dcos-mesos-slave
</pre>

Put setattribute.sh script on the boot server in /root/genconf/serve folder.  This will allow the agents to get the file using curl -O boot/setattribute.sh

Then create setattribute_onagents.sh script on boot in root's home directory.

<pre>
#!/bin/bash
USERNAME=azureuser
PKIFILE=azureuser
FILE=/opt/mesosphere/etc/mesos-slave
CMD=setattribute.sh
if [ "$#" -ne 3 ];then
        echo "Usage: $0 <attribute-name> <attribute-value> <csv-server-names>"
        exit 99
fi
ATTRNAME=$1
ATTRVAL=$2
SERVERS=$(echo $3 | tr "," "\n")
for SERVER in $SERVERS
do
        echo $SERVER
        ssh -t -t -o "StrictHostKeyChecking no" -i $PKIFILE $USERNAME@$SERVER "sudo curl -O boot/$CMD; sudo bash $CMD $ATTRNAME $ATTRVAL" >>$CMD.log 2>>$CMD.log &
done
</pre>

You may need to adjust the USERNAME, PKIFILE.  

The command line for setting a6,a7, and a8 with AGENTSET = SAT.

<pre>
./setattribute_onagents AGENTSET SAT a6,a7,a8
</pre>

You can verify using this command from boot server.

<pre>
$ ssh -i azureuser azureuser@a6 'cat /opt/mesosphere/etc/mesos-slave'
</pre>

You should see something like.

<pre>
[azureuser@boot ~]$ ssh -i azureuser azureuser@a6 'cat /opt/mesosphere/etc/mesos-slave'
MESOS_RESOURCES=[{"name":"ports","type":"RANGES","ranges": {"range": [{"begin": 1025, "end": 2180},{"begin": 2182, "end": 3887},{"begin": 3889, "end": 5049},{"begin": 5052, "end": 8079},{"begin": 8082, "end": 8180},{"begin": 8182, "end": 32000}]}}]
MESOS_ATTRIBUTES=AGENTSET:SAT
</pre>

Now if you add a CONSTRAINT to a marathon task.

<pre>
{
  "id": "/app",
  "cmd": "python -m SimpleHTTPServer $PORT",
  "cpus": 0.1,
  "mem": 128,
  "disk": 0,
  "instances": 1,
  "constraints": [
    [
      "AGENTSET",
      "LIKE",
      "SAT"
    ]
  ],
  "labels": {
    "HAPROXY_GROUP": "external"
  },
  "portDefinitions": [
    {
      "port": 10009,
      "protocol": "tcp",
      "labels": {}
    }
  ]
}
</pre>

The task will only run on a6,a7,or a8.


