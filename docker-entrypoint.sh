#!/bin/sh
# bootstrap clam av service and clam av database updater
set -m

function process_file() {
    if [[ ! -z "$1" ]]; then
        local SETTING_LIST=$(echo "$1" | tr ',' '\n' | grep "^[A-Za-z][A-Za-z]*=.*$")
        local SETTING
        
        for SETTING in ${SETTING_LIST}; do
            # Remove any existing copies of this setting.  We do this here so that
            # settings with multiple values (e.g. ExtraDatabase) can still be added
            # multiple times below
            local KEY=${SETTING%%=*}
            sed -i $2 -e "/^${KEY} /d"
        done

        for SETTING in ${SETTING_LIST}; do
            # Split on first '='
            local KEY=${SETTING%%=*}
            local VALUE=${SETTING#*=}
            echo "${KEY} ${VALUE}" >> "$2"
        done
    fi
}

process_file "${CLAMD_SETTINGS_CSV}" /etc/clamav/clamd.conf
process_file "${FRESHCLAM_SETTINGS_CSV}" /etc/clamav/freshclam.conf

# start in background
freshclam -d &
clamd
