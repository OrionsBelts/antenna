#!/usr/bin/env bash

##
# Description
#
# Script which reads all secrets needed for functions, pulls their values from
# GitHub secrets and then creates them in the openfaas instance.
##

# Exit immediately if there is an error
set -e

# Check to see that deps are installed
jq --version
yq --version

# Validate Environment Variables
[[ -z "${GITHUB_WORKSPACE}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${TF_VAR_do_subdomain}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${TF_VAR_do_domain}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${SECRETS}" ]] && echo "Missing Env Var" && exit 1

# Global Variables
STACK_FILE="${GITHUB_WORKSPACE}/stack.yml"
DOMAIN="${TF_VAR_do_subdomain}.${TF_VAR_do_domain}"
GATEWAY_URI="https://${DOMAIN}/"

# Check to see if the stack file is present before doing operations
if [ ! -f "${STACK_FILE}" ]; then
  echo "Error: ${STACK_FILE} not found."
  exit 1
fi

# Import Common Utils
source "${GITHUB_WORKSPACE}/core/scripts/common.sh"

# Login to instance
echo "INFO: login to openfaas"
openfaas_login "${GITHUB_WORKSPACE}/core/terraform.tfstate" "${GATEWAY_URI}"

# Collect **NEEDED** secret keys
FN_SECRET_LIST=$(local_fetchSecrets "${STACK_FILE}")

# Create secrets in open-faas instance
for SECRET_KEY in ${FN_SECRET_LIST}; do
  SECRET_KEY_FORMATTED=$(fmt_openfassToGithub "${SECRET_KEY}")

  SECRET_VALUE=$(echo "${SECRETS}" | jq -r --arg KEY "${SECRET_KEY_FORMATTED}" '.[$KEY]')
  echo "Adding secret: ${SECRET_KEY}.."
  openfaas_setSecret "${SECRET_KEY}" "${SECRET_VALUE}" "${GATEWAY_URI}"
done
