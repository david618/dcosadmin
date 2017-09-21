# Munin 

"Munin is a networked resource monitoring tool that can help analyze resource trends and "what just happened to kill our performance?" problems. It is designed to be very plug and play. A default installation provides a lot of graphs with almost no work."

[munin](http://munin-monitoring.org/)

These instrutions assum you have done an advanced install of DC/OS.  Installing munin on "boot" server and instaling munin-node on each of the DC/OS nodes.

## Munin Install on Boot

Open firewall to allow port 81
- Azure: boot NSG; Add Inbound Security Rule 
- AWS: ???

Install httpd server (Apache Web Server)
<pre>
sudo su -
yum -y install httpd
vi /etc/httpd/conf/httpd.conf
</pre>

Change port if needed (e.g. 81).  Port 80 is already used by DC/OS docker image created to support installs.

<pre>
systemctl enable httpd
systemctl start httpd
</pre>

Now install munin

<pre>
yum -y install epel-release
yum -y install munin 
</pre>

Configure admin password
<pre>
htpasswd /etc/munin/munin-htpasswd admin
</pre>
**NOTE** Without setting password some of graphs on munin did not work.

## Install munin-node on Agents

Here is a script (install_munin.sh) to make the task easier.  

<pre>
vi genconf/serve/install_munin.sh
</pre>

Created in web folder of the DC/OS web server.  You'll need to tweak the sed command for the IP of your boot server.

<pre>
#!/bin/bash

yum -y install epel-release
yum -y install munin-node

#sed -i '/allow ^::1$$/ a allow ^10\\.10\\.0\\.10$' /etc/munin/munin-node.conf
sed -i '/allow ^::1$$/ a allow ^172\\.17\\.0\\.4$' /etc/munin/munin-node.conf

systemctl start munin-node
systemctl enable munin-node
</pre>

Now you need to run the script on every node in the cluster.  You could use the run_cluster_cmd.sh.

<pre>
sudo bash real-time-gis/devops/tools/run_cluster_cmd.sh azureuser azureuser 1 6 1 'curl -O boot/install_munin.sh;sudo bash install_munin.sh'
</pre>

or you can ssh to each node and run

<pre>
curl -O boot/install_munin.sh
sudo bash install_munin.sh
</pre>

## Configure munin on Boot

Edit /etc/munin/munin.conf and set host tree

<pre>
[m1]
    address m1
    use_node_name yes
[a1]
    address a1
    use_node_name yes
[a2]
    address a2
    use_node_name yes
[a3]
    address a3
    use_node_name yes
[a4]
    address a4
    use_node_name yes
[a5]
    address a5
    use_node_name yes
[a6]
    address a6
    use_node_name yes
[p1]
    address p1
    use_node_name yes
</pre>

## Access the Munin Web Page

For example:  http<i></i>://51.183.30.201:81/munin

Where 51.183.30.201 is the boot servers public IP.

You'll be prompted for the username/password you created earlier.

## Access Data Directly

Munin doesn't currently provide a rest interface; however, it is possible to use rrdtool to export the data directly.

<pre>
cd /var/lib/munin
xport -s now-1h -e now --json DEF:xx=a1-cpu-system-d.rrd:42:AVERAGE   XPORT:xx:"bytes"
</pre>

Will extract vaules from rrd file to json giving results like.

<pre>
{ about: 'RRDtool xport JSON output',
  meta: {
    "start": 1506014100,
    "step": 300,
    "end": 1506014100,
    "legend": [
      'bytes'
          ]
     },
  "data": [
    [ null ],
    [ null ],
    [ null ],
    [ null ],
    [ null ],
    [ null ],
    [ null ],
    [ 4.4870370370e+00 ],
    [ 4.5845000000e+00 ],
    [ 4.6090000000e+00 ],
    [ 4.6348333333e+00 ],
    [ 4.6328333333e+00 ],
    [ null  ]
  ]
}
</pre>
