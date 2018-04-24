#!/bin/bash

# See if login token is valid
az vm list > /dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "You need to login to Azure"
  echo "After successful authentication run $0 again"
  # login
  az login
  exit 2
fi

ACTION="deallocate"

# Use Azure Metadata to lookup Resource Group
resourceGroup=$(curl -s -H Metadata:true http://169.254.169.254/metadata/instance?api-version=2017-08-01 | jq .compute.resourceGroupName --raw-output)

if [ -z "${resourceGroup}" ]; then
  echo "Couldn't find the Resource Group name using Azure Metadata"
  exit 1
fi

echo "Stopping nodes on Cluster  ${resourceGroup}"
echo "This process can take up to 15 minutes"

totalNodes=0

# Masters
echo "Shutting Down Masters"
count=1
name=m1
nameExists=$(getent hosts ${name})
while [ ! -z "${nameExists}" ];do
  echo "${ACTION} ${name}"
  az vm ${ACTION} --resource-group ${resourceGroup} --name ${resourceGroup}${name} > down_${name}.log 2>&1 
  count=$(( count + 1 ))
  name="m${count}"
  nameExists=$(getent hosts ${name})
  totalNodes=$(( totalNodes + 1 ))
done

# Public Agents
echo "Shutting Down Public Agents"
count=1
name=p1
nameExists=$(getent hosts ${name})
while [ ! -z "${nameExists}" ];do
  echo "${ACTION} ${name}"
  az vm ${ACTION} --resource-group ${resourceGroup} --name ${resourceGroup}${name} > down_${name}.log 2>&1 
  count=$(( count + 1 ))
  name="p${count}"
  nameExists=$(getent hosts ${name})
  totalNodes=$(( totalNodes + 1 ))
done


# Private Agents
echo "Shutting Down Private Agents"
count=1
name=a1
nameExists=$(getent hosts ${name})
while [ ! -z "${nameExists}" ];do
  echo "${ACTION} ${name}"
  az vm ${ACTION} --resource-group ${resourceGroup} --name ${resourceGroup}${name} > down_${name}.log 2>&1 &
  count=$(( count + 1 ))
  name="a${count}"
  nameExists=$(getent hosts ${name})
  totalNodes=$(( totalNodes + 1 ))
done

echo "Waiting for all Private Agents to Stop"
cntSucceeded=$(cat down_a*.log 2>/dev/null | grep -e "Succeeded" | wc -l)
while [ "$cntSucceeded" -lt "$totalNodes" ]; do
	sleep 10
	cntSucceeded=$(cat down_*.log | grep -e "Succeeded" | wc -l)
	echo "$(date +%H:%M:%S) : ${cntSucceeded} of ${totalNodes} have stopped"
done

echo "Cluster nodes are stopped/deallocated"
