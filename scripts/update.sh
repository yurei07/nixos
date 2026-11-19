#!/usr/bin/env bash
# Rebuild helper. Run from the repository root.
set -euo pipefail

if [[ ! -f flake.nix ]]; then
  echo "Run this from the repository root (where flake.nix lives)." >&2
  exit 1
fi

nix flake update
sudo nixos-rebuild switch --flake /etc/nixos#nixos
