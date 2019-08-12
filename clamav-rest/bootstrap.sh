#!/bin/sh
set -m

host=${HOST:-127.0.0.1}
port=${PORT:-3310}
filesize=${MAXSIZE:-10240MB}
timeout=${TIMEOUT:-15000}

echo "using clamd server: $host:$port, timeout: $timeout, max file size: $filesize"

# start in background
java -jar /var/clamav-rest/clamav-rest-1.0.2.jar --clamd.host=$host --clamd.port=$port --clamd.maxfilesize=$filesize --clamd.maxrequestsize=$filesize
