
# Upgrade 

Done from the boot server.

## Stop Docker nginx

'''
sudo docker ps

sudo docker kill (id)
'''

## Update the Configuration

Make changes to genconf fodler

Remove server and server and state folder


## Generate new Config
'''
sudo bash dcos_generate_config.sh --generate-node-upgrade-script 1.11.0
'''

## Start docker nginx

'''
sudo docker run -d -p 80:80 -v $PWD/genconf/serve:/usr/share/nginx/html:ro nginx
'''

## Reposition the Upgrade Script (optional)

It created in a subfolder under serve folder.  

## Verify Available

'''
curl localhost/dcos_node_upgrade.sh
'''

## Upgrade the Master

Log into one of Masters

```
ping leader.mesos
```

Make sure you are not on the leader.

'''
curl -O 10.10.0.10/dcos_node_upgrade.sh
sudo bash dcos_node_upgrade.sh
'''

When done do every master (not master).

Then stop dcos-mesos-master service on leader; wait for leader to change; then restart.


## General Upgrade

Similar Approach for upgraded dcos version from 1.11.0 to 1.11.1


## Debug if something Goes Wrong
''' 
journalctl -flu dcos-exhibitor
'''

