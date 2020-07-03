#!/usr/bin/env bash

if [[ -z "$GH_TOKEN" ]]
then
  echo "Missing GitHub token (GH_TOKEN)" >&2
  exit 2
fi

if [[ -z "$NR_TOKEN" ]]
then
  echo "Missing newreleases.io token (NR_TOKEN)" >&2
  exit 2
fi

exec nrgh-sync --gh-token "$GH_TOKEN" --nr-token "$NR_TOKEN"
