#!/bin/bash
set -euo pipefail

. env.shlib
cd "$FLING_BASE"

>&2 echo Templating formula the First...
frm="$(cat <<EOF
	{
		"formula": {
			"inputs": {
				"/":         "$(hitch show "refreshing.polydawn.net/bases/busybash:v1:linux-amd64")",
				"/app/go":   "$(hitch show "refreshing.polydawn.net/ports/go:v1.9:linux-amd64")",
				"/task":     "$(hitch show "refreshing.polydawn.net/demo/hello-go-src:vtmp:src")"
			},
			"action": {
				"exec": ["/bin/bash", "-c", "set -euo pipefail; export GOROOT=/app/go/go; export PATH=$PATH:/app/go/go/bin; "]
			},
			"outputs": {
				"/task/target": {"packtype": "tar"}
			}
		},
		"context": {
			"fetchUrls": {
				"/":       ["ca+file://.warehouse/", "ca+https://repeatr.s3.amazonaws.com/warehouse/"],
				"/task":   ["ca+file://.warehouse/"],
				"/app/go": ["https://storage.googleapis.com/golang/go1.9.linux-amd64.tar.gz"]
			},
			"saveUrls": {"/task/target": "ca+file://.warehouse/"}
		}
	}
EOF
)"
echo "$frm" | jq .formula

>&2 echo Running formula the First...
rr1="$(repeatr run <(echo "$frm"))"
echo "$rr1" | jq .
