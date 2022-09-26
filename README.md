
# PCE in a docker container

## How it works?
The container contains a install script that will bring up the PCE on the
docker host with the supplied credentials and data.




## What do you need?
* Docker host (Windows/Linux 64x CPU) to run the container 
* Docker host (Apple MacOS M1 or RaspberryPi ARM in general will work only to build the dockerfile)
* a set of current PCE RPMs deployed to the rpms/ directory (https://support.illumio.com/software/download.html#pce_software/download)
* a VEN bundle (optional) deployed to the vens/ directory (https://support.illumio.com/software/download.html#ven/download)
* Valid certs matches the hostname you will be using (server.crt + server.key) https://docs.illumio.com/core/22.2/Content/Guides/pce-install-upgrade/preparation/requirements-for-pce-installation.htm#tls-ssl-requirements
* Optional to have SendGrid/SendinBlue free plan APIkey+secret to enable email service https://docs.sendgrid.com/for-developers/sending-email/postfix 




## Before you start

### What to do on your host system?

Be sure to add the host that you supplied via --hostname and as the PCE_FQDN in
your /etc/hosts file.

On OSX this is /private/etc/hosts and the entry should look like this:
```
  127.0.0.1   pce-container.illumio.consulting
  10.0.12.201 pce-container.illumio.consulting
```
Note: If you have a registered domain and then you can add (A Record DNS type) for the PCE FQDN, and then you don't have to edit your local host file

## Runtime configuration

The container tries to set the Illumio PCE runtime env settings via a set of
environment variables via the batch option of illumio-pce-env setup --batch

### Environment variables

#### Mandatory environment variables
```
* PCE_FQDN - the PCE FQDN used in the configuration. Be sure to also set the docker hostname to this with --hostname
* PCE_EMAIL_ADDRESS - the email address to use when sending mails and the initial user for the PCE
* PCE_FULLNAME - full name of the initial user
* PCE_PASSWORD - the password to use for the initial user
* PCE_ORG_NAME - the name of the initial org
```
Optional environment variables
```
* PCE_SERVICE_DISCOVERY_FQDN (default: $PCE_FQDN)
* PCE_FRONTEND_HTTPS_PORT (default: 8443)
* PCE_FRONTEND_EVENT_SERVICE_PORT (default: 8444)
* PCE_FRONTEND_MANAGEMENT_HTTPS_PORT (default: 8443) (This is to access the PCE web portal, can be configered Example 6443)
* PCE_SYSLOG_EVENT_EXPORT_FORMAT (default: json)
```






## How do i start this container?

### First run - Initialisation

I experimented with privileged mode for this container, but it turns out the
PCE works without it and should be running fine without using privileged.


* Single line
docker run --privileged -it -d -p 8443:8443 -p 8444:8444 -p 6443:6443 -e PCE_FQDN="pce-container.illumio.consulting" -e PCE_SERVICE_DISCOVERY_FQDN="pce-container.illumio.consulting" -e PCE_EMAIL_ADDRESS="anas.hamra@illumio.com" -e PCE_FULLNAME="Anas Hamra" -e PCE_PASSWORD="Illuminated1" -e PCE_ORG_NAME=Illumio --hostname pce-container.illumio.consulting --name pce ansred/illumio-docker-pce-amd64

* Multiple lines:
```
docker run --rm --privileged -it -d -p 8443:8443 -p 8444:8444 -p 6443:6443 \
          -e PCE_FQDN="pce-container.illumio.consulting" \
          -e PCE_SERVICE_DISCOVERY_FQDN="pce-container.illumio.consulting" \
          -e PCE_EMAIL_ADDRESS="anas.hamra@illumio.com" \
          -e PCE_FULLNAME="Anas Hamra" \
          -e PCE_PASSWORD="Illuminated1" \
          -e PCE_ORG_NAME=Illumio \
          –v /sys/fs/cgroup:/sys/fs/cgroup:ro
          --hostname pce-container.illumio.consulting \
          --name pce \
          ansred/illumio-docker-pce-amd64
```

Explanation:

*  --rm (Optional if you want to delete the container when it stops)
*  -it (interactive: To be used when typing commands in the container)
*  -d - detach container
*  -p 8443:8443 - expose frontend service
*  -p 8444:8444 - expose event service
*  -p 6443:6443 - expose portal UI service (Optional if not using the default 8443 for both frontend+UI)
*  -e sets one environment variable at a time for all the above mentioned env vars
*  –v /sys/fs/cgroup:/sys/fs/cgroup:ro (Optional in case Systemd will be used) Ref # https://github.com/docker-library/docs/tree/master/centos#systemd-integration
*  --hostname - sets the docker hostname
*  --name - sets the docker name
*  ansred/illumio-docker-pce-amd64 - name of the docker image

* Tip # To save you from passing all the variables via environment variables you can
also create a env.list file like the one supplied with this package and use:
```
docker run -it -d -p 8443:8443 -p 8444:8444 -p 6443:6443 --env-file env.list --hostname pce-container.illumio.consulting --name pce ansred/illumio-docker-pce-amd64
```


## How can i access my PCE from the commandline?

SSH to the docker host and make sure the pce container is running, you can run command: (docker ps -a | grep pce)
Execute the following command:
```
  docker run -it pce bash
```


## How can i copy files to my PCE?
```
  docker cp <filename> pce:/some/path
```



## About volumes

This image will automatically create few docker volumes.

* /var/lib/illumio
* /var/log/illumio
* /var/tmp/certs
* /var/tmp/postfix
* /var/tmp/mailslurper






## How to build the image
The Dockerfile is supplied as Dockerfile. Just build it with 'docker build'.

The Dockerfile uses three files to do the PCE bootstrapping:

* install.sh - copied to /usr/bin/illumio.sh - bootstrapping and after bootstrapping running the PCE



# Build the image out of the Dockerfile
```
docker build -t ansred/illumio-docker-pce-amd64 . --no-cache=true --platform=linux/amd64
```

# Push the iamge to a private dockerhub registry if you wish (use Docker login command first)
```
docker push ansred/illumio-docker-pce-amd64
```





### Software installed
Directories for installing software:

* rpms/        - this will be copied to /var/tmp/rpms, any RPM in there will be installed with all dependencies
* vens/        - place VEN bundles here and they will be installed using ven-software-install. Right now the last VEN bundle in the list as seen by the shell (/var/tmp/vens/\*) will be installed
* certs/       - Valid certs will be copied over during the docker build into the image
* postfix/     - settings as per the SendGrid instructions will be copied over
* mailslurper/ - base settings will be copied







# Upgrading to a new version
Just move the corresponding RPMS for the new PCE version into the rpms/
directory and rebuild the image.  Do the same if there is a new VEN bundle that
you want to support.
Note: Make sure to have valid certs as well in the certs/ directory







# TODO
* error handling on strange inputs for the environment variables is very poor right now
* handling of updates - maybe check versions and do a DB migrate on startup
* Running the CentOS base image with systemd enabled
* Install and run Chrony + Postfix
* Configure setcap to enable External access on port 443 - front_end_management_https_port: 443 


  

Thanks to Alex Goller for providing the base dockerfile
