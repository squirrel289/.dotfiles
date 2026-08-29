#!/bin/sh
# Run every isolated shell and installer regression test.
set -eu
repo=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
cd "$repo"
sh test/shell-integrations.sh
sh test/startup-regression.sh
sh test/init.sh
printf '%s\n' 'test suite: ok'
