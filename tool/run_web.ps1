# Runs the app on the local web-server device, fetching Thermion's web
# runtime files first if they're not already present, then launching with
# the headers Thermion's WASM/worker runtime needs (SharedArrayBuffer
# requires the page to be cross-origin isolated). See tool/README.md.
#
# Usage: .\tool\run_web.ps1 [extra flutter run args]
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

$needsFetch = -not (Test-Path "web/thermion_dart.js") -or -not (Test-Path "web/thermion_dart.wasm")

if ($needsFetch) {
    Write-Host "==> Thermion web runtime files not found under web/ - fetching them (one-time)."

    if (Select-String -Path "pubspec.yaml" -Pattern "^hooks:" -Quiet) {
        Write-Error @"
pubspec.yaml already has a top-level 'hooks:' section.
Add this by hand instead (see tool/README.md), then re-run:
  hooks:
    user_defines:
      thermion_dart:
        skip_native_build: true
"@
        exit 1
    }

    Copy-Item "pubspec.yaml" "pubspec.yaml.orig"
    try {
        # Temporarily opt in to thermion_dart's own escape hatch (see
        # tool/README.md) so the plain-HTTP web-asset download doesn't trip
        # a mandatory native-toolchain probe `dart run` performs first -
        # that probe needs no C compiler for this download, but crashes on
        # Windows when the project path contains spaces. Reverted as soon
        # as the fetch below finishes (or fails), so it never affects
        # native (Android/iOS/desktop) builds.
        Add-Content "pubspec.yaml" "`nhooks:`n  user_defines:`n    thermion_dart:`n      skip_native_build: true`n"
        flutter pub get | Out-Null
        dart run thermion_dart:download_web
    }
    finally {
        Move-Item -Force "pubspec.yaml.orig" "pubspec.yaml"
        flutter pub get | Out-Null
    }

    Write-Host "==> Fetched web/thermion_dart.js and web/thermion_dart.wasm."
}

flutter run -d web-server --cross-origin-isolation @args
