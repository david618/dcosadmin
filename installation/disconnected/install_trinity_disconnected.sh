#!/bin/bash

#***************** SET THESE PARAMETERS ************************

CONFIG_FILENAME="trinity-taskmanager.json"

DOCKER_TAG="0.9.1.178"

EXTERNAL_HOSTNAME="djoffline.westus.cloudapp.azure.com"

NUM_PUBLIC_AGENTS=1

#DOCKER_PREFIX=boot:5000
DOCKER_PREFIX=esritrinity


#***************** SET THESE PARAMETERS ************************

# Install dcos
#curl -O https://downloads.dcos.io/binaries/cli/linux/x86-64/0.4.15/dcos
# Asuume dcos has been uploaded and is in the local directory
chmod +x dcos

# Configure DCOS
./dcos config set core.dcos_url https://m1
./dcos config set core.ssl_verify false

## The following command prompts for username/password for DCOS
## I haven't figure out how to script it yet
echo "Enter 'admin' for login username; the DCOS password you used during DCOS install."
./dcos auth login

./dcos package install --cli dcos-enterprise-cli

# Genreate key pair 
./dcos security org service-accounts keypair trinity-private-key.pem trinity-public-key.pem

# Create Service Account
./dcos security cluster ca cacert > dcos-ca.crt
./dcos security org service-accounts show
./dcos security org service-accounts create -p trinity-public-key.pem -d "Trinity service account" trinity-principal
./dcos security org service-accounts show trinity-principal

# Create trinity-secret
./dcos security secrets create-sa-secret --strict trinity-private-key.pem trinity-principal trinity-secret
./dcos security secrets list /

# Adminrouter Permissions
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:adminrouter:ops:historyservice/users/trinity-principal/full
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:adminrouter:ops:mesos/users/trinity-principal/full
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:adminrouter:ops:metadata/users/trinity-principal/full
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:adminrouter:ops:networking/users/trinity-principal/full
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:adminrouter:ops:slave/users/trinity-principal/full
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:adminrouter:ops:system-health/users/trinity-principal/full
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:adminrouter:package/users/trinity-principal/full
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:adminrouter:service:marathon/users/trinity-principal/full
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:adminrouter:service:metronome -H 'Content-Type: application/json' -d '{"description":"dcos:adminrouter:service:metronome"}'
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:adminrouter:service:metronome/users/trinity-principal/full

# Secrets Permissions
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:secrets:default:%252Ftrinity-secret -H 'Content-Type: application/json' -d '{"description":"dcos:secrets:default:/trinity-secret"}'
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:secrets:default:%252Ftrinity-secret/users/trinity-principal/create 
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:secrets:default:%252Ftrinity-secret/users/trinity-principal/delete
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:secrets:default:%252Ftrinity-secret/users/trinity-principal/read
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:secrets:default:%252Ftrinity-secret/users/trinity-principal/update

# Service Permissions
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F -H 'Content-Type: application/json' -d '{"description":"dcos:service:marathon:marathon:services:/"}'
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F/users/trinity-principal/create
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F/users/trinity-principal/delete
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F/users/trinity-principal/read
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F/users/trinity-principal/update

# Mesos Permissions 
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:mesos:agent:endpoint:path:%252Fmetrics%252Fsnapshot -H 'Content-Type: application/json' -d '{"description":"dcos:mesos:agent:endpoint:path:/metrics/snapshot"}'
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:mesos:agent:endpoint:path:%252Fmetrics%252Fsnapshot/users/trinity-principal/read 
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:mesos:agent:endpoint:path:%252Fcontainers -H 'Content-Type: application/json' -d '{"description":"dcos:mesos:agent:endpoint:path:/containers"}'
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:mesos:agent:endpoint:path:%252Fcontainers/users/trinity-principal/read
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:mesos:agent:endpoint:path:%252Fmonitor%252Fstatistics -H 'Content-Type: application/json' -d '{"description":"dcos:mesos:agent:endpoint:path:/monitor/statistics"}'
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:mesos:agent:endpoint:path:%252Fmonitor%252Fstatistics/users/trinity-principal/read

# Metronome Permission
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:service:metronome:metronome:jobs -H 'Content-Type: application/json' -d '{"description":"dcos:service:metronome:metronome:jobs"}'
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:service:metronome:metronome:jobs/users/trinity-principal/create
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:service:metronome:metronome:jobs/users/trinity-principal/delete
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:service:metronome:metronome:jobs/users/trinity-principal/read
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:service:metronome:metronome:jobs/users/trinity-principal/update


# ***********************************
# Install Marathon-LB
# ***********************************

