#!/bin/sh
# Runs every test; needs bash, php-cli.
cd "$(dirname "$0")" || exit 1
rc=0
for t in *_test.php; do php "$t" || rc=1; done
for t in *_test.sh; do bash "$t" || rc=1; done
exit $rc
