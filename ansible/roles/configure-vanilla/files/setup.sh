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

    # HOST='command'
    # DOMAIN='appliance.local'

    # # Setup factory certs.
    # cd $ct/ssl
    # tar xvzf $src/factory-certificates.tgz
    # chown www-data $ct/ssl/private/*
    # pver=`/opt/ruby-1.8/bin/ruby -e "require 'rubygems'; require 'yaml'; info = YAML.load_file('/data/private/share/etc/concurrent-thinking/appliance/release.yml'); puts \"#{info['pack_version']}\""`
    # relocate $DOMAIN $pver

    a2dissite redirect-http-to-https
    a2ensite allow-http
    cd /etc/apache2
    echo "Listen 80" > ports.conf
    # rm -f /etc/monit/conf.d/knockd-eth0
    # cp /usr/local/etc/apache2-http.monit /etc/monit/conf.d/apache2
    # cp /usr/local/etc/knockd-eth1-unconfigured.monit /etc/monit/conf.d/knockd-eth1
    # /usr/sbin/monit reload
    /etc/init.d/apache2 reload
    cd /etc/apache2/conf-available
    sed -i "s/ServerName .*/ServerName command.appliance.local/" mia.server_name.conf
    # # sync apache2 changes to upgrade rootfs
    # rm -rf /upgrade/etc/apache2
    # cp -a /etc/apache2 /upgrade/etc/apache2
    # # get a link-local address on eth1
    # /usr/sbin/avahi-autoipd --force-bind -Dw eth1
    # # restart knockd-eth1
    # pid=`cat /var/run/knockd-eth1.pid`
    # if [ "$pid" ]; then
    #     kill $pid
    #     sleep 1
    # fi
    # /usr/sbin/knockd -d -i eth1:avahi -c /etc/knockd-eth1.conf
    # # reset network interfaces file
    # cp /etc/network/interfaces.unconfigured.template /etc/network/interfaces
    # # sync network interfaces changes to upgrade rootfs
    # cp -a /etc/network/interfaces /upgrade/etc/network/interfaces
    # # Restart delia to pick up new network interfaces
    # /etc/init.d/delia restart
    # # XXX - wait for DELIA to restart
    # sleep $DELIA_WAIT
    ;;

    # ------------------------------------------------------------
    init)

    a2dissite ssl
    /etc/init.d/apache2 reload
    # # stop gmond
    # /etc/init.d/ganglia-monitor stop
    # # remove any global address on eth1
    # for addr in `ip -4 -o addr show eth1 | grep global | awk '{print $4}' | xargs`; do
    #     ip addr del $addr dev eth1
    # done
    # # remove any LL route on the cluster management interface (eth0)
    # ip route del 169.254.0.0/16 dev eth0
    # # remove the default route so the eth1 LL route takes precedence
    # for a in `ip route | grep via | awk '{print $3;}'`; do
    #     ip route del default via $a
    # done
    # # forcibly add a default route for LL routing to eth1 in case it's gone away for some reason
    # ip route add default metric 1000 dev eth1
	;;

    # ------------------------------------------------------------
    reopen)

    # # now we are reopened, we can down any link local addresses 
    # LL=`ip -4 -o address show dev eth1 | grep "link" | awk '{print $4}'`
    # if [ "$LL" ]; then
	      # ip addr del $LL dev eth1
	      # # kill any autoipd process running for eth1
	      # /usr/sbin/avahi-autoipd -k eth1
    # fi
    # # we are in the reopen stage, so now we disable http access
    a2dissite allow-http
    a2ensite redirect-http-to-https
    /etc/init.d/apache2 reload
    # # sync apache2 changes to upgrade rootfs
    # rm -rf /upgrade/etc/apache2
    # cp -a /etc/apache2 /upgrade/etc/apache2
	;;

    # ------------------------------------------------------------
    config)

    HOST=$1
    DOMAIN=$2
    PUBLIC_IP=$3
    PUBLIC_MASK=$4
    GATEWAY_IP=$5
    PUBLIC_WILDCARD_MASK=$6
    # network interface configuration
    # ip addr add $PUBLIC_IP/$PUBLIC_MASK dev eth1 broadcast + scope global
    # if [ "$GATEWAY_IP" != "0.0.0.0" ]; then
    #     ip route add default via $GATEWAY_IP
    # fi
    # # restart knockd-eth1
    # pid=`cat /var/run/knockd-eth1.pid`
    # if [ "$pid" ]; then
    #     kill $pid
    #     sleep 1
    # fi
    # cp /usr/local/etc/knockd-eth1-configured.monit /etc/monit/conf.d/knockd-eth1
    # /usr/sbin/knockd -d -i eth1 -c /etc/knockd-eth1.conf

    # # update issue.net with job and release information
    # /usr/local/sbin/update-issue.net.sh

    # # install template file to interfaces file
    # cp /etc/network/interfaces.configured.template /etc/network/interfaces
    # sed -i "s/%PUBLIC_IP%/$PUBLIC_IP/g" /etc/network/interfaces
    # sed -i "s/%PUBLIC_NETMASK%/$PUBLIC_WILDCARD_MASK/g" /etc/network/interfaces
    # if [ "$GATEWAY_IP" != "0.0.0.0" ]; then
    #     sed -i "s/%GATEWAY%/$GATEWAY_IP/g" /etc/network/interfaces
    # else
    #     sed -i "s/gateway %GATEWAY%//g" /etc/network/interfaces
    # fi
    # # sync network interfaces changes to upgrade rootfs
    # cp -a /etc/network/interfaces /upgrade/etc/network/interfaces
    # generate resolv.conf to point to ourselves
    # echo "search $DOMAIN" > /etc/resolv.conf
    # echo "nameserver $PUBLIC_IP" >> /etc/resolv.conf	
    # # perform apache ssl prep for proceeding to reopen stage
    cd /etc/apache2
    echo "Listen 443" >> ports.conf
    cd /etc/apache2/conf-available
    sed -i "s/ServerName .*/ServerName ${HOST}.${DOMAIN}/" mia.server_name.conf
    cd /etc/apache2/sites-available
    sed -i "s|RedirectMatch .*|RedirectMatch ^/(.*)$ \"https://${HOST}.${DOMAIN}/\$1\"|" redirect-http-to-https.conf
    a2ensite ssl
    /etc/init.d/apache2 reload
    # cp /usr/local/etc/apache2-https.monit /etc/monit/conf.d/apache2
    # /usr/sbin/monit reload
    # # sync apache2 changes to upgrade rootfs
    # rm -rf /upgrade/etc/apache2
    # cp -a /etc/apache2 /upgrade/etc/apache2
	;;

    # ------------------------------------------------------------
    security_prep)

    cd $src
    tar xvzf $src/appliance-config.tgz
    tar xvzf $src/security-pack.tgz

    cd $ct/ssl
    # # we might need to update our internal certificates to the latest version
    # if [ -e $src/appliance.local_certs.tar.gz ]; then
    #     tar xvzf $src/appliance.local_certs.tar.gz
    # fi
    # # we might need to update our domain certificates to the latest version
    # if [ -e $src/latest-certificates.tgz ]; then
    #     tar xvzf $src/latest-certificates.tgz
    # # otherwise just use our backup certificates
    # else
        tar xvzf $src/certificates.tgz
    # fi
    chown www-data $ct/ssl/private/*

    DOMAIN=`cat $ct/ssl/gpg/release.yml | grep domain_name | awk '{print $2}'`
    pver=`/opt/ruby-1.8/bin/ruby -e "require 'rubygems'; require 'yaml'; info = YAML.load_file('/data/private/share/etc/concurrent-thinking/appliance/release.yml'); puts \"#{info['pack_version']}\""`
    relocate $DOMAIN $pver
	;;

    # ------------------------------------------------------------
    security)

    HOST=$1
    DOMAIN=$2
    # JOB=$3
    # LICENSE=$4
    # DISKPASS=$5
    # BOOTPASS=$6
    # REMOTEPASS=$7
    # BIOSPASS=$8
    # ROOTPASS=$9

    # we work out the domain dynamically here 
    # since if there's anything wrong with the value in ApplianceNetworkInterface then we'll never restore a backup
    DOMAIN=`cat $ct/appliance/release.yml | grep domain_name | awk '{print $2}'`

    ln -snf /etc/ssl/certs/${HOST}.${DOMAIN}_crt.pem /etc/ssl/certs/apache_crt.pem
    ln -snf /etc/ssl/private/${HOST}.${DOMAIN}_key.pem /etc/ssl/private/apache_key.pem

    # # check date, and fudge it if necessary
    # /usr/local/sbin/check-date-and-fudge.sh

    # # GPG setup
    # echo ">>>GPG SETUP<<<"
    # /usr/bin/gpg --no-tty --import < $ct/appliance/$JOB.asc
    # (sleep 1; echo -e '5\ny\n'; sleep 1) | /usr/bin/gpg --no-tty --command-fd 0 --edit-key "$JOB" trust
    # /usr/bin/gpg --yes --no-tty --batch --passphrase "$LICENSE" --lsign-key 'Concurrent Thinking Appliance Licenses'
    # echo ">>>RELEASE INSTALLATION<<<"
    # chown www-data $ct/appliance/release.yml
    # echo ">>>KEY SIGNING<<<"
    # /usr/bin/gpg --yes --no-tty --batch --default-key "$JOB" --passphrase "$LICENSE" --lsign-key 'Concurrent Thinking Development Team'
    # /usr/bin/gpg --yes --no-tty --batch --default-key "$JOB" --passphrase "$LICENSE" --lsign-key 'Concurrent Thinking Appliance Patches'
    # # sync GPG changes to upgrade rootfs
    # rm -rf /upgrade/root/.gnupg
    # cp -a /root/.gnupg /upgrade/root/.gnupg
    # # disk and boot passwords
    # echo ">>>DISK PASSWORD<<<"
    # sed -i '192s|.*|DISK_PASSWORD=\`ruby /usr/local/sbin/gen_disk_password.rb \"'$DISKPASS'\"\`|' "/usr/sbin/safe.install_bootloader"
    # BOOTPASSMD5=`mkpasswd -H md5 $BOOTPASS`
    # echo ">>>BOOT PASSWORD<<<"
    # sed -i "125s|^password --md5 .*$|password --md5 $BOOTPASSMD5|" "/usr/sbin/safe.install_bootloader"
    # echo ">>>UPDATE LUKS PASSWORD<<<"
    # echo -n `echo "$DISKPASS" | cut -c1-8` | md5sum | cut -f1 -d" " > /etc/keys/rootfs.key.new

    # if [ -e /sys/block/hda ]; then
    #     DISK=/dev/hda
    # elif [ -e /sys/block/vda ]; then
    #     # KVM virtio disk
    #     DISK=/dev/vda
    # else
    #     DISK=/dev/sda
    # fi
    # PART2=${DISK}2
    # PART3=${DISK}3
        
    # OLDSLOT=`cryptsetup luksDump $PART2 | grep ENABLED | cut -c10-10`
    # NEWSLOT=`cryptsetup luksDump $PART2 | grep DISABLED | head -n1 | cut -c10-10`
    # cryptsetup -S $NEWSLOT -d /etc/keys/rootfs.key luksAddKey $PART2 /etc/keys/rootfs.key.new
    # cryptsetup -q -d /etc/keys/rootfs.key.new luksKillSlot $PART2 $OLDSLOT
    # cryptsetup -S $NEWSLOT -d /etc/keys/rootfs.key luksAddKey $PART3 /etc/keys/rootfs.key.new
    # cryptsetup -q -d /etc/keys/rootfs.key.new luksKillSlot $PART3 $OLDSLOT
    # mv /etc/keys/rootfs.key.new /etc/keys/rootfs.key
    # echo ">>>BOOTLOADER INSTALLATION<<<"
    # /usr/sbin/safe.install_bootloader 1 2 3
    # echo ">>>BIOS PASSWORD<<<"
    # # Only update BIOS if it's the right system manufacturer and
    # # BIOS version!
    # BIOSDATE=`dmidecode -s bios-release-date`
    # SYSMANF=`dmidecode -s system-manufacturer`
    # if [ "$SYSMANF" == "Supermicro" -a "$BIOSDATE" == "03/05/2008" ]; then
	      # # bios password can't be explicitly set from CLI so we use a
    #     # hash on the job number to select one to use from a password pool.
	      # idx=$(printf %02d $(expr $(printf '%d' 0x`echo $JOB | md5sum - | cut -c1-2`) % 20))
	      # echo 2 | /data/private/share/vanilla/cmospwd -d -r /data/private/share/vanilla/$idx.dat
    # else
	      # echo ">>> *** NOT UPDATING CMOS ($SYSMANF, $BIOSDATE) *** <<<"
    # fi
    # # root password
    # echo ">>>ROOT PASSWORD<<<"
    # echo "root:$ROOTPASS" | chpasswd
    # # sync password changes to upgrade rootfs
    # cp -a /etc/shadow /upgrade/etc/shadow
    # echo ">>>DELIA RESTART<<<"
    # # restart delia to use new certificates
    # /etc/init.d/delia restart
    # # XXX - wait for DELIA to restart
    # sleep $DELIA_WAIT
	;;

    # ------------------------------------------------------------
    run_post_migration_scripts)

    POST_ALWAYS_RUN_RESTORATION_SCRIPTS_DIR=$3
    PATH=/opt/ruby-1.8/bin:$PATH
    sudo -u www-data --preserve-env=PATH /usr/local/sbin/run_always_run_post_restoration_scripts.rb $POST_ALWAYS_RUN_RESTORATION_SCRIPTS_DIR
  ;;

    # ------------------------------------------------------------
    finalize)

    # # Set the link-local route to use the management network. This allows
    # # controls to establish a VPN session over a link-local address on the
    # # management network.
    # ip route replace 169.254.0.0/16 dev eth0 scope link metric 1000

    # # disable dhcp by default - can be enabled on a restore or in the UI
    # /sbin/insserv -r isc-dhcp-server

    # cp /usr/local/etc/knockd-eth0.monit /etc/monit/conf.d/knockd-eth0
    # /usr/sbin/monit reload
    /etc/init.d/ganglia-monitor start
    # /etc/init.d/knockd restart
    /etc/init.d/delia restart

    # XXX - wait for DELIA to restart
    sleep $DELIA_WAIT

    # copy timezone to resources so the uml can use it
    # cp /etc/timezone /resources/etc/timezone

    # force "startup" initialization of certs etc. within UML
    # sudo -u ajaxterm ssh root@console /etc/rc.local

    # # execute scheme specific bootstrap script if it exists
    # if [ -x "$src/bootstrap/bootstrap.sh" ]; then
    #     /bin/bash $src/bootstrap/bootstrap.sh
    # fi

    echo "---- End of the appliance first time setup wizard ----"
	;;

    # ------------------------------------------------------------
    *)

    echo "Unrecognized stage: $STAGE"
	;;
esac
