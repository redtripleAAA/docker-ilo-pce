
# PCE in a docker container

## How it works?

The container contains a install script that will bring up the PCE on the
docker host with the supplied credentials and data.

## What do you need?

* Docker for Mac or Windows installed or a working docker install on Linux.
* a set of current PCE RPMs deployed to the rpms/ directory
* a VEN bundle (optional) deployed to the vens/ directory

## Before you start

### What to do on your host system?

Be sure to add the host that you supplied via --hostname and as the PCE_FQDN in
your /etc/hosts file.

On OSX this is /private/etc/hosts and the entry should look like this:

  127.0.0.1 pce.docker.com

## Runtime configuration

The container tries to set the Illumio PCE runtime env settings via a set of
environment variables via the batch option of illumio-pce-env setup --batch

### Environment variables

#### Mandatory environment variables

* PCE_FQDN - the PCE FQDN used in the configuration. Be sure to also set the docker hostname to this with --hostname
* PCE_EMAIL_ADDRESS - the email address to use when sending mails and the initial user for the PCE
* PCE_FULLNAME - full name of the initial user
* PCE_PASSWORD - the password to use for the initial user
* PCE_ORG_NAME - the name of the initial org

Optional environment variables

* PCE_SERVICE_DISCOVERY_FQDN (default: $PCE_FQDN)
* PCE_FRONTEND_HTTPS_PORT (default: 8443)
* PCE_FRONTEND_EVENT_SERVICE_PORT (default: 8444)
* PCE_FRONTEND_MANAGEMENT_HTTPS_PORT (default: 8443)
* PCE_SYSLOG_EVENT_EXPORT_FORMAT (default: json)


## How do i start this container?

### First run - Initialisation

I experimented with privileged mode for this container, but it turns out the
PCE works without it and should be running fine without using privileged.

docker run -it -d -p 8443:8443 -p 8444:8444 -e PCE_FQDN="pce.docker.com" -e PCE_SERVICE_DISCOVERY_FQDN="pce.docker.com" -e PCE_EMAIL_ADDRESS="alex.goller@illumio.com" -e PCE_FULLNAME="Alexander Goller" -e PCE_PASSWORD="Illuminated1" -e PCE_ORG_NAME=Illumio --hostname pce.docker.com --name pce illumio-docker-pce

Explanation:

*  -d - detach container
*  -p 8443:8443 - expose frontend service on localhost
*  -p 8444:8444 - expose event service on localhost
*  -e sets one environment variable at a time for all the above mentioned env vars
*  --hostname - sets the docker hostname
*  --name - sets the docker name
*  illumio-docker-pce - name of the docker image

To save you from passing all the variables via environment variables you can
also create a env.list file like the one supplied with this package and use:

docker run -it -d -p 8443:8443 -p 8444:8444 --env-file env.list --hostname pce.docker.com --name pce illumio-docker-pce


### Subsequent runs

docker run --privileged -d -p 8443:8443 -p 8444:8444 --hostname pce.docker.com illumio-docker-pce

## How can i access my PCE from the commandline?

Execute the following command:

  docker run -it illumio-docker-pce /bin/sh

## How can i copy files to my PCE?

  docker cp <filename> illumio-docker-pce:/some/path

## About volumes

This image will automatically create two docker volumes.

* /var/lib/illumio
* /var/log/illumio

## How to build the image

The Dockerfile is supplied as Dockerfile. Just build it with 'docker build'.

The Dockerfile uses three files to do the PCE bootstrapping:

* install.sh - copied to /usr/bin/illumio.sh - bootstrapping and after bootstrapping running the PCE

### Software installed

Directories for installing software:

* rpms/ - this will be copied to /var/tmp/rpms, any RPM in there will be installed with all dependencies
* vens/ - place VEN bundles here and they will be installed using ven-software-install. Right now the last VEN bundle in the list as seen by the shell (/var/tmp/vens/\*) will be installed

# Upgrading to a new version

Just move the corresponding RPMS for the new PCE version into the rpms/
directory and rebuild the image.  Do the same if there is a new VEN bundle that
you want to support.

# TODO

* error handling on strange inputs for the environment variables is very poor
  right now
* handling of updates - maybe check versions and do a DB migrate on startup
