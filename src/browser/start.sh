#!/bin/bash

podman rm jdgregson-browser -f
podman run \
  -d \
  --rm \
  --name jdgregson-browser \
  --shm-size=4g \
  -e VNC_PW=password \
  -p 127.0.0.1:6901:6901 \
  -v /opt/jdgregson-browser-host/src/browser/policies:/etc/opt/chrome/policies/managed \
  -e APP_ARGS="--no-default-browser-check --no-first-run" \
  docker.io/kasmweb/chrome:1.14.0-rolling
