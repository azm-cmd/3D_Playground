# Runs the app on the local web-server device with the headers Thermion's
# WASM/worker runtime needs (SharedArrayBuffer requires the page to be
# cross-origin isolated). See tool/README.md for details.
#
# Usage: .\tool\run_web.ps1 [extra flutter run args]
$ErrorActionPreference = "Stop"
flutter run -d web-server --cross-origin-isolation @args
