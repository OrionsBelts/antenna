#!/usr/bin/env bash

# Exit immediately if there is an error
set -e

# Check to see that deps are installed
jq --version
yq --version

# Variables
STACK_FILE="../stack.yml"


# Check to see if the stack file is present before doing operations
if [ ! -f "${STACK_FILE}" ]; then
  echo "Error: ${STACK_FILE} not found."
  exit 1
fi

FN_SECRET_LIST=$(cat "${STACK_FILE}" | yq '.functions[].secrets[]?' | jq --slurp -r '.[]')

# Fetch secret names from GitHub
GITHUB_SECRETS=$(echo "${SECRETS}" | jq -r 'keys[]')

ERROR_SECRETS=""

# Check GitHub to make sure secrets exist
for FN_SECRET in ${FN_SECRET_LIST}; do
  KEY_EXISTS="false"

  for SECRET_KEY in ${GITHUB_SECRETS}; do
    if [ ${FN_SECRET} == ${SECRET_KEY} ]; then
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
