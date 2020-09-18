#!/usr/bin/env bash

##
# Description
#
# Downloads the PEM key for letsencrypt's staging endpoint. File is saved to
# the directory the script is run from.
##

# Exit immediately if there is an error
set -e

# Fetching Public SSH key
curl \
  -s \
  -X GET \
  "https://letsencrypt.org/certs/fakelerootx1.pem" > fakelerootx1.pem
