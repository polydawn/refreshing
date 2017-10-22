#!/bin/bash
set -euo pipefail

. env.shlib
cd "$FLING_BASE"

rm -rf hitch.db
