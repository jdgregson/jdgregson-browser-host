#!/bin/bash

CONTAINER_NAME=jdgregson-browser-container

echo "Stopping $CONTAINER_NAME..."
podman rm $CONTAINER_NAME -f
