#!/bin/bash
set -m

host=${HOST:-127.0.0.1}
port=${PORT:-3310}
# I *think* this is miliseconds. The default is 500.
timeout=${TIMEOUT:-15000}

echo "using clamd server: $host:$port timeout: $timeout"

# start in background
java -jar /var/clamav-rest/clamav-rest-1.0.2.jar --clamd.host=$host --clamd.port=$port --clamd.timeout=$timeout
