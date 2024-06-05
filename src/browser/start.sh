#!/bin/bash

podman rm jdgregson-browser -f
podman run \
  -d \
  --rm \
  --name jdgregson-browser \
  --shm-size=4g \
  -p 127.0.0.1:6901:6901 \
  -e VNC_PW=password \
  -e APP_ARGS="--no-default-browser-check --no-first-run --start-maximized --force-dark-mode" \
  -e LAUNCH_URL="about:blank" \
  -v /opt/jdgregson-browser-host/src/browser/policies:/etc/opt/chrome/policies/managed \
  docker.io/kasmweb/chrome:1.15.0-rolling