./dcos security org service-accounts keypair mlb-private-key.pem mlb-public-key.pem
./dcos security org service-accounts create -p mlb-public-key.pem -d "Marathon-LB service account" mlb-principal
./dcos security org service-accounts show mlb-principal
./dcos security secrets create-sa-secret --strict mlb-private-key.pem mlb-principal mlb-secret
./dcos security secrets list /

curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:service:marathon:marathon:admin:events -d '{"description":"Allows access to Marathon events"}' -H 'Content-Type: application/json'
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:service:marathon:marathon:services:%252F/users/mlb-principal/read
curl -k -i -X PUT --cacert dcos-ca.crt -H "Authorization: token=`./dcos config show core.dcos_acs_token`" `./dcos config show core.dcos_url`/acs/api/v1/acls/dcos:service:marathon:marathon:admin:events/users/mlb-principal/read

# Install instance for each public agent
echo -e "{\n    \"marathon-lb\": {\n        \"secret_name\": \"mlb-secret\",\n        \"marathon-uri\": \"https://marathon.mesos:8443\",\n        \"bind-http-https\":false,\n        \"instances\":${NUM_PUBLIC_AGENTS}\n    }\n}" > mlb-config.json
./dcos package install --options=mlb-config.json --yes marathon-lb

# ***********************************
# Install Trinity Proxy
# ***********************************
cat > trinity-proxy.json << TPJ
{
  "id": "/trinity-proxy",
  "instances": $NUM_PUBLIC_AGENTS,
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "${DOCKER_PREFIX}/realtime-proxy:${DOCKER_TAG}",
      "network": "BRIDGE",
      "portMappings": [
        {
          "containerPort": 9000,
          "hostPort": 80,
          "servicePort": 80,
          "protocol": "tcp"
        },
        {
          "containerPort": 9443,
          "hostPort": 443,
          "servicePort": 443,
          "protocol": "tcp"
        }
      ],
      "forcePullImage": false
    }
  },
  "cpus": 2,
  "mem": 4096,
  "requirePorts": true,
  "healthChecks": [
    {
      "portIndex": 0,
      "protocol": "MESOS_HTTP",
      "path": "/healthcheck"
    }
  ],
  "acceptedResourceRoles": [
    "slave_public"
  ]
}
TPJ

./dcos marathon app add trinity-proxy.json

# ***********************************
# Install Trinity TaskManager
# ***********************************
cat > ${CONFIG_FILENAME} << EOL
{
  "id": "/trinity-taskmanager",
  "instances": 1,
  "cpus": 2,
  "mem": 2048,
  "disk": 0,
  "gpus": 0,
  "constraints": [
    [
      "hostname",
      "UNIQUE"
    ]
  ],
  "backoffSeconds": 1,
  "backoffFactor": 1.15,
  "maxLaunchDelaySeconds": 3600,
  "container": {
    "type": "DOCKER",
    "docker": {
      "image": "${DOCKER_PREFIX}/realtime-taskmanager:${DOCKER_TAG}",
      "network": "BRIDGE",
      "portMappings": [
        {
          "name": "playapp",
          "hostPort": 0,
          "containerPort": 9000,
          "protocol": "tcp",
          "servicePort": 10000
        }
      ],
      "privileged": false,
      "forcePullImage": false
    }
  },
  "healthChecks": [
    {
      "portIndex": 0,
      "gracePeriodSeconds": 300,
      "intervalSeconds": 60,
      "timeoutSeconds": 20,
      "maxConsecutiveFailures": 3,
      "protocol": "HTTP",
      "path": "/rtgis/admin/tags"
    }
  ],
  "upgradeStrategy": {
    "minimumHealthCapacity": 1,
    "maximumOverCapacity": 1
  },
  "secrets": {
    "secret0": {
      "source": "trinity-secret"
    }
  },
  "unreachableStrategy": {
    "inactiveAfterSeconds": 900,
    "expungeAfterSeconds": 604800
  },
  "requirePorts": false,
  "labels": {
    "HAPROXY_GROUP": "external",
    "HAPROXY_0_BACKEND_HEAD": "backend {backend}\n  balance {balance}\n  mode {mode}\n  timeout server 5m\n  timeout client 5m\n"
  },
  "env": {
    "DCOS_SECRET": {
      "secret": "secret0"
    },
    "EXTERNAL_HOSTNAME": "${EXTERNAL_HOSTNAME}",
    "ZK_QUORUM": "master.mesos:2181",
    "DCOS_URL": "https://master.mesos",
    "DOCKER_IMAGE_VERSION": "${DOCKER_TAG}"
  }
}
EOL

./dcos marathon app add ${CONFIG_FILENAME}
