#!/usr/bin/env bash
# Runs the GUT suite headless. Usage: GODOT=<console exe> tools/run_tests.sh [extra GUT args]
if [ -z "${GODOT:-}" ]; then
	echo "ERROR: GODOT is not set. Export it to the Godot console executable, e.g." >&2
	echo '  export GODOT="C:/path/Godot_v4.7.2-stable_win64_console.exe"' >&2
	exit 1
fi
cd "$(dirname "$0")/.." || exit 1
"$GODOT" --headless --path . --import >/dev/null 2>&1
"$GODOT" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit "$@"
exit $?
