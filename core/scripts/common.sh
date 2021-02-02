#!/usr/bin/env bash

##
# Description
#
# Common function declarations to be used by the rest of the scripts in this
# folder. This file doesn't validate environment variables, so make sure to
# `source` this file **AFTER** the environment variable check in a script.
##

DO_API_URL="https://api.digitalocean.com/v2"

# Function Declarations
docker_auth() {
  local token=$1

  mkdir -p "${HOME}/.docker/"

  local AUTH='{"auths":{"registry.digitalocean.com":{"auth":"'"${token}"'"}}}'
  echo "${AUTH}" > "${HOME}/.docker/config.json"
}

docker_fetch_tags() {
  local token=$1
  local repository_name=$2

  curl -s \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${token}" \
    "${DO_API_URL}/registry/depot/repositories/${repository_name}/tags"
}

docker_fetch_tag() {
  local token=$1
  local repository_name=$2
  local tag=$3

  local TAGS=$(docker_fetch_tags "${token}" "${repository_name}")

  echo "${TAGS}" | jq -r \
    --arg TAGNAME "${tag}" \
    '.tags[]? | select(.tag == $TAGNAME)'
}

docker_fetch_digestByTag() {
  local token=$1
  local repository_name=$2
  local tag=$3

  local TAG_DATA=$(docker_fetch_tag "${token}" "${repository_name}" "${tag}")

  echo "${TAG_DATA}" | jq -r '.manifest_digest'
}

docker_delete_digest() {
  local token=$1
  local repository_name=$2
  local digest=$3

  # Bail if {digest} is empty
  [[ -z "${digest}" ]] && return 0

  curl -s \
    -X DELETE \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${token}" \
    "${DO_API_URL}/registry/depot/repositories/${repository_name}/digests/${digest}"
}

openfaas_login() {
  local statefile=$1
  local gateway=$2

  local password=$(cat "${statefile}" | jq -r '.resources[] | select(.name == "password") | .instances[].attributes.result')
  local tls_flag=""
  [[ "${ENVIRONMENT}" == "staging" ]] && tls_flag="--tls-no-verify"

  faas-cli \
    login \
    --username admin \
    --password "${password}" \
    --gateway "${gateway}" \
    ${tls_flag}
}

openfaas_createFunc() {
  local function_name=$1
  local template_name=$2
  local gateway_uri=$3
  local function_prefix=$4

  faas-cli \
    new \
    "${function_name}" \
    --lang="${template_name}" \
    --gateway="${gateway_uri}" \
    --prefix="${function_prefix}"
}

openfaas_build() {
  local filename=$1
  local tag_flag="--tag latest"
  [[ "${ENVIRONMENT}" == "staging" ]] && tag_flag="--tag sha"

  faas-cli \
    build \
    --yaml "${filename}" \
    ${tag_flag}
}

openfaas_push() {
  local filename=$1
  local tag_flag="--tag latest"
  [[ "${ENVIRONMENT}" == "staging" ]] && tag_flag="--tag sha"

  faas-cli \
    push \
    --yaml "${filename}" \
    ${tag_flag}
}

openfaas_deploy() {
  local filename=$1
  local tls_flag=""
  [[ "${ENVIRONMENT}" == "staging" ]] && tls_flag="--tls-no-verify"
  local tag_flag="--tag latest"
  [[ "${ENVIRONMENT}" == "staging" ]] && tag_flag="--tag sha"

  faas-cli \
    deploy \
    --yaml "${filename}" \
    ${tag_flag} \
    ${tls_flag}
}

openfaas_setSecret() {
  local key=$1
  local value=$2
  local gateway=$3
  local tls_flag=""
  [[ "${ENVIRONMENT}" == "staging" ]] && tls_flag="--tls-no-verify"

  faas-cli \
    secret \
    create \
    "${key}" \
    --from-literal="${value}" \
    --gateway="${gateway}" \
    ${tls_flag}
}

openfaas_invokeFunc() {
  local name=$1
  local gateway=$2
  local tls_flag=""
  [[ "${ENVIRONMENT}" == "staging" ]] && tls_flag="--tls-no-verify"

  faas-cli \
    invoke \
    "${name}" \
    --gateway "${gateway}" \
    ${tls_flag}
}

local_fetchSecrets() {
  local stackfile=$1
  local result=$(cat "${stackfile}" | yq -r '.functions[].secrets[]?')
  echo "${result}"
}

local_fetchFunctions() {
  local stackfile=$1
  local result=$(cat "${stackfile}" | yq -r '.functions | keys[]')
  echo "${result}"
}

fmt_githubToOpenfaas() {
  local key=$1
  local fmt=$(echo "${key}" | tr '[:upper:]' '[:lower:]' | sed s/_/-/g)
  echo "${fmt}"
}

fmt_openfassToGithub() {
  local key=$1
  local fmt=$(echo "${key}" | tr '[:lower:]' '[:upper:]' | sed s/-/_/g)
  echo "${fmt}"
}

# Testing Helpers
openfaas_updateFuncYaml() {
  local filename=$1
  local secret_key=$2

  # Generate temp yaml
  cat "${filename}" | \
  yq \
    --arg KEY "${secret_key}" \
    '.functions.smoketest.secrets = [$KEY] | .configuration.copy = ["./common"] | .version = "1.0"' \
    --yaml-output \
  > "${filename}.tmp"

  # Overwrite yaml
  mv "${filename}.tmp" "${filename}"
}

assert_equal() {
  local actual=$1
  local expected=$2

  test "${actual}" == "${expected}" || \
  (echo "FAILED - expected: \"${expected}\", actual: \"${actual}\""; exit 1)
}
