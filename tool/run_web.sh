#!/usr/bin/env bash
# Runs the app on the local web-server device with the headers Thermion's
# WASM/worker runtime needs (SharedArrayBuffer requires the page to be
# cross-origin isolated). See tool/README.md for details.
#
# Usage: tool/run_web.sh [extra flutter run args]
set -euo pipefail
exec flutter run -d web-server --cross-origin-isolation "$@"
