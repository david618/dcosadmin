# DC/OS Disk Types

DC/OS supports two disk types ROOT or MOUNT.

## ROOT

ROOT disk is space in /var/lib/mesos.  

Before install DC/OS we create a data drive (e.g. 1TB) and mount the drive at /var/lib/mesos.  This space can then be used by Services like Elastic or Kafka.  

ROOT disk type is the default.


## MOUNT

MOUNT disk space is mounted under /dcos/volume[0-9].

Instructions on how to add a MOUNT disk are provided [here](https://docs.mesosphere.com/1.11/storage/mount-disk-resources/)

Overview of Process
- Create a Partition
- Format Partition
- Make Directory (e.g. /dcoc/volume0)
- Mount the Partition to new directory (Add entry to /etc/fstab)
- Clear resouces files dcos and mesos
- Restart the node

To use a MOUNT disk you specify "MOUNT" when deploying a service (e.g. Elastic) from DC/OS catalog.  

**NOTE:** Each volume can only be used by one service.  The entire volume is allocated to the service.

For example
- Created volumes: 250GB, 300GB, 350GB, 400GB, 600GB, 650GB, 700GB, and 750GB.
- Volumes were spread across 4 nodes; each node had two volumes (/dcos/volume0 and /dcos/volume2)
- Deployed Elastic requested the Data Nodes use "MOUNT" with 275000MB or 275GB of disk
- One data node took the 300GB volume (Shown in Mesos)
- Another data node took 400GB volume (Shown in Mesos)
- In DC/OS Dashboard 700GB was allocated. 


