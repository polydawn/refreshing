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
				"exec": ["/bin/bash", "-c", "set -euo pipefail; export GOROOT=/app/go/go; export PATH=$PATH:/app/go/go/bin; mkdir target; go build -o target/hello"]
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
rr="$(repeatr run <(echo "$frm"))"
echo "$rr" | jq .

# Pass on the binary in another hitch release.
#  But first, destroy existing releases.  this is demo content.
rm -rf hitch.db/refreshing.polydawn.net/demo/hello-go || true

hitch catalog create "refreshing.polydawn.net/demo/hello-go"
hitch release start  "refreshing.polydawn.net/demo/hello-go" "vtmp"
hitch release add-item "linux-amd64" "$(echo "$rr" | jq -r '.results["/task/target"]')"
hitch release commit

# Let's make another formula that runs the product, whee!
>&2 echo Templating formula the Second...
frm="$(cat <<EOF
	{
		"formula": {
			"inputs": {
				"/":         "$(hitch show "refreshing.polydawn.net/bases/busybash:v1:linux-amd64")",
				"/task":     "$(hitch show "refreshing.polydawn.net/demo/hello-go:vtmp:linux-amd64")"
			},
			"action": {
				"exec": ["/task/hello"]
			}
		},
		"context": {
			"fetchUrls": {
				"/":       ["ca+file://.warehouse/", "ca+https://repeatr.s3.amazonaws.com/warehouse/"],
				"/task":   ["ca+file://.warehouse/"]
			}
		}
	}
EOF
)"
echo "$frm" | jq .formula

>&2 echo Running formula the Second...
rr="$(repeatr run <(echo "$frm"))"
echo "$rr" | jq .
