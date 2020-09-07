#!/usr/bin/env bash

##
# Description
#
# Moves to the `/core` folder and downloads the PEM key for letsencrypt's
# staging endpoint.
##

# Exit immediately if there is an error
set -e

# Validate Environment Variables
[[ -z "${GITHUB_WORKSPACE}" ]] && echo "Missing Env Var" && exit 1

cd ${GITHUB_WORKSPACE}/core

# Fetching Public SSH key
curl \
  -s \
  -X GET \
  "https://letsencrypt.org/certs/fakelerootx1.pem" > fakelerootx1.pem