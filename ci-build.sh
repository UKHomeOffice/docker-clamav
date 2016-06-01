#!/usr/bin/env bash

set -e

TAG=clamav
COUNT=0
PORT=3310
START_INSTANCE="docker run --privileged=true -v ${PWD}/data:/var/lib/clamav"
FILE="${PWD}/data/daily.*"
source ./helper.sh

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
    sleep 1
    sudo docker exec -it ${INSTANCE} /readyness.sh POLL
}

function start_test() {
    tear_down
    COUNT=$((COUNT + 1))
    PORT=$((PORT + 1))
    INSTANCE=${TAG}_$COUNT
    echo "STARTING TEST:$1"
    shift
    echo "Running:$@ --name ${INSTANCE} -p ${PORT}:3310 ${TAG}"
    bash -c "$@ --name ${INSTANCE} -d -p ${PORT}:3310 ${TAG}"
    if ! wait_until_started ; then
        echo "Error, not started in time..."
        ${SUDO_CMD} docker logs ${INSTANCE}
        exit 1
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
    TEAR_DOWN=true
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
start_test "Simple start" "${STD_CMD}"
start=`date +%s`
x=0
while [ "$x" -lt 100 -a ! -e $FILE ]; do
 x=$((x+1))
   echo "daily.cvd not yet downloaded. Sleeping..."
 sleep 20
done
end=`date +%s`

runtime=$((end-start))
echo "It took $runtime seconds to get cve's"
start_test "Start with custom settings" "${STD_CMD} \
           -e \"CLAMD_SETTINGS_CSV=LogClean no,StatsEnabled\" \
           -e \"FRESHCLAM_SETTINGS_CSV=OnUpdateExecute /bin/true wow\""

echo "Test CLAMD_SETTINGS_CSV add setting..."
${SUDO_CMD} docker exec -it ${INSTANCE} \
     grep "^LogClean no" /usr/local/etc/clamd.conf

echo "Test CLAMD_SETTINGS_CSV remove setting..."
if ${SUDO_CMD} docker exec -it ${INSTANCE} grep "^StatsEnabled " /usr/local/etc/clamd.conf ; then
    echo "Failed test for deleting entry..."
    exit 1
fi
echo "Test FRESHCLAM_SETTINGS_CSV add complex setting..."
${SUDO_CMD} docker exec -it ${INSTANCE} \
    grep "^OnUpdateExecute /bin/true wow" /usr/local/etc/freshclam.conf

touch ./data/1strun
start_test "Test UPDATE=false mode" "${STD_CMD} -e \"UPDATE=false\""

rm ./data/1strun
start_test "Test UPDATE_ONLY=true mode" "${STD_CMD} -e \"UPDATE_ONLY=true\""
echo "Started now polling for mutex file..."
if ! wait_until_cmd "${SUDO_CMD} ls ./data/1strun" ; then
    echo "Error, not detecting mutex file???"
    ${SUDO_CMD} docker logs ${INSTANCE}
    exit 1
fi
#testing clamd-rest container.

${SUDO_CMD} docker build -t ${TAG}-rest clamav-rest

#start container.
docker run -itd -p 8080:8080 --name=clamav-rest -e HOST=clamav_1 --link clamav_1:clamav_1 clamav-rest
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
  
  
  
  
