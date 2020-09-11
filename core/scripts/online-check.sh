#!/usr/bin/env bash

##
# Description
#
# Check to see when the faasd instance is online. Script will
# loop until it gets a status 200 from the instance.
##

# Exit immediately if there is an error
set -e

# Validate Environment Variables
[[ -z "${TF_VAR_do_subdomain}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${TF_VAR_do_domain}" ]] && echo "Missing Env Var" && exit 1

# Vaildate Required Files
[[ ! -f fakelerootx1.pem ]] && echo "Missing File" && exit 1
[[ ! -f terraform.tfstate ]] && echo "Missing File" && exit 1

PASSWORD=$(cat terraform.tfstate | jq -r '.resources[] | select(.name == "password") | .instances[].attributes.result')

printf "Waiting for online"

until $(
  curl \
    --silent \
    --location \
    --fail \
    --output /dev/null \
    --max-time 3 \
    --cacert fakelerootx1.pem \
    --user "admin:${PASSWORD}" \
    "https://${TF_VAR_do_subdomain}.${TF_VAR_do_domain}/ui/"
); do
  printf "."
  sleep 5s
done