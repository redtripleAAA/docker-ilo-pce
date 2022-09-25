#!/bin/sh

PCE_ENV=/opt/illumio-pce/illumio-pce-env
PCE_CTL=/opt/illumio-pce/illumio-pce-ctl
PCE_DB=/opt/illumio-pce/illumio-pce-db-management
PCE_INSTALLED=/etc/pce-installed
SUDO="sudo -u ilo-pce"

function run_pce()
{
    echo "Starting the Illumio PCE"
    $SUDO $PCE_CTL start
    while true; do
        $SUDO $PCE_CTL status
        sleep 60
    done
}

if [ ! -e $PCE_INSTALLED ]; then
    echo "Installing Illumio PCE runtime"
   #$PCE_ENV setup --generate-cert -b \ This is to generate a temp cert
    $PCE_ENV setup -b \
        pce_fqdn=${PCE_FQDN:=pce-container.illumio.consulting} \
        service_discovery_fqdn=${PCE_SERVICE_DISCOVERY_FQDN:=$PCE_FQDN} \
        node_type=snc0 \
        email_address=$PCE_EMAIL_ADDRESS \
        front_end_https_port=${PCE_FRONTEND_HTTPS_PORT:=8443} \
        front_end_event_service_port=${PCE_FRONTEND_EVENT_SERVICE_PORT:=8444} \
        front_end_management_https_port=${PCE_FRONTEND_MANAGEMENT_HTTPS_PORT:=6443} \
        syslog_event_export_format=${PCE_SYSLOG_EVENT_EXPORT_FORMAT:=json} \
        expose_user_invitation_link=true \
        login_banner="Illumio 2022" \
        &&\
    

    # Copy Let's encrypt cert
            cd /var/lib/illumio-pce/cert
            rm -f server.crt server.key
            cp /var/tmp/certs/* /var/lib/illumio-pce/cert
            cd /var/lib/illumio-pce/cert && chown ilo-pce server.crt server.key
            cd /var/lib/illumio-pce/cert && chmod 400 server.crt server.key

    $SUDO $PCE_CTL start --runlevel 1 &&\
    $SUDO $PCE_CTL status -sv -w 300
    $SUDO $PCE_DB setup
    $SUDO $PCE_CTL set-runlevel 5 &&\
    touch $PCE_INSTALLED
    if [ -e $PCE_INSTALLED ]; then
        echo "PCE installed successfully"
    fi
    $SUDO $PCE_CTL status -sv -w 300
    $SUDO ILO_PASSWORD=$PCE_PASSWORD $PCE_DB create-domain --full-name "$PCE_FULLNAME" --user-name "$PCE_EMAIL_ADDRESS" --org-name $PCE_ORG_NAME
    if [ -e /var/tmp/vens/illumio-ven-bundle-*.bz2 ]; then
        for i in /var/tmp/vens/illumio-ven-bundle-*.bz2
        do
            SHORTNAME=`echo $i | sed -e 's/.*illumio-ven-bundle-//g; s/\.tar\.bz2//g'`
            yes yes | $SUDO $PCE_CTL ven-software-install --orgs 1 --default  $i
        done
    fi
    run_pce
else
    run_pce
fi
