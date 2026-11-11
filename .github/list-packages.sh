#!/usr/bin/env bash
# Prints the packages built by CPack or Inno Setup in the build directory $1,
# as GitHub step outputs: deb=..., tgz=..., exe=... (empty when absent).
set -euo pipefail
for kind in deb:'mozart2-*.deb' tgz:'mozart2-*.tar.gz' exe:'mozart2-*.exe'; do
  files=()  # no mapfile: macOS still ships bash 3.2
  while IFS= read -r f; do files+=("$f"); done < <(compgen -G "$1/${kind#*:}" || true)
  if [ ${#files[@]} -gt 1 ]; then
    echo "several packages match ${kind#*:}: ${files[*]}" >&2
    exit 1
  fi
  echo "${kind%%:*}=${files[0]-}"
done
