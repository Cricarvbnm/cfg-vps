#!/usr/bin/env bash
set -euo pipefail
umask 077

archive=$1
destination=$2
owner=$3
group=$4

mkdir -p -- "$(dirname -- "$destination")"
stage=$(mktemp -d "$(dirname -- "$destination")/.mihomo-client.XXXXXXXX")
committed=false
cleanup() {
  if ! "$committed" && { test -e "$stage/previous" || test -L "$stage/previous"; }; then
    if test -e "$destination" || test -L "$destination" || \
      ! mv -T -- "$stage/previous" "$destination"; then
      printf 'Previous Mihomo tree retained at %s/previous\n' "$stage" >&2
      return
    fi
  fi
  rm -rf -- "$stage"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

mkdir -- "$stage/content"
tar --extract --gzip --file="$archive" --directory="$stage/content" \
  --no-same-owner --no-same-permissions --delay-directory-restore

chown -R -- "$owner:$group" "$stage/content"
find "$stage/content" -type d -exec chmod 0750 -- {} +
find "$stage/content" -type f -exec chmod 0640 -- {} +

# Keep the old tree until extraction and permission setup have succeeded.
if test -e "$destination" || test -L "$destination"; then
  mv -T -- "$destination" "$stage/previous"
fi
mv -T -- "$stage/content" "$destination"
committed=true
