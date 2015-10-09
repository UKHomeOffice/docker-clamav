#!/usr/bin/env bash

function wait_until_cmd() {
    cmd=$@
    max_retries=10
    retries=0
    while true ; do
        if ! bash -c "${cmd}" &> /dev/null ; then
            retries=$((retries + 1))
            echo "Testing for readyness..."
            if [ ${retries} -eq ${max_retries} ]; then
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

function wait_until_listening() {
    ip=$1
    port=$2
    if wait_until_cmd "nc -z ${ip} $port" ; then
        return 0
    else
        return 1
    fi
}

