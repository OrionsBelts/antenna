#!/usr/bin/env bash

##
# Description
#
# Validates that the secrets that are listed in `stack.yml` have corresponding
# GitHub Secrets of the same name (though formatted differently). Secrets in
# the `stack.yml` file must be lowercase and dash separators (kebab case). The
# key names in GitHub Secrets need to be capitalized snake case.
##

# Exit immediately if there is an error
set -e

# Validate Environment Variables
[[ -z "${GITHUB_WORKSPACE}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${SECRETS}" ]] && echo "Missing Env Var" && exit 1

# Check to see that deps are installed
jq --version
yq --version

# Variables
STACK_FILE="${GITHUB_WORKSPACE}/stack.yml"

# Check to see if the stack file is present before doing operations
if [ ! -f "${STACK_FILE}" ]; then
  echo "Error: ${STACK_FILE} not found."
  exit 1
fi

# Import Common Utils
source "${GITHUB_WORKSPACE}/core/scripts/common.sh"

FN_SECRET_LIST=$(local_fetchSecrets "${STACK_FILE}")

# Fetch secret names from GitHub
GITHUB_SECRETS=$(echo "${SECRETS}" | jq -r 'keys[]')

ERROR_SECRETS=""

# Check GitHub to make sure secrets exist
for FN_SECRET in ${FN_SECRET_LIST}; do
  KEY_EXISTS="false"

  for GH_SECRET_KEY in ${GITHUB_SECRETS}; do
    # INFO(mperrotte): convert GH key format to openfaas secret key format
    GH_SECRET_KEY_FORMATTED=$(fmt_githubToOpenfaas "${GH_SECRET_KEY}")

    if [ ${FN_SECRET} == ${GH_SECRET_KEY_FORMATTED} ]; then
      # INFO(mperrotte): secret exists
      KEY_EXISTS="true"
      break
    fi
  done

  if [ "${KEY_EXISTS}" == "false" ]; then
    if [ "${ERROR_SECRETS}" == "" ]; then
      ERROR_SECRETS="${FN_SECRET}"
    else
      ERROR_SECRETS="${ERROR_SECRETS} ${FN_SECRET}"
    fi
  fi
done

# NOTE(mperrotte): if there are errors, report and exit
if [ "${ERROR_SECRETS}" != "" ]; then
  echo "ERROR: GitHub secrets are missing"

  for KEY in ${ERROR_SECRETS}; do
    echo "- ${KEY}"
  done

  exit 1
fi
