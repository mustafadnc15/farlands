#!/usr/bin/env bash
# Runs the GUT suite headless. Usage: GODOT=<console exe> tools/run_tests.sh [extra GUT args]
if [ -z "${GODOT:-}" ]; then
	echo "ERROR: GODOT is not set. Export it to the Godot console executable, e.g." >&2
	echo '  export GODOT="C:/path/Godot_v4.7.2-stable_win64_console.exe"' >&2
	exit 1
fi
cd "$(dirname "$0")/.." || exit 1
log="$(mktemp)"; trap 'rm -f "$log"' EXIT
"$GODOT" --headless --path . --import >"$log" 2>&1; st=$?
if [ $st -ne 0 ] || grep -qE "Parse Error|Failed to load script" "$log"; then
	cat "$log"; echo "ERROR: import failed (exit $st) or a script failed to parse" >&2; exit 1
fi
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit "$@" 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
clean="$(sed 's/\x1b\[[0-9;]*m//g' "$log")"
if grep -qE "could not be loaded|Parse Error" <<<"$clean"; then
	echo "ERROR: a test script failed to load or parse (GUT skips it and still exits 0)" >&2; status=1
fi
if [ $# -eq 0 ]; then
	expected=$(find tests -name 'test_*.gd' | wc -l | tr -d ' ')
	ran=$(grep -E '^Scripts +[0-9]+' <<<"$clean" | awk '{print $2}' | tail -1)
	if [ "${ran:-0}" != "$expected" ]; then
		echo "ERROR: GUT ran ${ran:-0} test scripts, expected $expected" >&2; status=1
	fi
fi
exit $status
