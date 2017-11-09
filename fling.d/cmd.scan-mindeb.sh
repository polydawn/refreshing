#!/bin/bash
#
# This one's less of a scan, more of just an imperative statement.
#
set -euo pipefail

. env.shlib
cd "$FLING_BASE"

hitch catalog create "refreshing.polydawn.net/bases/mindeb" || \
	{ e=$?; [[ $e -eq 7 || $e -eq 8 ]] || exit $e; } ## it's fine if it exists already :)

hitch release start "refreshing.polydawn.net/bases/mindeb" "v0.1.1.1" && {
	hitch release add-item "linux-amd64" "tar:6fSG9fsZzroqsku1LX3FRwNcfPcCosKk9pWbfCkF7BQkCrRCyu5pWN4nC4hcb3iWPu"
	hitch release commit
} || { e=$?; [[ $e -eq 7 || $e -eq 8 ]] && { >&2 printf "skipping scan - mindeb v0.1.1.1 already released\n"; exit 0; } || exit $e; }
