#!/bin/bash


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



    ;;

    # ------------------------------------------------------------
    init)

	;;

    # ------------------------------------------------------------
    reopen)

	;;

    # ------------------------------------------------------------
    config)

	;;

    # ------------------------------------------------------------
    security_prep)


	;;

    # ------------------------------------------------------------
    security)

	;;

    # ------------------------------------------------------------
    run_post_migration_scripts)

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
