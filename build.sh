#!/usr/bin/env bash

docker buildx build \
  --platform=linux/amd64,linux/386,linux/arm/v6,linux/arm64 \
  --tag pschmitt/nrgh-sync:latest \
  --push \
  .
