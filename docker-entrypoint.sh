#!/bin/bash

set -e

export UPDATE_EVERY_MINUTES=${UPDATE_EVERY_MINUTES:-60}
export UPDATE=${UPDATE:-true}
export UPDATE_ONLY=${UPDATE_ONLY:-false}
export UPDATE_EVERY_SECONDS=$(($UPDATE_EVERY_MINUTES * 60))
export FIRST_UPDATE_MUTEX_FLAG=/var/lib/clamav/1strun

if [ "${UPDATE_ONLY}" == "true" ]; then
	# Only run freshclam...
	while true ; do
		freshclam "@$"
		echo "Waiting for ${UPDATE_EVERY_MINUTES} mins from $(date)..."
		sleep ${UPDATE_EVERY_SECONDS}
		touch ${FIRST_UPDATE_MUTEX_FLAG}
	done
else
	if [ "${UPDATE}" == "true" ]; then
		echo "Run one complete update..."
		freshclam
		echo "Running freshclam as daemon..."

		# TODO: add some monitoring around this...?
		freshclam -d
	else
		echo "Expecting sidecar container to update definitions..."
		MAX_RETRIES=10
		RETRY_WAIT_SECONDS=10
		retries=0
		while true ; do
		if [ ! -f ${FIRST_UPDATE_MUTEX_FLAG} ] ; then
			retries=$(($retries + 1))
			if [ ${retries} -gt ${MAX_RETRIES} ]; then
				echo "No updates within $(($MAX_RETRIES * $RETRY_WAIT_SECONDS)))"
				exit 1
			else
				echo "Retrying, $retries out of $MAX_RETRIES..."
				sleep ${RETRY_WAIT_SECONDS}
			fi
		fi
		done
	fi
	exec clamd "$@"
fi
