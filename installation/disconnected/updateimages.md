# Update files in S3

### Pull Current Images from S3

This is how to pull s3 bucket down to server you want to build images on.  Recommend you use a Cloud computer (Azure/AWS) because moving images up to s3 can be very slow depending on you'r upload speed. 

<pre>
sudo yum -y install epel-release
sudo yum install -y python2-pip

pip install --upgrade --user awscli
aws configure
</pre>

Provided ID and Key
<pre>

mkdir s3
cd s3
aws s3 sync s3://djennings . 
</pre>

## Install Some Prereqs

These are required for working with docker images.

<pre>
sudo yum install -y ipset unzip libtool-ltdl libseccomp policycoreutils-python 
sudo rpm -Uvh docker-engine-selinux-1.13.1-1.el7.centos.noarch.rpm 
sudo rpm -Uvh docker-engine-1.13.1-1.el7.centos.x86_64.rpm 
sudo systemctl start docker
</pre>

## Updates

### Get Latest Docker Engine RPM

CentOS EPEL includes a version of Docker; however, the version packaged did have some issues.

Download docker-engine from the [docker repo](https://yum.dockerproject.org/repo/main/centos/7/Packages/)

<pre>
curl -O https://yum.dockerproject.org/repo/main/centos/7/Packages/docker-engine-1.13.1-1.el7.centos.x86_64.rpm
curl -O https://yum.dockerproject.org/repo/main/centos/7/Packages/docker-engine-selinux-1.13.1-1.el7.centos.noarch.rpm
</pre>

Copy the rpm's to the s3 folder

### Get nginx Docker Images

The DC/OS installer needs nginx.

<pre>
sudo docker pull nginx
sudo docker save -o nginx.tar docker.io/nginx
sudo chown azureuser. nginx.tar
gzip nginx.tar 
</pre>

Copy the nginx.tar.gz to the s3 folder.

### Update Docker Images For Trinity 

#### Pull Docker Images 
 
Pulls the images from Docker down to local machine.
 
- Edit Docker Pull Script (docker-pull.sh) and set the TAG
- Run Script
  <pre>
  sudo bash docker-pull.sh
  </pre>
- You'll be prompted for your Docker username and password (you need permissions to esritrinity)
- Script takes a few minutes to run

#### Save Docker Images

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
  
#### Copy New Images to s3 Folder

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

### Created local-universe

To build on centos install pre-reqs

<pre>
sudo yum -y install epel-release
sudo yum -y install git maven
sudo yum -y install python34
</pre>

For offline installation of DCOS if you need access to packages in Universe you need to create a [Local Universe](https://dcos.io/docs/1.9/administering-clusters/deploying-a-local-dcos-universe/) 

Follow these steps

<pre>
git clone https://github.com/mesosphere/universe.git --branch version-3.x
cd universe/docker/local-universe/
sudo make base
</pre>

Look up versions of apps you need from DC/OS 

As of Trinity TAG:  0.9.4.241
- beta-elastic: 1.0.14-5.5.1-beta
- beta-kafka: 1.1.22-0.10.1.0-beta
- marathon-lb: 1.8.0
- dcos-enterprise-cli: 1.0.8

Run make
<pre>
sudo make DCOS_VERSION=1.9.2 DCOS_PACKAGE_INCLUDE="marathon-lb:1.8.0,beta-kafka:1.1.22-0.10.1.0-beta,beta-elastic:1.0.14-5.5.0-beta,dcos-enterprise-cli:1.0.8" local-universe
</pre>

Copy local-universe.tar.gz to the s3 folder

<pre>
sudo chown azureuser. local-universe.tar.gz
cp local-universe.tar.gz ~/s3/
</pre>


## Sync Changes from Local Folder to S3

<pre>
cd ~/s3
aws s3 sync . s3://djennings --delete
</pre>
