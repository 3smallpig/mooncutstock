#!/usr/bin/env bash
set -euo pipefail
# Official snapshot: fail closed if mutable upstream objects change.
root="${MOON_HOME:?isolated MOON_HOME required}"
mkdir -p "$root/lib"
work="$(mktemp -d)"
trap 'rm -rf -- "$work"' EXIT
curl --fail --location --retry 2 --header 'If-Match: "6ae7c52851085cc3d4d65fd04410ef7b-12"' \
  https://cli.moonbitlang.com/binaries/latest/moonbit-linux-x86_64.tar.gz -o "$work/moon.tar.gz"
curl --fail --location --retry 2 --header 'If-Match: "65ef1811c0e64c48bf01312100f7e998"' \
  https://cli.moonbitlang.com/cores/core-latest.tar.gz -o "$work/core.tar.gz"
(cd "$work" && printf '%s\n' \
  '24b93a5409d2a4fb8e3d1b84b473f27b63476cef4418094764df96cb26b03c09  moon.tar.gz' \
  '96d30f4dbcc6a9e1736ef26fbdd0e8fb0e97cb01d50e55d2a0072208b8061ae5  core.tar.gz' | sha256sum --check -)
tar -xzf "$work/moon.tar.gz" -C "$root"
tar -xzf "$work/core.tar.gz" -C "$root/lib"
chmod +x "$root"/bin/*
export PATH="$root/bin:$PATH"
moon version --all
moon -C "$root/lib/core" bundle --warn-list -a --all
