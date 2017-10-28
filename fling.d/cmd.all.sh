#!/bin/bash
set -euo pipefail
set -x

./cmd.init.sh
./cmd.scan-busybash.sh
./cmd.scan-go.sh
./cmd.pack-demo-hello-go.sh
./cmd.demo-go.sh
