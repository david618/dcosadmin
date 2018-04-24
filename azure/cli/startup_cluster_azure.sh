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

ACTION="start"

# Resource Group

resourceGroup=$(curl -s -H Metadata:true http://169.254.169.254/metadata/instance?api-version=2017-08-01 | jq .compute.resourceGroupName --raw-output)

if [ -z "${resourceGroup}" ]; then
  echo "Couldn't find the Resource Group name using Azure Metadata"
  exit 1
fi

echo "Starting Cluster ${resourceGroup}"

# Private Agents
echo "Starting Private Agents"
NUM_AGENTS=0
for file in down_a*.log; do
  name=$(echo ${file} | cut -d '_' -f2 | cut -d '.' -f1)
  az vm ${ACTION} --resource-group ${resourceGroup} --name ${resourceGroup}${name} > up_${name}.log 2>&1 &
  echo "${ACTION} ${name}"
  NUM_AGENTS=$(( NUM_AGENTS + 1 ))
done

# Wait for all private agetns to start before starting master and public
cnt=0
echo "Waiting for Private Agents to Start"
while [ $cnt -lt ${NUM_AGENTS} ]; do
     sleep 10
     cnt=$(cat up_a?.log 2>/dev/null | grep Succeeded | wc -l)
     echo "$(date +%H:%M:%S) : $cnt of ${NUM_AGENTS} private agents have started"
done
echo "All Private Agents have Started"

# Give the Private Agents a Minute to stablize
sleep 60

echo "Staring Public Agents"
for file in down_p*.log; do
  name=$(echo ${file} | cut -d '_' -f2 | cut -d '.' -f1)
  echo "${ACTION} ${name}"
  az vm ${ACTION} --resource-group ${resourceGroup} --name ${resourceGroup}${name} > up_${name}.log 2>&1 
done

echo "Staring Masters"
for file in down_m*.log; do
  name=$(echo ${file} | cut -d '_' -f2 | cut -d '.' -f1)
  echo "${ACTION} ${name}"
  az vm ${ACTION} --resource-group ${resourceGroup} --name ${resourceGroup}${name} > up_${name}.log 2>&1 
done

echo "All nodes are running"
