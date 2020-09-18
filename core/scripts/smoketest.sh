#!/usr/bin/env bash

##
# Description
#
# This script will log into the docker registry in digitalocean as well as
# auth with the openfaas instance that's deployed. It will instanciate a
# smoketest function (build, push, and deploy) designed to pull a secret from
# the environment and return a value. That secret will be created and the
# function will invoked, and the response is validated. If all things exit
# successfully, this script will pass.
##

# Exit immediately if there is an error
set -e

# Validate Environment Variables
[[ -z "${GITHUB_WORKSPACE}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${TF_VAR_do_subdomain}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${TF_VAR_do_domain}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${TF_VAR_do_token}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${FUNCTION_PREFIX}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${DO_REGISTRY_AUTH}" ]] && echo "Missing Env Var" && exit 1

# Check to see that deps are installed
jq --version
yq --version

# Global Variables
DOMAIN="${TF_VAR_do_subdomain}.${TF_VAR_do_domain}"
GATEWAY_URI="https://${DOMAIN}/"
TEMPLATE="orions-smoketest"
FUNC_NAME="smoketest"
FILENAME="${FUNC_NAME}.yml"
SECRET_KEY="some-secret"
SECRET_VALUE="super-secret-value"

# Import Common Utils
source "${GITHUB_WORKSPACE}/core/scripts/common.sh"

# Grant permission to container registry
echo "INFO: authenticate docker"
docker_auth "${TF_VAR_do_token}"

# Repo root
# INFO(mperrotte): in order for the build/deploy command to work
cd "${GITHUB_WORKSPACE}"

# Login to instance
echo "INFO: login to openfaas"
openfaas_login "${GITHUB_WORKSPACE}/core/terraform.tfstate" "${GATEWAY_URI}"

# Create smoketest function
echo "INFO: create smoketest function"
openfaas_createFunc "${FUNC_NAME}" "${TEMPLATE}" "${GATEWAY_URI}" "${FUNCTION_PREFIX}"

# Generate new function context yaml
echo "INFO: update function context yaml"
openfaas_updateFuncYaml "${FILENAME}" "${SECRET_KEY}"

# Build smoketest function
echo "INFO: build smoketest function"
openfaas_build "${FILENAME}"

# Push smoketest function image
echo "INFO: push smoketest function"
openfaas_push "${FILENAME}"

# Set secret used by function
echo "INFO: create secret for function"
openfaas_setSecret "${SECRET_KEY}" "${SECRET_VALUE}" "${GATEWAY_URI}"

# Deploy smoketest function
echo "INFO: deploy smoketest function"
openfaas_deploy "${FILENAME}"

echo "INFO: sleep for 5 seconds (allow function to deploy)"
sleep 5s

# Invoke function
echo "INFO: invoke smoketest function"
RESULT=$(openfaas_invokeFunc "${FUNC_NAME}" "${GATEWAY_URI}")

# Validate function has access to secret
echo "INFO: validate function result"
ACTUAL_VALUE=$(echo "${RESULT}" | jq -r '.data')
EXPECTED_VALUE="successfully read ${SECRET_VALUE}"

assert_equal "${ACTUAL_VALUE}" "${EXPECTED_VALUE}"
