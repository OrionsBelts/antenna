#!/usr/bin/env bash

##
# Description
#
# Script cleans up the artifacts left over by testing a function.
##

# Exit immediately if there is an error
set -e

# Validate Environment Variables
[[ -z "${GITHUB_WORKSPACE}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${TF_VAR_do_token}" ]] && echo "Missing Env Var" && exit 1

# Global Variables

# Import Common Utils
source "${GITHUB_WORKSPACE}/core/scripts/common.sh"

FUNC_NAME=$1
TAG=$2

MANIFEST_DIGEST=$(docker_fetch_digestByTag "${TF_VAR_do_token}" "${FUNC_NAME}" "${TAG}")

docker_delete_digest "${TF_VAR_do_token}" "${FUNC_NAME}" "${MANIFEST_DIGEST}"
