#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/.build/app/Nicos Window Switcher.app"
BIN="$APP/Contents/MacOS/WindowSwitcher"
REPORT="${NICOS_SWITCHER_SELFTEST_REPORT:-$ROOT/.build/selftest-report.json}"
TIMEOUT_SECONDS="${NICOS_SWITCHER_SMOKE_TIMEOUT_SECONDS:-30}"

mkdir -p "$ROOT/.build"
rm -f "$REPORT"

if [[ ! -x "$BIN" ]]; then
  echo "missing binary: $BIN" >&2
  exit 1
fi

export NICOS_SWITCHER_HEADLESS=1
export NICOS_SWITCHER_SELFTEST=1
export NICOS_SWITCHER_SELFTEST_REPORT="$REPORT"

"$BIN" >"$ROOT/.build/smoke-stdout.log" 2>"$ROOT/.build/smoke-stderr.log" &
pid=$!
deadline=$(( $(date +%s) + TIMEOUT_SECONDS ))
code=""
while kill -0 "$pid" 2>/dev/null; do
  if (( $(date +%s) >= deadline )); then
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    echo "headless smoke timed out after ${TIMEOUT_SECONDS}s" >&2
    cat "$ROOT/.build/smoke-stderr.log" >&2 || true
    exit 124
  fi
  sleep 0.1
done
wait "$pid" || code=$?
code="${code:-0}"

echo "headless smoke exit=$code"
if [[ ! -f "$REPORT" ]]; then
  echo "no report written" >&2
  cat "$ROOT/.build/smoke-stderr.log" >&2 || true
  exit 1
fi
cat "$REPORT"

if [[ "$code" -ne 0 ]]; then
  cat "$ROOT/.build/smoke-stderr.log" >&2 || true
  exit "$code"
fi

ok=$(/usr/bin/plutil -extract ok raw -expect bool "$REPORT")
app=$(/usr/bin/plutil -extract app raw -expect string "$REPORT")
showing=$(/usr/bin/plutil -extract showing raw -expect bool "$REPORT")
allowed=$(/usr/bin/plutil -extract list_and_focus_allowed raw -expect bool "$REPORT")
option_tab=$(/usr/bin/plutil -extract hotkey_is_option_tab raw -expect bool "$REPORT")
hotkeys=$(/usr/bin/plutil -extract hotkeys_enabled raw -expect bool "$REPORT")
[[ "$app" == "nicos-window-switcher" ]]
[[ "$ok" == "true" ]]
[[ "$showing" == "true" ]]
[[ "$allowed" == "true" ]]
[[ "$option_tab" == "false" ]]
[[ "$hotkeys" == "true" ]]
echo "headless smoke ok"
