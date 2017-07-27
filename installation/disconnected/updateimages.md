# Update files in S3

## Update Docker Images For Trinity 

### Pull Current Images from S3

This is how to pull s3 bucket down to server you want to build images on.  Recommend you use a Cloud computer (Azure/AWS) because moving images up to s3 can be very slow depending on you'r upload speed. 

<pre>
$ sudo su - 
# yum -y install epel-release
# yum install -y python2-pip
# exit

$ pip install --upgrade --user awscli
$ aws configure
</pre>

Provided ID and Key
<pre>

$ mkdir s3
$ cd s3
$ aws s3 sync s3://djennings . 
</pre>

### Pull Docker Images 
 
Pulls the images from Docker down to local machine.
 
- Edit Docker Pull Script (docker-pull.sh) and set the TAG
- Run Script
  <pre>
  sudo bash docker-pull.sh
  </pre>
- You'll be prompted for your Docker username and password (you need permissions to esritrinity)
- Script takes a few minutes to run

### Save Docker Images

Saves and Compresses Docker Images.

- Edit Docker Save Script docker-save.sh and set the TAG
- Create a folder and cd to that folder
  **NOTE:** Azure has some pretty small root drives so I created images folder on /mnt/resources.
  <pre>
  sudo mkdir /mnt/resources/images
  sudo chown azureuser. /mnt/resources/images
  cd /mnt/resources/images
  </pre>
- Run Script
  <pre>
  sudo bash /home/azureuser/djennings/docker-save.sh
  </pre>
  
### Copy New Images to s3 Folder

- From the s3 folder remove the old images
<pre>
cd ~/s3 
rm realtime-*
</pre>
- Copy the new images to the s3 folder
<pre>
sudo cp /mnt/resources/images/realtime-* ~/s3
chown azureuser. ~/s3/realtime-*
</pre>

## Created local-universe

To build on centos install pre-reqs

<pre>
sudo yum -y install epel-release
sudo yum -y install git maven
sudo yum -y install docker
sudo yum -y install python34
systemctl start docker
</pre>

For offline installation of DCOS if you need access to packages in Universe you need to create a [Local Universe](https://dcos.io/docs/1.9/administering-clusters/deploying-a-local-dcos-universe/) 

Followed instructions under "Installing a selected set of Universe package" 

For step 3 these are packages we need.  You can just edit the Makefile or use the sed command.

<pre>
sed -i -e 's/--selected/--include="marathon-lb,beta-kafka,beta-elastic,dcos-enterprise-cli"/' Makefile
</pre>

or you can just edit the Makefile using vi and set --include as follows.

<pre>
--include="marathon-lb,beta-kafka,beta-elastic,dcos-enterprise-cli"
</pre>

**NOTE:** If you need an older version of package, you'll need to remove newer versions of the package from your local copy.

As of Trinity TAG:  0.9.4.222
- beta-elastic: 1.0.13-5.4.1-beta
- beta-kafka: 1.1.22-0.10.1.0-beta

For example. 

<pre>
cd universe/repo/packages/B/beta-elastic
ls 
0  1  2  3  4  5
</pre>

Look at contents of the package.json for latest.
<pre>
cat 5/package.json
{
  "description": "Elasticsearch 5, and optionally X-Pack",
  "framework": true,
  "maintainer": "support@mesosphere.io",
  "minDcosReleaseVersion": "1.9",
  "name": "beta-elastic",
  "packagingVersion": "3.0",
  "postInstallNotes": "DC/OS elastic service is being installed!\n\n\tDocumentation: https://docs.mesosphere.com/1.9/usage/service-guides/elastic\n\tIssues: https://docs.mesosphere.com/support/",
  "postUninstallNotes": "DC/OS elastic service is being uninstalled.",
  "preInstallNotes": "This DC/OS Service is currently a beta candidate undergoing testing as part of a formal beta test program.\n\nThere may be bugs, incomplete features, incorrect documentation, or other discrepancies.\n\nDefault configuration requires 3 agent nodes each with: CPU: 4.5 | Memory: 11264MB | Disk: 15500MB\n\nMore specifically, each instance type requires:\n\nMaster node: 3 instances | 1.0 CPU | 2048 MB MEM | 1 2000 MB Disk\n\nData node: 2 instances | 1.0 CPU | 4096 MB MEM | 1 10000 MB Disk\n\nIngest node: 1 instance | 0.5 CPU | 2048 MB MEM | 1 2000 MB Disk\n\nCoordinator node: 1 instance | 1.0 CPU | 2048 MB MEM | 1 1000 MB Disk\n\nContact Mesosphere before deploying this beta candidate service. Product support is available to approved participants in the beta test program.",
  "selected": false,
  "tags": [
    "elastic",
    "elasticsearch",
    "kibana",
    "x-pack"
  ],
  "version": "1.0.14-5.5.0-beta"
}
</pre>
This version is newer than we need.

<pre>
cat 4/package.json
{
  "description": "Elasticsearch 5, and optionally X-Pack",
  "framework": true,
  "maintainer": "support@mesosphere.io",
  "minDcosReleaseVersion": "1.9",
  "name": "beta-elastic",
  "packagingVersion": "3.0",
  "postInstallNotes": "DC/OS elastic service is being installed!\n\n\tDocumentation: https://docs.mesosphere.com/1.9/usage/service-guides/elastic\n\tIssues: https://docs.mesosphere.com/support/",
  "postUninstallNotes": "DC/OS elastic service has been uninstalled.",
  "preInstallNotes": "This DC/OS Service is currently a beta candidate undergoing testing as part of a formal beta test program. There may be bugs, incomplete features, incorrect documentation, or other discrepancies. Contact Mesosphere before deploying this beta candidate service. Product support is available to approved participants in the beta test program.",
  "selected": false,
  "tags": [
    "elasticsearch",
    "x-pack"
  ],
  "version": "1.0.13-5.4.1-beta"
}
</pre>

This is the one we want; so delete folder 5.
<pre>
rm -rf 5
</pre>

To get beta-kafka 1.1.22-0.10.1.0-beta. I had to remove folders 2 and 1 from universe/repo/packages/B/beta-kafka.

**STEP 4 NOTE:** To build local-universe use command "**sudo make DCOS_VERSION=1.9 local-universe**".  The DCOS_VERSION is required!

**Skip Step 5** I'll provide instructions later for that.

Copy the s3 folder

<pre>
sudo chown azureuser. local-universe.tar.gz
cp local-universe.tar.gz ~/djennings/
</pre>


## Update Images on S3 

<pre>
cd ~/s3
aws s3 sync . s3://djennings
</pre>
