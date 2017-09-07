#!/bin/bash

for a in $(cat /etc/hosts | grep ^10 | cut -d ' ' -f4 | grep -v boot)
do
	echo Updating /etc/hosts on $a
	scp -i centos.pem /etc/hosts centos@${server}:~
        ssh -t -i centos.pem centos@${server}  'sudo cp /home/centos/hosts /etc/hosts'
done

