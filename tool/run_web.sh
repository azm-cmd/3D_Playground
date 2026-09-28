#!/usr/bin/env bash
# Runs the app on the local web-server device, fetching Thermion's web
# runtime files first if they're not already present, then launching with
# the headers Thermion's WASM/worker runtime needs (SharedArrayBuffer
# requires the page to be cross-origin isolated). See tool/README.md.
#
# Usage: tool/run_web.sh [extra flutter run args]
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ ! -f web/thermion_dart.js || ! -f web/thermion_dart.wasm ]]; then
  echo "==> Thermion web runtime files not found under web/ — fetching them (one-time)."

  if grep -q '^hooks:' pubspec.yaml; then
    echo "pubspec.yaml already has a top-level 'hooks:' section." >&2
    echo "Add this by hand instead (see tool/README.md), then re-run:" >&2
    echo "  hooks:" >&2
    echo "    user_defines:" >&2
    echo "      thermion_dart:" >&2
    echo "        skip_native_build: true" >&2
    exit 1
  fi

  cp pubspec.yaml pubspec.yaml.orig
  cleanup() {
    if [[ -f pubspec.yaml.orig ]]; then
      mv -f pubspec.yaml.orig pubspec.yaml
      flutter pub get >/dev/null
    fi
  }
  trap cleanup EXIT

  # Temporarily opt in to thermion_dart's own escape hatch (see
  # tool/README.md) so the plain-HTTP web-asset download doesn't trip
  # a mandatory native-toolchain probe `dart run` performs first — that
  # probe needs no C compiler for this download, but crashes on Windows
  # when the project path contains spaces. Reverted as soon as the fetch
  # below finishes (or fails), so it never affects native (Android/iOS/
  # desktop) builds.
  {
    echo ""
    echo "hooks:"
    echo "  user_defines:"
    echo "    thermion_dart:"
    echo "      skip_native_build: true"
  } >> pubspec.yaml

  flutter pub get >/dev/null
  dart run thermion_dart:download_web

  mv -f pubspec.yaml.orig pubspec.yaml
  flutter pub get >/dev/null
  trap - EXIT

  echo "==> Fetched web/thermion_dart.js and web/thermion_dart.wasm."
fi

exec flutter run -d web-server --cross-origin-isolation "$@"
