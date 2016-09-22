#!/usr/bin/env bash

set -e

TAG=clamav
COUNT=0
PORT=3310

STD_CMD="${SUDO_CMD} ${START_INSTANCE}"

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
    max_retries=20
    wait_time=${WAIT_TIME:-5}
    retries=0
    cmd="$@"
    while ! $cmd; do
        echo "waiting for command to succeed"
        (($retries++)) 
        if (($retries==$max_retries)); then
           echo "Test Failed"
           return 1
        fi
        sleep $wait_time
    done
    echo "Test Succeeded"
    return 0
}


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

RUN_FRESHCLAM_TEST=$(docker exec -t clamav bash -c "freshclam | grep -q 'bytecode.cvd is up to date'")
if ! wait_until_started "${RUN_FRESHCLAM_TEST}"; then
    echo "Error, not started in time..."
    docker logs clamav
    exit 1
fi

sleep 10 #wait for clamd process to start
echo "=========="
echo "TESTING CLAMD PROCESS..."
echo "=========="

RUN_CLAMD_TEST=$(docker exec -t clamav bash -c "clamdscan eicar.com | grep -q 'Infected files: 1'")

if ! wait_until_started "${RUN_CLAMD_TEST}"; then
    echo "Error, not started in time..."
    docker logs clamav
    exit 1
fi

#testing clamd-rest container.

docker build -t ${TAG}-rest clamav-rest

#start container.
docker run -id -p 8080:8080 --name=clamav-rest -e HOST=clamav --link clamav:clamav clamav-rest
sleep 20 #wait for app to start
REST_CMD=$( curl -w %{http_code} -s --output /dev/null localhost:8080)
VIRUS_TEST=$(curl -s -F "name=test-virus" -F "file=@eicar.com" localhost:8080/scan | grep -o false)

if [ $REST_CMD == "200" ]; then
  if [ $VIRUS_TEST == "false" ]; then
      echo "SUCCESS rest api working and detecting viruses Correctly"
      exit 0
  else
    echo "FAILED rest api not detecting co correctly"
    exit 1
  fi
else
  echo "rest api not starting."
  exit 1
fi
  
  
  
  
