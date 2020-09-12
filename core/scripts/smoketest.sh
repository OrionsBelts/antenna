#!/usr/bin/env bash

##
# Description
#
#
##

# Exit immediately if there is an error
set -e

# Validate Environment Variables
[[ -z "${GITHUB_WORKSPACE}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${TF_VAR_do_subdomain}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${TF_VAR_do_domain}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${FUNCTION_PREFIX}" ]] && echo "Missing Env Var" && exit 1

# Check to see that deps are installed
jq --version
yq --version

# Global Variables
DOMAIN="${TF_VAR_do_subdomain}.${TF_VAR_do_domain}"
GATEWAY_URI="https://${DOMAIN}/"
TEMPLATE="orions-smoketest"
FUNC_NAME="smoketest"
FILENAME="${FUNC_NAME}.yml"
SECRET_KEY="SOME_SECRET"
SECRET_VALUE="super-secret-value"

# Function Declarations
openfaas_login() {
  local PASSWORD=$(cat "${GITHUB_WORKSPACE}/core/terraform.tfstate" | jq -r '.resources[] | select(.name == "password") | .instances[].attributes.result')
  faas-cli \
    login \
    --username admin \
    --password "${PASSWORD}" \
    --gateway "${GATEWAY_URI}" \
    --tls-no-verify
}

openfaas_createFunc() {
  faas-cli \
    new \
    "${FUNC_NAME}" \
    --lang="${TEMPLATE}" \
    --gateway="${GATEWAY_URI}" \
    --prefix="${FUNCTION_PREFIX}"
}

openfaas_updateFuncYaml() {
  # Generate temp yaml
  cat "${FILENAME}" | \
  yq \
    '.functions.secrets = ["SOME_SECRET"] | .configuration.copy = ["./common"]' \
    --yaml-output \
  > "${FILENAME}.tmp"

  # Overwrite yaml
  mv "${FILENAME}.tmp" "${FILENAME}"
}

openfaas_build() {
  faas-cli \
    build \
    --yaml "${FILENAME}" \
    --tag sha
}

openfaas_push() {
  faas-cli \
    push \
    --yaml "${FILENAME}" \
    --tag sha
}

openfaas_deploy() {
  faas-cli \
    deploy \
    --yaml "${FILENAME}" \
    --tag sha
}

openfaas_setSecret() {
  local key=$1
  local value=$2

  faas-cli \
    secret \
    create \
    "${key}" \
    --from-literal="${value}" \
    --gateway="${GATEWAY_URI}" \
    --tls-no-verify
}

openfaas_invokeFunc() {
  local name=$1

  faas-cli \
    invoke \
    "${name}" \
    --gateway "${GATEWAY_URI}" \
    --tls-no-verify
}

# Script Logic

# Install `faas-cli`
curl -sSL https://cli.openfaas.com | sudo sh

# Repo root
cd ".."

# Login to instance
echo "INFO: login to openfaas"
openfaas_login

# Create smoketest function
echo "INFO: create smoketest function"
openfaas_createFunc

# Generate new function context yaml
echo "INFO: update function context yaml"
openfaas_updateFuncYaml

# Build smoketest function
echo "INFO: build smoketest function"
openfaas_build

# Push smoketest function image
echo "INFO: push smoketest function"
openfaas_push

# Set secret used by function
echo "INFO: create secret for function"
openfaas_setSecret "${SECRET_KEY}" "${SECRET_VALUE}"

# Deploy smoketest function
echo "INFO: deploy smoketest function"
openfaas_deploy

echo "INFO: sleep for 5 seconds (allow function to deploy)"
sleep 5s

# Invoke function
echo "INFO: invoke smoketest function"
RESULT=$(openfaas_invokeFunc "${FUNC_NAME}")

# Validate function has access to secret
echo "INFO: validate function result"
ACTUAL_VALUE=$(echo "${RESULT}" | jq '.data')
[[ "${ACTUAL_VALUE}" != "successfully read ${SECRET_VALUE}" ]] && \
echo "Secret Test Failed" && \
exit 1
