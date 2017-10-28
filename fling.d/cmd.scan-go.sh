#!/bin/bash
set -euo pipefail

. env.shlib
cd "$FLING_BASE"

hitch catalog create "refreshing.polydawn.net/ports/go" || \
	{ e=$?; [[ $e -eq 7 || $e -eq 8 ]] || exit $e; } ## it's fine if it exists already :)

hitch release start "refreshing.polydawn.net/ports/go" "v1.8" && {
	hitch release add-item "linux-amd64" "$(rio scan tar --source=https://storage.googleapis.com/golang/go1.8.linux-amd64.tar.gz)"
	hitch release add-item "dawrin-amd64" "$(rio scan tar --source=https://storage.googleapis.com/golang/go1.8.darwin-amd64.tar.gz)"
	hitch release commit
} || { e=$?; [[ $e -eq 7 || $e -eq 8 ]] && { >&2 printf "skipping scan - go v1.8; already released\n"; } || exit $e; }

hitch release start "refreshing.polydawn.net/ports/go" "v1.9" && {
	hitch release add-item "linux-amd64" "$(rio scan tar --source=https://storage.googleapis.com/golang/go1.9.linux-amd64.tar.gz)"
	hitch release add-item "dawrin-amd64" "$(rio scan tar --source=https://storage.googleapis.com/golang/go1.9.darwin-amd64.tar.gz)"
	hitch release commit
} || { e=$?; [[ $e -eq 7 || $e -eq 8 ]] && { >&2 printf "skipping scan - go v1.9; already released\n"; } || exit $e; }
