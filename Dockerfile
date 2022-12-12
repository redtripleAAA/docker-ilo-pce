FROM centos:7
#FROM marcopas/docker-mailslurper

LABEL MAINTAINER=anas.hamra@illumio.com>

ADD ./rpms /var/tmp/rpms
ADD ./vens /var/tmp/vens
ADD ./certs /var/tmp/certs
ADD ./postfix /var/tmp/postfix
ADD ./mailslurper /var/tmp/mailslurper

RUN rpm --rebuilddb && yum install -y epel-release &&\
    yum install -y sudo \
                   vim-minimal &&\
    yum install -y /var/tmp/rpms/* && rm -rf /var/tmp/rpms/* && yum clean all

#Extra handy packages
RUN yum install -y byobu curl git htop man zip unzip vim wget nano sudo openssh-server sshpass iputils-ping telnet traceroute postfix systemd

### this probably isn't needed and given by docker
COPY files/limits.conf /etc/limits.conf
COPY files/sysctl.conf /etc/sysctl.conf
# COPY mailslurper/config.json /etc/mailslurper-config.json
# COPY mailslurper/mailslurper /usr/bin/mailslurper

### copy install script over and the scripts to create the initial org
COPY install.sh /usr/bin/illumio.sh

ENTRYPOINT /usr/bin/illumio.sh

### add the volumes after Illumio is installed
VOLUME /var/lib/illumio-pce
VOLUME /var/log/illumio-pce

### expose our standard ports, maybe configurable in the future
EXPOSE 8443
EXPOSE 8444
EXPOSE 6443

#EXPOSE 2500
#EXPOSE 8080
#EXPOSE 8085

##############################################################################################
# Dockerfile build+push commands:
# docker build -t ansred/illumio-docker-pce-amd64 . --no-cache=true --platform=linux/amd64
# Docker push ansred/illumio-docker-pce-amd64

##############################################################################################
# PCE commands:
# sudo -u ilo-pce illumio-pce-ctl cluster-status -w

##############################################################################################
### Docker Run command for reference

## Single-line Docker Run:
# sudo docker run --privileged -itd -p 8443:8443 -p 8444:8444 -p 6443:6443 -e PCE_FQDN="pce.illumio.consulting" -e PCE_SERVICE_DISCOVERY_FQDN="pce.consulting" -e PCE_EMAIL_ADDRESS="adm.pce@illumio.consulting" -e PCE_FULLNAME="Anas Hamra" -e PCE_PASSWORD="Illuminated1" -e PCE_ORG_NAME=Illumio --hostname pce.illumio.consulting --name pce ansred/illumio-docker-pce-amd64

##############################################################################################


