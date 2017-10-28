#!/bin/bash
#
# Slurp some local files into a ware to use as sources in a demo.
#
set -euo pipefail

. env.shlib
cd "$FLING_BASE"

# destroy existing releases.  this is demo content.
rm -rf hitch.db/refreshing.polydawn.net/demo/hello-go-src || true

hitch catalog create "refreshing.polydawn.net/demo/hello-go-src"
hitch release start  "refreshing.polydawn.net/demo/hello-go-src" "vtmp"
hitch release add-item "src" "$(rio pack tar demo-src/hello-go --target=ca+file://.warehouse/)"
hitch release commit
