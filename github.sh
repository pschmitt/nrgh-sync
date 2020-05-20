#!/bin/bash

# https://gist.github.com/mbohun/b161521b2440b9f08b59

usage() {
  local self
  self="$(basename "$0")"

  echo "Usage: ${self} GITHUB_TOKEN REST_EXPRESSION"
  echo "Examples:"
  echo "$self XXX /user"
  echo "$self XXX /users/pschmitt/starred"
}

gh_curl() {
  curl -fsSL \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    "$@"
}

get_page_count() {
  local url="$1"

  gh_curl -I "$url" | \
    grep '^Link:' | \
    sed -e 's/^Link:.*page=//g' -e 's/>.*$//g'
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  set -e

  if [[ $# -lt 2 ]]
  then
    usage
    exit 2
  fi

  GITHUB_TOKEN="$1"
  REST_EXPRESSION="${2#/}"  # remove leading '/'

  URL="https://api.github.com/${REST_EXPRESSION}"

  PAGES="$(get_page_count "$URL")"

  # does this result use pagination?
  if [[ -z "$PAGES" ]]
  then
    # Single page result
    gh_curl "$URL"
  else
    echo "There are $PAGES pages of results" >&2
    # Pagination
    res='[]'  # empty JSON array
    for page in $(seq 1 "$PAGES")
    do
      res_page="$(gh_curl "${URL}?page=$page")"
      res="$(jq -s '.[0] + .[1]' <<< "${res} ${res_page}")"
    done
    echo "$res"
  fi
fi

# vim set ft=bash et ts=2 sw=2 :
