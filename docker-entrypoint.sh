#!/bin/bash
# bootstrap clam av service and clam av database updater
set -m

# start in background
freshclam -d &
clamd 
