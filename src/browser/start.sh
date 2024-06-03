#!/bin/bash

podman run \
  -d \
  --rm \
  --name jgregson-browser \
  --n-shm-size=4g \
  -e VNC_PW=password \
  -p 127.0.0.1:6901:6901 \
  docker.io/kasmweb/chrome:1.14.0-rolling
