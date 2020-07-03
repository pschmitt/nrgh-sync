#!/usr/bin/env bash

SLEEP_INTERVAL=${SLEEP_INTERVAL:-5m}

while true
do
  nrgh-sync --gh-token "$GH_TOKEN" --nr-token "$NR_TOKEN"

  sleep "$SLEEP_INTERVAL"
done
