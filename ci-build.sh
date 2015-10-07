#!/usr/bin/env bash

set -e

TAG=clamav
NAME=$TAG_instance

# Cope with local builds with docker machine...
if [ "${DOCKER_MACHINE_NAME}" == "" ]; then
    DOCKER_HOST_NAME=localhost
    SUDO_CMD=sudo
    # On travis... need to do this for it to work!
    ${SUDO_CMD} service docker restart ; sleep 10
else
    DOCKER_HOST_NAME=$(docker-machine ip ${DOCKER_MACHINE_NAME})
    SUDO_CMD=""
fi

function get() {
    url=$1
    max_retries=10
    retries=0
    while true ; do
        if ! wget -O- $url ; then
            retries=$((retries + 1))
            if [ $retries -eq $max_retries ]; then
                return 1
            else
                echo "Retrying, $retries out of $max_retries..."
                sleep 5
            fi
        else
            return 0
        fi
    done
    echo
    return 1
}

if docker ps -a | grep ${NAME} ; then
    if docker ps | grep ${NAME} ; then
        ${SUDO_CMD}  docker stop ${NAME}
    fi
    ${SUDO_CMD}  docker rm ${NAME}
fi

docker build -t ${TAG} .
# ${SUDO_CMD}  docker run --name ${NAME} -d -p 3200:3200 ${TAG}
# docker logs ${NAME}
