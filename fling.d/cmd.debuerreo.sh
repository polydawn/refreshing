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

# Run one formula with high enough privs to create dev nodes.
#  We do this separately from the apt steps so we don't have "network" and "sysad" touching.
>&2 echo Templating a formula to build the basic dev nodes...
frm="$(cat <<EOF
	{
		"formula": {
			"inputs": {
				"/": "$(hitch show "refreshing.polydawn.net/bases/mindeb:v0.1.1.1:linux-amd64")"
			},
			"action": {
				"policy": "sysad",
				"exec": ["/bin/bash", "-c", "set -euo pipefail; mkdir -p /chroot/dev; cd /chroot/dev; mknod null c 1 3; mknod zero c 1 5; mknod full c 1 7; mknod random c 1 8; mknod urandom c 1 9;"]
			},
			"outputs": {
				"/chroot": {"packtype": "tar", "filters": {"uid":"0", "gid":"0", "sticky":"keep"}}
			}
		},
		"context": {
			"fetchUrls": {
				"/": ["ca+file://.warehouse/", "ca+https://repeatr.s3.amazonaws.com/warehouse/"]
			},
			"saveUrls": {"/chroot": "ca+file://.warehouse/"}
		}
	}
EOF
)"
echo "$frm" | jq .formula
>&2 echo Running formula the First...
rr="$(repeatr run <(echo "$frm"))"
echo "$rr" | jq .
chroot_ware="$(echo "$rr" | jq -r '.results["/chroot"]')"

>&2 echo Templating formula for debootstrap fabrication...
## Some comments about image fabrication:
##  - we do include 'ca-certificates'.  This is not great for updatability, but you can overlay it with a newer one if you want.  We figured it's better to be not-broken out of box.
##  - we do set a default '/etc/resolv.conf' file.  Again, the reasoning is based on practicality and wanting things to work out of box.
frm="$(cat <<EOF
	{
		"formula": {
			"inputs": {
				"/":                  "$(hitch show "refreshing.polydawn.net/bases/mindeb:v0.1.1.1:linux-amd64")",
				"/app/debootstrap":   "tar:2oEopZrP5ah4Aj1iJYVwx5w28QXmKE9xQW1FAK6CpHsEvke1CUqLjFZ4HnWocveNiy",
				"/app/debuerreotype": "$(hitch show "refreshing.polydawn.net/base-factory/debuerreotype:vtmp:script")",
				"/chroot":            "$chroot_ware"
			},
			"action": {
				"policy": "governor",
				"userinfo": {"uid":0,"gid":0},
				"env": {
					"DISTRIBUTION": "stretch",
					"TIMESTAMP": "2017-01-04T03:32:24Z",
					"DEBOOTSTRAP_DIR": "/app/debootstrap/debootstrap-1.0.87/",
					"PATH": "/app/debuerreotype/scripts/:/app/debootstrap/debootstrap-1.0.87/:/sbin:/usr/sbin:/bin:/usr/bin"
				},
				"exec": ["/bin/bash", "-c", "set -euo pipefail; apt update ; apt install -y wget ; debuerreotype-init --no-merged-usr /chroot \$DISTRIBUTION \$TIMESTAMP ; debuerreotype-minimizing-config /chroot ; debuerreotype-apt-get /chroot update -qq ; debuerreotype-apt-get /chroot dist-upgrade -yqq ; debuerreotype-apt-get /chroot install -y --no-install-recommends inetutils-ping iproute2 wget curl ca-certificates ; debuerreotype-slimify /chroot ; debuerreotype-gen-sources-list /chroot \$DISTRIBUTION http://deb.debian.org/debian http://security.debian.org ; echo 'nameserver 8.8.8.8' > /chroot/etc/resolv.conf ; "]
			},
			"outputs": {
				"/chroot": {"packtype": "tar", "filters": {"uid":"keep", "gid":"keep", "sticky":"keep"}}
			}
		},
		"context": {
			"fetchUrls": {
				"/":                  ["ca+file://.warehouse/", "ca+https://repeatr.s3.amazonaws.com/warehouse/"],
				"/app/debootstrap":   ["http://snapshot.debian.org/archive/debian/20170104T033224Z/pool/main/d/debootstrap/debootstrap_1.0.87.tar.gz"],
				"/app/debuerreotype": ["ca+file://.warehouse/"],
				"/chroot":            ["ca+file://.warehouse/"]
			},
			"saveUrls": {"/chroot": "ca+file://.warehouse/"}
		}
	}
EOF
)"
echo "$frm" | jq .formula

>&2 echo Running formula the First...
rr="$(repeatr run <(echo "$frm"))"
echo "$rr" | jq .
