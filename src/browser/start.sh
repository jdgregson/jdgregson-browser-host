#!/bin/bash

CONTAINER_NAME=jdgregson-browser-container
VNC_PASSWORD=password
APP=edge

if [[ "0" == "$(id -u)" ]]; then
  echo "Refusing to run podman container as root, exiting..."
  exit 1
fi

podman image prune -f

/opt/jdgregson-browser-host/src/browser/stop.sh

echo "Starting $CONTAINER_NAME..."
podman run \
  -d \
  --rm \
  --name $CONTAINER_NAME \
  --shm-size=4g \
  -p 127.0.0.1:6901:6901 \
  -e VNC_PW=$VNC_PASSWORD \
  -e APP_ARGS="--no-default-browser-check --no-first-run --start-maximized --load-extension=/home/kasm-user/extensions/extension" \
  -v /opt/jdgregson-browser-host/src/browser/extensions:/home/kasm-user/extensions \
  -v /opt/jdgregson-browser-host/src/browser/policies:/etc/opt/edge/policies/managed \
  -v /opt/jdgregson-browser-host/src/browser/Default:/home/kasm-default-profile/.config/microsoft-edge/Default \
  docker.io/kasmweb/$APP:1.15.0-rolling
