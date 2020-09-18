#!/usr/bin/env bash

##
# Description
#
# This script will push or pull a terraform statefile from a digitalocean
# space (bucket). Given the parameter "push" or "pull" as an argument to this
# script it will act accordingly.
##

# Exit immediately if there is an error
set -e

# Check to see that deps are installed
aws --version

# Validate Environment Variables
[[ -z "${AWS_ACCESS_KEY_ID}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${AWS_SECRET_ACCESS_KEY}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${AWS_DEFAULT_REGION}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${DO_SPACES_REGION}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${DO_SPACES_URI}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${LOCATION}" ]] && echo "Missing Env Var" && exit 1

# Global Variables
ENDPOINT_FLAG="--endpoint-url=https://${DO_SPACES_REGION}.digitaloceanspaces.com"
STATE_FILE="terraform.tfstate"
BASE_URI="s3://orionsbelt/tfstate/${LOCATION}"

# Script Parameters
ACTION="$1"

# Validate Script Params
[[ -z "${ACTION}" ]] && echo "Missing Script Param" && exit 1

case ${ACTION} in
  "push")
    # Push the terraform state
    aws "${ENDPOINT_FLAG}" s3 cp \
      "${STATE_FILE}" \
      "${BASE_URI}/${STATE_FILE}"
    ;;
  "pull")
    # Fetch terraform state
    aws "${ENDPOINT_FLAG}" s3 cp \
      "${BASE_URI}" \
      ./ \
      --recursive
    ;;
esac
