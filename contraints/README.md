
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
