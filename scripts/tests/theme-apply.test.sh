#!/usr/bin/env bash
# theme-apply.sh: quick requests collapse into the newest, none is lost, a failure is retried.
# Runs against a stub matugen (no real theming): bash scripts/tests/theme-apply.test.sh
set -u
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
cat >"$tmp/bin/matugen" <<'STUB'
#!/usr/bin/env bash
sleep 0.3
[ -f "$FAIL_FLAG" ] && exit 1
echo "$2" >>"$RUNS"
STUB
printf '#!/bin/sh\n' >"$tmp/bin/busctl"   # no real notifications from a test
chmod +x "$tmp/bin/matugen" "$tmp/bin/busctl"
export PATH="$tmp/bin:$PATH" XDG_STATE_HOME="$tmp/state" RUNS="$tmp/runs" FAIL_FLAG="$tmp/fail"

for i in 1 2 3 4 5; do "$here/../theme-apply.sh" "/w/$i.png" & sleep 0.05; done
wait
last=$(tail -n1 "$RUNS")
[ "$last" = /w/5.png ] || { echo "FAIL: newest request not applied last (got $last)"; exit 1; }
[ "$(wc -l <"$RUNS")" -lt 5 ] || { echo "FAIL: requests did not collapse ($(wc -l <"$RUNS") runs)"; exit 1; }

touch "$FAIL_FLAG"; "$here/../theme-apply.sh" /w/6.png; rm "$FAIL_FLAG"
"$here/../theme-apply.sh" /w/6.png
[ "$(tail -n1 "$RUNS")" = /w/6.png ] || { echo "FAIL: a failed request was not retried"; exit 1; }
echo "ok: $(wc -l <"$RUNS") runs for 7 requests, newest last, failure retried"
