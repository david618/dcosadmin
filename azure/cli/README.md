# Azure CLI

## Installation

Follow the [installation](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) instructions for your operating system.


### CentOS

<pre>
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/azure-cli.repo'
sudo yum -y install azure-cli
</pre>

## Login 

<pre>
az login
</pre>

This will direct you to [Device Login](https://login.microsoftonline.com/common/oauth2/deviceauth) and you will enter the code created by az login.

## Now you can execute commands

Here are some [Common CLI Tasks](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-manage).

Example of looking up status and deallocating a VM.

<pre>
az vm get-instance-view --name dj06a1 --resource-group dj06 --query instanceView.statuses[1]
az vm deallocate --resource-group dj06 --name dj06a4
</pre>

### Bash Script Examples

start_private_agents.sh
<pre>
#!/bin/bash

RG="dj06"

for num in $(seq 1 6); do
  echo ${num}
  az vm start --resource-group ${RG} --name ${RG}a${num}
done
</pre>

**Note:** Before deallocating all of the agents stop all Mesos tasks.  

deallocate_private_agents.sh
<pre>
#!/bin/bash

RG="dj06"

for num in $(seq 1 6); do
  echo ${num}
  az vm deallocate --resource-group ${RG} --name ${RG}a${num}
done
</pre>

Even if we stopped all but one agent; this would save some money over the evenings/weekends when a cluster is not being used.



