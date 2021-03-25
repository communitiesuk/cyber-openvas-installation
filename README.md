# Openvas Scripts

This repository contains scripts to build an OVF image OpenVAS, current versions being:

```
OpenVAS 20.08
Ubuntu 20.04.1 LTS 
4GB RAM
20GB storage
```

## Overview of scripts

| Script                        | Purpose |
| :------------- |:-------------|
| openvas_packerfile.json       | Packer script to build image     |
| http/user-data                | Used to bootstrap the image      |
| http/meta-data                | Empty but required file     |
| scripts/openvas.sh		| Main installation script called by packer shell   | |provisioner |
|scripts/git.sh          | Child script called by openvas.sh |
|scripts/git2.sh          | Child script called by openvas.sh |
|scripts/ospd.sh          | Child script called by openvas.sh |
|scripts/gvmd.sh          | Child script called by openvas.sh |
|scripts/postgres.sh      | Child script called by openvas.sh |
|scripts/postgres.sql     | Child script called by postgres.sh |
|sample_report.pdf        | Sample scan report of vulnerable Metasploitable image |
|Instructions.docx        | Operating instructions |




#### The following pre-requisites are required to build the image:

* Packer
* VirtualBox
* Kernel virtualisation enabled
* If you are running Hyper-V or Docker you will need to disable the service
* At least 30GB free space


#### In order to instigate  build run the following command (The build should take around 3 hours to complete) :

```
packer build -force openvas_packerfile.json
```


#### The source code is compiled from the following repositories :

```
https://github.com/greenbone/gvm-libs.git
https://github.com/greenbone/openvas-smb.git
https://github.com/greenbone/openvas.git
https://github.com/greenbone/ospd.git
https://github.com/greenbone/ospd-openvas.git
https://github.com/greenbone/gvmd.git
https://github.com/greenbone/gsa.git
```

#### This builds the following components : 

| Component         | Purpose | commands to manage | logs |
| :------------- |:-------------|:-------------|:-----------------
|GSAD | Web front end | service gsa start/stop/restart | /opt/gvm/var/log/gvm/gsad.log
|GVMD | Vulnerability manager | service gvm start/stop/restart | /opt/gvm/var/log/gvm/gvmd.log
|Scanner | OpenVAS scanner | service openvas start/stop/restart | /opt/gvm/var/log/gvm/openvas.log


If you want to change the password in the user-data file you can generate it using the following command and it will prompt for the password to hash :

```
mkpasswd --method=SHA-512 --rounds=4096
```

By default the application listens on port 443 and uses a self signed cert. If you are running locally on VirtualBox you can hit the front end on https://localhost (assuming you have forwarded port 443 in VirtualBox)


### Definition updates

It is necessary to regularly update the feeds and NVT definitions to ensure the latest vulnerabilities are being scanned for. There is a script which is ran upon startup which will do this as follows :

```
/opt/gvm/updatedefs.sh
```

This can be ran on a regular basis by incorporating it into a cron job (note it must be ran as the gvm user). As an example (run every day at midnight):

```
echo "0 0 * * * /opt/gvm/updatedefs.sh >> /opt/gvm/var/log/gvm/update.log" | crontab -
```

### Post build tasks

The image is built with pre-defined passwords which should be changed when a VM is created from the image.

#### Linux admin password

ssh onto the VM and run the following command :

```
passwd 
```

Then input a suitable password.

#### Web console password

ssh onto the VM and run the following command :

```
gvmd --user=gvm --new-password=new_password
```