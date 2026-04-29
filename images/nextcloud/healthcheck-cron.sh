#!/usr/bin/env bash
set -eu -o pipefail

if [ ! -f /tmp/cron-success ]; then
    exit 1
fi

now=$(date +%s)
last=$(date +%s -r /tmp/cron-success)

# more than 5 minutes not success
if [ "$((now - last))" -gt $((5 * 60)) ]; then
    exit 1
fi

exit 0
