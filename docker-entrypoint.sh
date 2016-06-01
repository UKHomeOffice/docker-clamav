#!/bin/bash

set -e

UPDATE=${UPDATE:-true}
UPDATE_ONLY=${UPDATE_ONLY:-false}
FIRST_UPDATE_MUTEX_FLAG=/var/lib/clamav/1strun
CLAMD_CONF=/usr/local/etc/clamd.conf
FRESHCLAM_CONF=/usr/local/etc/freshclam.conf
LOG_PREFIX=${LOG_PREFIX:-DOCKER-CLAMAV}

function log_out() {
    echo "${LOG_PREFIX}:$@"
}

function update_setting() {
    file=$1
    name=$2
    value=$3

    log_out "Updating '${file}' with setting:'${name}', value:'${value}'"

    if ! grep "^#*$name " $file >/dev/null ; then
        log_out "Error - invalid setting:${name} for file:${file}"
        exit 1
    fi

    if [ "$value" == "" ]; then
    	log_out "Deleting setting in ${file} with:${name}..."
        sed -i "/^#*${name} .*/d" ${file}
    else
    	log_out "Updating setting in ${file} with:${name} ${value}..."
        sed -i "s|^#*${name} .*$|${name} ${value}|g" ${file}
    fi
}

function update_all_settings() {
	file=$1
	settings_csv=$2

	IFS=',' read -a setting_array <<< "${settings_csv}"
	for i in "${!setting_array[@]}"; do
	    item="${setting_array[$i]}"
		setting="$(echo "${item}" | cut -d' ' -f 1)"
		value="${item#* }"
		if [ "${setting}" == "${value}" ]; then
		    setting=""
		fi
		update_setting ${file} ${setting} "${value}"
	done
}

function update_freshclam() {
    if [ "${FRESHCLAM_SETTINGS_CSV}" != "" ]; then
    	update_all_settings ${FRESHCLAM_CONF} "${FRESHCLAM_SETTINGS_CSV}"
    fi
}

function update_clamd() {
    if [ "${CLAMD_SETTINGS_CSV}" != "" ]; then
    	update_all_settings ${CLAMD_CONF} "${CLAMD_SETTINGS_CSV}"
    fi
}

if [ "${UPDATE_ONLY}" == "true" ]; then
    touch /UPDATE_ONLY
    # Only run freshclam...
    update_freshclam
    log_out "Run one complete update..."
    freshclam "@$"
    log_out "Signalling update complete with file mutex:${FIRST_UPDATE_MUTEX_FLAG}..."
    touch ${FIRST_UPDATE_MUTEX_FLAG}
    log_out "Running freshclam daemon (foreground process)..."
    exec freshclam -d "@$"
else
    update_clamd
    if [ "${UPDATE}" == "true" ]; then
        touch /UPDATE
        update_freshclam

        log_out "Run one complete update..."
        freshclam
        log_out "Running freshclam as daemon (foreground logging)..."
		# TODO: add some monitoring around this...?
        freshclam -d &
    else
        log_out "Waiting for ${FIRST_UPDATE_MUTEX_FLAG}..."
        MAX_RETRIES=10
        RETRY_WAIT_SECONDS=10
        RETIRES=0
        while true ; do
            if [ -f ${FIRST_UPDATE_MUTEX_FLAG} ] ; then
                log_out "Update complete signal found:${FIRST_UPDATE_MUTEX_FLAG}"
                break;
            else
                RETIRES=$(($RETIRES + 1))
                if [ ${RETIRES} -gt ${MAX_RETRIES} ]; then
                    log_out "No updates within $(($MAX_RETRIES * $RETRY_WAIT_SECONDS)))"
                    exit 1
                else
                    log_out "Retrying, $RETIRES out of $MAX_RETRIES..."
                    sleep ${RETRY_WAIT_SECONDS}
                fi
            fi
        done
    fi
    log_out "Starting clamd process..."
    exec clamd "$@"
fi
