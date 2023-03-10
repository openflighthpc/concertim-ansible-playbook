#!/bin/bash

function relocate {
    # move certs to /etc/ssl
    ct='/data/private/share/etc/concurrent-thinking'
    if [ "$pver" != "3" ]; then
      mv $ct/ssl/certs/*.$1_crt.pem /etc/ssl/certs
      mv $ct/ssl/private/*.$1_key.pem /etc/ssl/private
      mv $ct/ssl/certs/concertim-CA_crt.pem /etc/ssl/certs
      mv $ct/ssl/certs/phoenix-CA_crt.pem /etc/ssl/certs
      cat /etc/ssl/certs/concertim-CA_crt.pem /etc/ssl/certs/phoenix-CA_crt.pem > /etc/ssl/certs/cacerts.pem
      # move asc and yml files to /etc/concurrent-thinking/appliance
      mv $ct/ssl/gpg/* $ct/appliance
    else
      mv $ct/ssl/*.$1_crt.pem /etc/ssl/certs
      mv $ct/ssl/private/*.$1_key.pem /etc/ssl/private
      mv $ct/ssl/concurrent-CA_crt.pem /etc/ssl/certs
      mv $ct/ssl/phoenix-CA_crt.pem /etc/ssl/certs
      cat /etc/ssl/certs/concertim-CA_crt.pem /etc/ssl/certs/phoenix-CA_crt.pem > /etc/ssl/certs/cacerts.pem
      # move asc and yml files to /etc/concurrent-thinking/appliance
      mv $ct/ssl/*.yml $ct/appliance
      mv $ct/ssl/*.asc $ct/appliance
    fi
    chown www-data $ct/appliance/release.yml
}

if [ $UID != 0 ]; then
    echo "Must be run as root"
    exit
fi
DELIA_WAIT=45
export HOME=/root
STAGE=$1
shift

ct='/data/private/share/etc/concurrent-thinking'
src='/usr/src/concurrent-thinking'

case $STAGE in

    # ------------------------------------------------------------
    reset)

    # # Remove ssl certificates (from certificates.tgz)
    for cert in $(tar tzf $src/certificates.tgz | grep '.pem$')
    do
        rm -f /etc/ssl/certs/$cert
        rm -f /etc/ssl/private/$cert
    done
    rm -f /etc/ssl/certs/apache_crt.pem
    rm -f /etc/ssl/private/apache_key.pem

    # # Remove non certificate contents of certificates.tzg
    rm -f $src/release.yml.asc

    # # Remove contents of appliance_config.dat (aka appliance-config.tgz)
    rm -f $src/security-pack.tgz
    rm -rf $src/bootstrap

    # # Remove contents of security-pack.tgz
    rm -f $src/security.yml
    rm -f $src/certificates.tgz
    rm -f $src/pack.yaml


    a2dissite redirect-http-to-https
    a2ensite allow-http
    cd /etc/apache2
    echo "Listen 80" > ports.conf
    /etc/init.d/apache2 reload
    cd /etc/apache2/conf-available
    sed -i "s/ServerName .*/ServerName command.appliance.local/" mia.server_name.conf
    ;;

    # ------------------------------------------------------------
    init)

    a2dissite ssl
    /etc/init.d/apache2 reload
	;;

    # ------------------------------------------------------------
    reopen)

    a2dissite allow-http
    a2ensite redirect-http-to-https
    /etc/init.d/apache2 reload
	;;

    # ------------------------------------------------------------
    config)

    HOST=$1
    DOMAIN=$2
    PUBLIC_IP=$3
    PUBLIC_MASK=$4
    GATEWAY_IP=$5
    PUBLIC_WILDCARD_MASK=$6
    cd /etc/apache2
    echo "Listen 443" >> ports.conf
    cd /etc/apache2/conf-available
    sed -i "s/ServerName .*/ServerName ${HOST}.${DOMAIN}/" mia.server_name.conf
    cd /etc/apache2/sites-available
    sed -i "s|RedirectMatch .*|RedirectMatch ^/(.*)$ \"https://${HOST}.${DOMAIN}/\$1\"|" redirect-http-to-https.conf
    a2ensite ssl
    /etc/init.d/apache2 reload
	;;

    # ------------------------------------------------------------
    security_prep)

    cd $src
    tar xvzf $src/appliance-config.tgz
    tar xvzf $src/security-pack.tgz

    cd $ct/ssl
    tar xvzf $src/certificates.tgz
    chown www-data $ct/ssl/private/*

    DOMAIN=`cat $ct/ssl/gpg/release.yml | grep domain_name | awk '{print $2}'`
    pver=`/opt/ruby-1.8/bin/ruby -e "require 'rubygems'; require 'yaml'; info = YAML.load_file('/data/private/share/etc/concurrent-thinking/appliance/release.yml'); puts \"#{info['pack_version']}\""`
    relocate $DOMAIN $pver
	;;

    # ------------------------------------------------------------
    security)

    HOST=$1
    DOMAIN=$2

    # we work out the domain dynamically here 
    # since if there's anything wrong with the value in ApplianceNetworkInterface then we'll never restore a backup
    DOMAIN=`cat $ct/appliance/release.yml | grep domain_name | awk '{print $2}'`

    ln -snf /etc/ssl/certs/${HOST}.${DOMAIN}_crt.pem /etc/ssl/certs/apache_crt.pem
    ln -snf /etc/ssl/private/${HOST}.${DOMAIN}_key.pem /etc/ssl/private/apache_key.pem

	;;

    # ------------------------------------------------------------
    run_post_migration_scripts)

    POST_ALWAYS_RUN_RESTORATION_SCRIPTS_DIR=$3
    PATH=/opt/ruby-1.8/bin:$PATH
    sudo -u www-data --preserve-env=PATH /usr/local/sbin/run_always_run_post_restoration_scripts.rb $POST_ALWAYS_RUN_RESTORATION_SCRIPTS_DIR
  ;;

    # ------------------------------------------------------------
    finalize)

    /etc/init.d/ganglia-monitor start
    /etc/init.d/delia restart

    # XXX - wait for DELIA to restart
    sleep $DELIA_WAIT


    echo "---- End of the appliance first time setup wizard ----"
	;;

    # ------------------------------------------------------------
    *)

    echo "Unrecognized stage: $STAGE"
	;;
esac
