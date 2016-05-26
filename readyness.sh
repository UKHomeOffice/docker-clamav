#!/usr/bin/env bash

set -e

CLAMD_TEST="echo '.' |nc localhost 3310"
FRESHCLAM_TEST="ps ax | grep -v 'grep' |  grep 'freshclam -d'"

source ./helper.sh

function run_test() {
    if [ "${2}" == "POLL" ]; then
        wait_until_cmd "${1}"
    else
        ${1}
    fi
}

if [ -f /UPDATE_ONLY ]; then
    # Only check for freshclam...
      run_test eval "${FRESHCLAM_TEST}" $1
else
    # Test for clamd
    run_test ${CLAMD_TEST} $1

    if [ -f /UPDATE ]; then
        run_test eval "${FRESHCLAM_TEST}" $1
    fi
fi
