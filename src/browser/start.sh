#!/bin/bash

CONTAINER_NAME=jdgregson-browser-container
VNC_PASSWORD=password

podman image prune -f
podman rm $CONTAINER_NAME -f
podman run \
  -d \
  --rm \
  --name $CONTAINER_NAME \
  --shm-size=4g \
  -p 127.0.0.1:6901:6901 \
  -e VNC_PW=$VNC_PASSWORD \
  -e APP_ARGS="--no-default-browser-check --no-first-run --start-maximized" \
  -e LAUNCH_URL="about:blank" \
  -v /opt/jdgregson-browser-host/src/browser/policies:/etc/opt/chrome/policies/managed \
  -v /opt/jdgregson-browser-host/src/browser/Default:/home/kasm-default-profile/.config/google-chrome/Default \
  docker.io/kasmweb/chrome:1.15.0-rolling
