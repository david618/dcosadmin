#!/bin/bash

RG="dj06"
ACTION="deallocate"
NUM_MASTERS=1
NUM_AGENTS=6
NUM_AGENTS_PUBLIC=1

echo "Shutting Down Masters"
for num in $(seq 1 ${NUM_MASTERS}); do
  echo "az vm ${ACTION} --resource-group ${RG} --name ${RG}m${num}"
  az vm ${ACTION} --resource-group ${RG} --name ${RG}m${num} > down_m${num}.log 2>&1
done

echo "Shutting Down Public Agents"
for num in $(seq 1 ${NUM_AGENTS_PUBLIC}); do
  echo "az vm ${ACTION} --resource-group ${RG} --name ${RG}p${num}"
  az vm ${ACTION} --resource-group ${RG} --name ${RG}p${num} > down_p${num}.log 2>&1
done

echo "Shutting Down Private Agents"
for num in $(seq 1 ${NUM_AGENTS}); do
  echo "az vm ${ACTION} --resource-group ${RG} --name ${RG}a${num}"
  az vm ${ACTION} --resource-group ${RG} --name ${RG}a${num} > down_a${num}.log 2>&1 &
done


sleep 10
echo "Watching logs with the following command:"
echo "tail -f down_*.log | grep -e status -e down"
echo "When you see all nodes with status succeeded; shutdown is conmplete. You can use Ctrl-C to exit watching at any time."
tail -f down_*.log | grep -e status -e down
