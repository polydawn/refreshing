#!/bin/bash
#
# This one's less of a scan, more of just an imperative statement.
#
set -euo pipefail

. env.shlib
cd "$FLING_BASE"

hitch catalog create "refreshing.polydawn.net/bases/busybash" || \
	{ e=$?; [[ $e -eq 7 || $e -eq 8 ]] || exit $e; } ## it's fine if it exists already :)

hitch release start "refreshing.polydawn.net/bases/busybash" "v1" && {
	hitch release add-item "linux-amd64" "tar:6q7G4hWr283FpTa5Lf8heVqw9t97b5VoMU6AGszuBYAz9EzQdeHVFAou7c4W9vFcQ6"
	hitch release commit
} || { e=$?; [[ $e -eq 7 || $e -eq 8 ]] && { >&2 printf "skipping scan - busybash v1 already released\n"; exit 0; } || exit $e; }
