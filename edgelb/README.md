# Edge-LB

At DC/OS 1.11 you still cannot edit the Mesosphere

## Changing the configuration of Edge-LB using DC/OS cli

Log into the "boot" server

<pre>
sudo chown azureuser. dcos
chmod u+x dcos
PATH=$PATH:~
</pre>


**NOTE:** You only need to configure and install once.

### Configure Cluster

<pre>
dcos cluster setup https://m1 --insecure
</pre>
Enter username and password


### Install Packages
<pre>
dcos package repo add --index=0 edgelb-aws      https://edge-lb-infinity-artifacts.s3.amazonaws.com/permanent/tag/v1.0.0-rc3/edgelb/stub-universe-edgelb.json
dcos package repo add --index=0 edgelb-pool-aws https://edge-lb-infinity-artifacts.s3.amazonaws.com/permanent/tag/v1.0.0-rc3/edgelb-pool/stub-universe-edgelb-pool.json
</pre>

### Install CLI 

<pre>
dcos package install edgelb --cli
dcos package install edgelb-pool --cli
</pre>

### Save the Config 

<pre>
dcos edgelb show --json a4iot > rcvRest-a4oit-config.json
</pre>

## Delete the Pool

<pre>
dcos edgelb delete a4iot
</pre>


### Edit the Config

This saved config didn't work when I tried to recreate the pool.  

Saved off just the contents of the "v2" object.  That portion works.


## Create the Pool

With the original Pool (Just Trinity)

<pre>
dcos edgelb create edge-lb-a4iot-pool.json 
</pre>

Or use your edited config.


