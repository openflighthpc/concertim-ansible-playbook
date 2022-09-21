#!/bin/bash

# Script to set environment variables that are relied upon by `vagrant
# provision`.  Use as follows:
#
# ```
# cd vagrant/
# source scripts/prepare-env.sh
# vagrant up <HOST>
# ```

export AWS_ACCESS_KEY_ID=$( aws configure get aws_access_key_id )
export AWS_SECRET_ACCESS_KEY=$( aws configure get aws_secret_access_key )

# We assume here that `../ansible/secrets.enc` contains the line
# `GH_TOKEN=<my github token>`.  If so, we set that as an environment
# variable.
if [ -f ../ansible/secrets.enc ]; then
    while IFS="=" read variable value
    do
        if [ "${variable}" == "GH_TOKEN" ] ; then
            declare -x ${variable}=${value}
        fi
    done < <( ansible-vault view ../ansible/secrets.enc )
fi
