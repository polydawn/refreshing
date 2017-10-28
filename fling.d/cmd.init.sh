#!/bin/bash
set -euo pipefail

. env.shlib
cd "$FLING_BASE"

hitch init || \
	{ e=$?; [[ $e -eq 7 || $e -eq 8 ]] || exit $e; } ## it's fine if it exists already :)

mkdir -p .warehouse
mkdir -p .rio-cache
