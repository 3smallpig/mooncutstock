#!/usr/bin/env bash
set -euo pipefail
# Official archived snapshot: pin compiler/core version AND fail closed on digest changes.
root="${MOON_HOME:?isolated MOON_HOME required}"
mkdir -p "$root/lib"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
curl --fail --location --retry 2 --header 'If-Match: "0560ebd5ba5528390cd4872766f2234b"' \
  https://cli.moonbitlang.com/binaries/0.10.18%2B6c83a7f62/moonbit-linux-x86_64.tar.gz -o "$work/moon.tar.gz"
curl --fail --location --retry 2 --header 'If-Match: "7b87b77b0d942a76fba657b809c31cdf"' \
  https://cli.moonbitlang.com/cores/core-0.10.18%2B6c83a7f62.tar.gz -o "$work/core.tar.gz"
(cd "$work" && printf '%s\n' \
  '0e4cde1ace98e8ef00552a937738b59c6901c4b8a004ebad71ea0e63688f63f1  moon.tar.gz' \
  '30a8ae1c1e1e8fde478ea742cbc928c8f4ae1f5c00090afe3f10c97be9e5da64  core.tar.gz' | sha256sum --check -)
tar -xzf "$work/moon.tar.gz" -C "$root"
tar -xzf "$work/core.tar.gz" -C "$root/lib"
chmod +x "$root"/bin/*
export PATH="$root/bin:$PATH"
moon version --all
moon -C "$root/lib/core" bundle --warn-list -a --all
