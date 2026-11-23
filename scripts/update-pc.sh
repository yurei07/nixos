#!/usr/bin/env bash
# Update the PC from this laptop: pull the repo there and rebuild its own host.
# Usage: /etc/nixos/scripts/update-pc.sh   (asks the PC's sudo password once)

set -euo pipefail

host=${NIHIL_PC:-192.168.0.150}
user=${NIHIL_PC_USER:-Prizrak}

ssh -t "$user@$host" '
	set -e
	cd /etc/nixos
	git pull --ff-only
	sudo nihil rebuild
	echo "PC updated."
'
