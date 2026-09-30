#!/bin/sh
set -e

if [ -S /var/run/docker.sock ]; then
    DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
    DOCKER_GROUP=$(getent group "$DOCKER_GID" | cut -d: -f1)
    if [ -z "$DOCKER_GROUP" ]; then
        DOCKER_GROUP=docker-host
        groupadd -g "$DOCKER_GID" "$DOCKER_GROUP"
    fi
    usermod -aG "$DOCKER_GROUP" jenkins
fi

exec su jenkins -c "/usr/local/bin/jenkins.sh"
