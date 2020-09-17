#!/usr/bin/env bash

##
# Description
#
# Moves to the `/core` folder and downloads the PEM key for letsencrypt's
# staging endpoint.
##

# Exit immediately if there is an error
set -e

# Fetching Public SSH key
curl \
  -s \
  -X GET \
  "https://letsencrypt.org/certs/fakelerootx1.pem" > fakelerootx1.pem
