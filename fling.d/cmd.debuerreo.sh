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
## Some comments about image fabrication:
##  - we do include 'ca-certificates'.  This is not great for updatability, but you can overlay it with a newer one if you want.  We figured it's better to be not-broken out of box.
##  - we do set a default '/etc/resolv.conf' file.  Again, the reasoning is based on practicality and wanting things to work out of box.
frm="$(cat <<EOF
	formula:
		inputs:
			"/":                  "$(hitch show "refreshing.polydawn.net/bases/mindeb:v0.1.1.1:linux-amd64")"
			"/app/debootstrap":   "tar:2oEopZrP5ah4Aj1iJYVwx5w28QXmKE9xQW1FAK6CpHsEvke1CUqLjFZ4HnWocveNiy"
			"/app/debuerreotype": "$(hitch show "refreshing.polydawn.net/base-factory/debuerreotype:vtmp:script")"
		action:
			policy: "sysad"
			userinfo: {"uid":0, "gid":0}
			env:
				"DISTRIBUTION": "stretch"
				"TIMESTAMP": "2017-01-04T03:32:24Z"
				"DEBOOTSTRAP_DIR": "/app/debootstrap/debootstrap-1.0.87/"
				"PATH": "/app/debuerreotype/scripts/:/app/debootstrap/debootstrap-1.0.87/:/sbin:/usr/sbin:/bin:/usr/bin"
			exec:
				- "/bin/bash"
				- "-c"
				- |
					set -euo pipefail
					apt update
					apt install -y wget
					debuerreotype-init --no-merged-usr /out \$DISTRIBUTION \$TIMESTAMP
					debuerreotype-minimizing-config /out
					debuerreotype-apt-get /out update -qq
					debuerreotype-apt-get /out dist-upgrade -yqq
					debuerreotype-apt-get /out install -y --no-install-recommends inetutils-ping iproute2 wget curl ca-certificates
					debuerreotype-slimify /out
					debuerreotype-gen-sources-list /out \$DISTRIBUTION http://deb.debian.org/debian http://security.debian.org
					echo 'nameserver 8.8.8.8' > /out/etc/resolv.conf
					# scrape out sources of unreproducibility
					# (documented in debuerreotype/.tar-exclude, but we replicate here because we don't use tar like that.)
					set +e # if these paths are already empty, that's surely fine.
					rm -r /out/debuerreotype-epoch
					rm -r /out/proc/*
					rm -r /out/sys/*
					rm -r /out/var/cache/apt/*
					rm -r /out/var/lib/apt/lists/*
					rm -r /out/etc/apt/apt.conf.d/01autoremove-kernels
					rm -r /out/var/log/apt/history.log
					rm -r /out/var/log/apt/term.log
					rm -r /out/run/motd.dynamic
					rm -r /out/etc/apt/trustdb.gpg
					rm -r /out/var/lib/systemd/catalog/database
					# more (these are in debuerreotype-fixup instead of the tar-excludes for some reason)
					rm /out/var/log/dpkg.log
					rm /out/var/log/bootstrap.log
					rm /out/var/log/alternatives.log
					rm /out/var/cache/ldconfig/aux-cache
		outputs:
			"/out":
				packtype: "tar"
				filters: {"uid":"keep", "gid":"keep", "sticky":"keep"}
	context:
		fetchUrls:
			"/":                  ["ca+file://.warehouse/", "ca+https://repeatr.s3.amazonaws.com/warehouse/"]
			"/app/debootstrap":   ["http://snapshot.debian.org/archive/debian/20170104T033224Z/pool/main/d/debootstrap/debootstrap_1.0.87.tar.gz"]
			"/app/debuerreotype": ["ca+file://.warehouse/"]
		saveUrls:
			"/out": "ca+file://.warehouse/"
EOF
)"
frm="$(echo "$frm" | refmt yaml=json)"
echo "$frm" | jq .formula

>&2 echo Running formula the First...
rr="$(repeatr run <(echo "$frm"))"
echo "$rr" | jq .
