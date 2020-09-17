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
[[ -z "${TF_VAR_do_token}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${REGISTRY_USER}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${DO_REGISTRY_AUTH}" ]] && echo "Missing Env Var" && exit 1

# Global Variables
DOMAIN="${TF_VAR_do_subdomain}.${TF_VAR_do_domain}"
GATEWAY_URI="https://${DOMAIN}/"
STACK_FILE="${GITHUB_WORKSPACE}/stack.yml"

# Import Common Utils
source "${GITHUB_WORKSPACE}/core/scripts/common.sh"

# Repo root
# INFO(mperrotte): in order for the build/deploy command to work
cd "${GITHUB_WORKSPACE}"

# Grant permission to container registry
echo "INFO: authenticate docker"
docker_auth "${DO_REGISTRY_AUTH}"

# Login to instance
echo "INFO: login to openfaas"
openfaas_login "${GITHUB_WORKSPACE}/core/terraform.tfstate" "${GATEWAY_URI}"

# Build functions
echo "INFO: build functions"
openfaas_build "${STACK_FILE}"

# Push function images
echo "INFO: push functions"
openfaas_push "${STACK_FILE}"

# Deploy functions
echo "INFO: deploy functions"
openfaas_deploy "${STACK_FILE}"
