#!/usr/bin/env bash
set -euo pipefail

script="$(cd -- "$(dirname -- "$0")/.." && pwd)/modules/caddy.nix/deploy-mihomo-client.sh"
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
mkdir -p "$work/input/client/nested" "$work/input/future" "$work/srv/mihomo/client"
printf 'old\n' > "$work/srv/mihomo/client/removed.yaml"
printf 'obsolete\n' > "$work/srv/mihomo/obsolete"
printf 'new\n' > "$work/input/client/nested/config.yaml"
printf 'extra\n' > "$work/input/future/settings.yaml"
owner=$(id -u)
group=$(id -g)

deploy() {
  bash "$script" "$work/client.tar.gz" "$work/srv/mihomo" "$owner" "$group"
}

tar -czf "$work/client.tar.gz" -C "$work/input" .
deploy
test ! -e "$work/srv/mihomo/client/removed.yaml"
test ! -e "$work/srv/mihomo/obsolete"
cmp "$work/input/client/nested/config.yaml" "$work/srv/mihomo/client/nested/config.yaml"
cmp "$work/input/future/settings.yaml" "$work/srv/mihomo/future/settings.yaml"
test "$(stat -c '%a:%u:%g' "$work/srv/mihomo")" = "750:$owner:$group"
test "$(stat -c '%a:%u:%g' "$work/srv/mihomo/client/nested/config.yaml")" = "640:$owner:$group"
printf 'PASS: complete replacement and permissions\n'

printf 'invalid\n' > "$work/client.tar.gz"
if deploy 2> "$work/error.log"; then
  echo 'Invalid archive unexpectedly succeeded' >&2
  exit 1
fi
test -f "$work/srv/mihomo/client/nested/config.yaml"
printf 'PASS: invalid archive preserves installed tree\n'

# Inject a failed install and failed rollback; the old backup must survive.
mkdir -p "$work/bin"
cat > "$work/bin/mv" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
count=0
if test -f "$MV_COUNT"; then read -r count < "$MV_COUNT"; fi
printf '%s\n' "$((count + 1))" > "$MV_COUNT"
if ((count >= 1)); then exit 1; fi
exec "$REAL_MV" "$@"
EOF
chmod +x "$work/bin/mv"
tar -czf "$work/client.tar.gz" -C "$work/input" .
real_mv=$(command -v mv)
if PATH="$work/bin:$PATH" MV_COUNT="$work/mv-count" REAL_MV="$real_mv" deploy 2> "$work/error.log"; then
  echo 'Failed install unexpectedly succeeded' >&2
  exit 1
fi
test -n "$(find "$work/srv" -path '*/previous/client/nested/config.yaml' -print -quit)"
printf 'PASS: failed rollback retains backup\n'

mkdir -p "$work/empty"
tar -czf "$work/client.tar.gz" -C "$work/empty" .
deploy
test -d "$work/srv/mihomo"
test -z "$(find "$work/srv/mihomo" -mindepth 1 -print -quit)"
printf 'PASS: empty archive deploys an empty directory\n'
