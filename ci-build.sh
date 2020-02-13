#!/usr/bin/env bash

set -e

TAG=clamav
COUNT=0
PORT=3310

function tear_down() {
    if [ "${TEAR_DOWN}" == "true" ]; then
        if docker ps -a | grep ${INSTANCE} &>/dev/null ; then
            if docker ps | grep ${INSTANCE} &>/dev/null ; then
                ${SUDO_CMD} docker stop ${INSTANCE}
            fi
            ${SUDO_CMD} docker rm ${INSTANCE}
        fi
    fi
}

function wait_until_started() {
    max_retries=10
    wait_time=${WAIT_TIME:-30}
    retries=0
    cmd="$*"
    if [[ $cmd == WARNING* ]]; then
        cmd=""
    fi
    while ! eval $cmd; do
        echo "waiting for command to succeed ('$cmd')"
        ((retries++))
        if ((retries==max_retries)); then
           echo "Test Failed"
           return 1
        fi
        sleep "$wait_time"
    done
    echo "Test Succeeded"
    return 0
}

# Removes any old containers and images (to avoid container name conflicts)
function clean_up() {
    if docker ps -a --filter "name=clamav" | grep clamav &>/dev/null; then
        echo "Removing old clamav container..."
        docker stop clamav &>/dev/null && docker rm clamav &>/dev/null
    else
        echo "No clamav container found."
    fi

    if docker ps -a --filter "name=go-clamav-rest" | grep go-clamav-rest &>/dev/null; then
        echo "Removing old clamav-rest container..."
        docker stop go-clamav-rest &>/dev/null && docker rm go-clamav-rest &>/dev/null
    else
        echo "No clamav-rest container found."
    fi

    action="$*"
    if [[ "$action" == "delete-images" ]]; then
        if docker images clamav | grep clamav &>/dev/null; then
            echo "Removing clamav image..."
            docker rmi clamav
        else
            echo "No clamav image found."
        fi

        if docker images go-clamav-rest | grep go-clamav-rest &>/dev/null; then
            echo "Removing clamav-rest image..."
            docker rmi go-clamav-rest
        else
            echo "No clamav-rest image found."
        fi
    fi
}

echo "========"
echo "REMOVING OLD CONTAINERS AND IMAGES..."
echo "========"
clean_up

echo "========"
echo "BUILD..."
echo "========"
${SUDO_CMD} docker build -t ${TAG} .

echo "=========="
echo "STARTING CLAMAV CONTAINER..."
echo "=========="
docker run -d --name=clamav -p ${PORT}:3310 ${TAG}

echo "=========="
echo "TESTING FRESHCLAM PROCESS..."
echo "=========="

RUN_FRESHCLAM_TEST='docker exec -t clamav sh -c "freshclam" | grep -q "bytecode.cvd already up-to-date"'
if ! wait_until_started "${RUN_FRESHCLAM_TEST}"; then
    echo "Error, not started in time..."
    docker logs clamav
    exit 1
fi

echo "=========="
echo "TESTING CLAMD PROCESS..."
echo "=========="

RUN_CLAMD_TEST='docker exec -t clamav sh -c "clamdscan /eicar.com" | grep -q "Infected files: 1"'
if ! wait_until_started "${RUN_CLAMD_TEST}"; then
    echo "Error, not started in time..."
    docker logs clamav
    exit 1
fi

#testing clamd-rest container.
echo "=========="
echo "TESTING REST API..."
echo "=========="

docker build -t go-${TAG}-rest go-clamav-rest

#start container.
docker run -id -p 8080:8080 --name=go-clamav-rest --link clamav:clamav go-clamav-rest -host clamav
sleep 30 #wait for app to start

REST_CMD=$(curl -w %{http_code} -s --output /dev/null 172.17.0.1:8080)
VIRUS_TEST=$(curl -s -F "name=test-virus" -F "file=@eicar.com" 172.17.0.1:8080/scan | grep -o false)

if [ $REST_CMD == "200" ]; then
  if [ $VIRUS_TEST == "false" ]; then
    echo "SUCCESS rest api working and detecting viruses correctly"
    clean_up
    exit 0
  fi
  echo "FAILED rest api not detecting correctly"
  exit 1
fi

echo "rest api not starting."
exit 1
