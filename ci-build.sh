#!/usr/bin/env bash

set -e

TAG=clamav
INSTANCE=${TAG}_instance
START_INSTANCE="docker run -d --name ${INSTANCE} -p 3310:3310 -v ${PWD}/data:/var/lib/clamav"

source ./helper.sh

function wait_until_started() {
    wait_until_listening ${DOCKER_HOST_NAME} 3310
}

function tear_down() {
    if docker ps -a | grep ${INSTANCE} &>/dev/null ; then
        if docker ps | grep ${INSTANCE} &>/dev/null ; then
            ${SUDO_CMD}  docker stop ${INSTANCE}
        fi
        ${SUDO_CMD}  docker rm ${INSTANCE}
    fi
}

function start_test() {
    tear_down
    echo "STARTING TEST:$1"
    shift
    wait=$1
    shift
    echo "Running:$@"
    bash -c "$@"
    if $wait ; then
        if ! wait_until_started ; then
            echo "Error, not started in time..."
            ${SUDO_CMD} docker logs ${INSTANCE}
            exit 1
        fi
    fi
}



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
STD_CMD="${SUDO_CMD} ${START_INSTANCE}"

echo "========"
echo "BUILD..."
echo "========"
${SUDO_CMD} docker build -t ${TAG} .

echo "=========="
echo "TESTING..."
echo "=========="
start_test "Simple start" true "${STD_CMD} ${TAG}"
start_test "Start with custom settings" true "${STD_CMD} \
           -e \"CLAMD_SETTINGS_CSV=LogClean no,StatsEnabled yes\" \
           -e \"FRESHCLAM_SETTINGS_CSV=OnUpdateExecute /bin/true wow\" \
           ${TAG}"

echo "Test CLAMD_SETTINGS_CSV add setting..."
${SUDO_CMD} docker exec -it ${INSTANCE} \
     grep "^LogClean no" /etc/clamd.conf

#echo "Test CLAMD_SETTINGS_CSV remove setting..."
#if ${SUDO_CMD} docker exec -it ${INSTANCE} grep -v "^StatsEnabled" /etc/clamd.conf &> /dev/null ; then
#    echo "Failed test for deleting entry..."
#    exit 1
#fi
echo "Test FRESHCLAM_SETTINGS_CSV add complex setting..."
${SUDO_CMD} docker exec -it ${INSTANCE} \
    grep "^OnUpdateExecute /bin/true wow" /etc/freshclam.conf

touch ./data/1strun
start_test "Test UPDATE=false mode" true "${STD_CMD} -e \"UPDATE=false\" ${TAG}"

rm ./data/1strun
start_test "Test UPDATE_ONLY=true mode" false "${STD_CMD} -e \"UPDATE_ONLY=true\" ${TAG}"
echo "Started now polling for mutex file..."
if ! wait_until_cmd "ls ./data/1strun" ; then
    echo "Error, not detecting mutex file???"
    ${SUDO_CMD} docker logs ${INSTANCE}
    exit 1
fi
