#!/usr/bin/env bash

##
# Description
#
# Downloads a defined public ssh key from digitalocean. File is put in the
# directory this script is run from.
##

# Exit immediately if there is an error
set -e

# Validate Environment Variables
[[ -z "${DO_API_TOKEN}" ]] && echo "Missing Env Var" && exit 1
[[ -z "${SSH_KEY_NAME}" ]] && echo "Missing Env Var" && exit 1

FILENAME="${SSH_KEY_NAME}.pub"

# Fetching Public SSH key
curl \
  -s \
  -X GET \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${DO_API_TOKEN}" \
  "https://api.digitalocean.com/v2/account/keys" | \
jq \
  -r \
  --arg KEY_NAME "${SSH_KEY_NAME}" \
  '.ssh_keys[] | select(.name == "$KEY_NAME") | .public_key' > "${FILENAME}"
