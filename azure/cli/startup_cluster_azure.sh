#!/bin/bash

RG="dj06"
ACTION="start"
NUM_MASTERS=1
NUM_AGENTS=6
NUM_AGENTS_PUBLIC=1

for num in $(seq 1 ${NUM_AGENTS}); do
  echo "az vm ${ACTION} --resource-group ${RG} --name ${RG}a${num}"
  az vm ${ACTION} --resource-group ${RG} --name ${RG}a${num}
done

for num in $(seq 1 ${NUM_MASTERS}); do
  echo "az vm ${ACTION} --resource-group ${RG} --name ${RG}m${num}"
  az vm ${ACTION} --resource-group ${RG} --name ${RG}m${num}
done

for num in $(seq 1 ${NUM_AGENTS_PUBLIC}); do
  echo "az vm ${ACTION} --resource-group ${RG} --name ${RG}p${num}"
  az vm ${ACTION} --resource-group ${RG} --name ${RG}p${num}
done

