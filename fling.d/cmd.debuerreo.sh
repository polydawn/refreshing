#!/bin/bash
set -euo pipefail

. env.shlib
cd "$FLING_BASE"

# Lift debuerreotype source from a git submodule into a tar.
rm -rf hitch.db/refreshing.polydawn.net/base-factory/debuerreotype || true
hitch catalog create "refreshing.polydawn.net/base-factory/debuerreotype"
hitch release start  "refreshing.polydawn.net/base-factory/debuerreotype" "vtmp"
hitch release add-item "script" "$(rio pack tar debuerreotype --target=ca+file://.warehouse/)"
hitch release commit

>&2 echo Templating formula the First...
frm="$(cat <<EOF
	{
		"formula": {
			"inputs": {
				"/":                  "$(hitch show "refreshing.polydawn.net/bases/mindeb:v0.1.1.1:linux-amd64")",
				"/app/debootstrap":   "tar:2oEopZrP5ah4Aj1iJYVwx5w28QXmKE9xQW1FAK6CpHsEvke1CUqLjFZ4HnWocveNiy",
				"/app/debuerreotype": "$(hitch show "refreshing.polydawn.net/base-factory/debuerreotype:vtmp:script")"
			},
			"action": {
				"policy": "sysad",
				"userinfo": {"uid":0},
				"env": {
					"DISTRIBUTION": "stretch",
					"TIMESTAMP": "2017-01-04T03:32:24Z",
					"DEBOOTSTRAP_DIR": "/app/debootstrap/debootstrap-1.0.87/",
					"PATH": "/app/debuerreotype/scripts/:/app/debootstrap/debootstrap-1.0.87/:/sbin:/usr/sbin:/bin:/usr/bin"
				},
				"exec": ["/bin/bash", "-c", "set -euo pipefail; apt update ; apt install -y wget ; debuerreotype-init --no-merged-usr /out \$DISTRIBUTION \$TIMESTAMP "]
			},
			"outputs": {
				"/out": {"packtype": "tar", "filters": {"uid":"keep", "gid":"keep", "sticky":"keep"}}
			}
		},
		"context": {
			"fetchUrls": {
				"/":                  ["ca+file://.warehouse/", "ca+https://repeatr.s3.amazonaws.com/warehouse/"],
				"/app/debootstrap":   ["http://snapshot.debian.org/archive/debian/20170104T033224Z/pool/main/d/debootstrap/debootstrap_1.0.87.tar.gz"],
				"/app/debuerreotype": ["ca+file://.warehouse/"]
			},
			"saveUrls": {"/out": "ca+file://.warehouse/"}
		}
	}
EOF
)"
#sed 's#/usr/share/debootstrap#\$PWD#g'
echo "$frm" | jq .formula

>&2 echo Running formula the First...
rr="$(repeatr run <(echo "$frm"))"
echo "$rr" | jq .
