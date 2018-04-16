#!/bin/bash

RG="dj06"
ACTION="start"
NUM_MASTERS=1
NUM_AGENTS=6
NUM_AGENTS_PUBLIC=1


for num in $(seq 1 ${NUM_AGENTS}); do
  echo "az vm ${ACTION} --resource-group ${RG} --name ${RG}a${num}"
  az vm ${ACTION} --resource-group ${RG} --name ${RG}a${num} > up_a${num}.log 2>&1 &
done
echo "Waiting for Private Agents to Start"

# Wait for all private agetns to start before starting master and public
cnt=0

echo "Staring Private Agents"
while [ $cnt -lt ${NUM_AGENTS} ]; do
     sleep 60
     cnt=$(cat up_a?.log | grep Succeeded | wc -l)
     echo "$(date +%H:%M:%S) : $cnt of ${NUM_AGENTS} private agents have started"
done

echo "All Agents Have Started"

echo "Staring Public Agents"
for num in $(seq 1 ${NUM_MASTERS}); do
  echo "az vm ${ACTION} --resource-group ${RG} --name ${RG}m${num}"
  az vm ${ACTION} --resource-group ${RG} --name ${RG}m${num} > up_m${num}.log 2>&1
done

echo "Staring Masters"
for num in $(seq 1 ${NUM_AGENTS_PUBLIC}); do
  echo "az vm ${ACTION} --resource-group ${RG} --name ${RG}p${num}"
  az vm ${ACTION} --resource-group ${RG} --name ${RG}p${num} > up_p${num}.log 2>&1
done

echo "All nodes are running"
