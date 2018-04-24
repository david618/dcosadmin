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


## Using the Rest API


Additional details are on the [help](https://docs.mesosphere.com/services/edge-lb/) pages.

### From Public DC/OS access point

Accessing from the outside world.  `https://<public-name-or-ip/service/edgelb/`.  To access the api on this endpoint you'll need to supply a token.

#### Get the Token 

Send HTTP POST to `https://<public-name-or-ip/acs/api/v1/auth/login` with the uid and password as json.

For example: `curl -XPOST -k -H "Content-Type: application/json" -d '{"uid":"trinity","password":"some-password"}' https://m1/acs/api/v1/auth/login`  

This will return the token.  For example.

```
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJ1aWQiOiJ0cml  ...   DQwePKO9hYbg3b7p0WUzdRbHOA"
}

```

### Use Rest API.

For example:

```
curl -XGET -k -H "Content-Type: application/json" -H "Authorization: token=eyJ0eXAiOi...CGlk5q1lKviuqKp1g"  https://dj06dcos.westus2.cloudapp.azure.com/service/edgelb/v2/config
```

The token is also necessary if you try to access the master node directory `https://m1/...`

### From Node on DC/OS cluster

You can use the VIP from inside the cluster and bypass the need for authentication.

```
curl -XGET -k -H "Content-Type: application/json" api.edgelb.marathon.l4lb.thisdcos.directory/service/edgelb/v2/config
```

#### Get the Current Pool Config

```
curl -o a4iot.json api.edgelb.marathon.l4lb.thisdcos.directory/v2/pools/a4iot

```

#### Make changed 

You can add/tweak the configuration as needed.


#### Update the Pool Config

```
curl -XPUT -H 'Content-Type: application/json' -d @a4iot_pretty_websats.json api.edgelb.marathon.l4lb.thisdcos.directory/v2/pools/a4iot

```

This will load the modified config saved in a file named `a4iot_pretty_websats.json

