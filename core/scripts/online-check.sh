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
[[ ! -f terraform.tfstate ]] && echo "Missing File" && exit 1
[[ "${ENVIRONMENT}" == "staging" ]] && [[ ! -f fakelerootx1.pem ]] && echo "Missing File" && exit 1

PASSWORD=$(cat terraform.tfstate | jq -r '.resources[] | select(.name == "password") | .instances[].attributes.result')
DOMAIN="${TF_VAR_do_subdomain}.${TF_VAR_do_domain}"
INSTANCE_URI="https://${DOMAIN}/ui/"
CERT_FLAG=""
[[ "${ENVIRONMENT}" == "staging" ]] && CERT_FLAG="--cacert fakelerootx1.pem"

echo "Waiting for ${INSTANCE_URI}"

until $(
  curl \
    --silent \
    --location \
    --fail \
    --output /dev/null \
    --max-time 3 \
    ${CERT_FLAG} \
    --user "admin:${PASSWORD}" \
    "${INSTANCE_URI}"
); do
  echo "."
  sleep 5s
done
