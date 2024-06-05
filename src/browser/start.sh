#!/bin/bash

podman rm jdgregson-browser -f
podman run \
  -d \
  --rm \
  --name jdgregson-browser \
  --shm-size=4g \
  -e VNC_PW=password \
  -p 127.0.0.1:6901:6901 \
  -v /opt/jdgregson-browser-host/browser/policies:/etc/opt/chrome/policies/managed \
  docker.io/kasmweb/chrome:1.14.0-rolling
