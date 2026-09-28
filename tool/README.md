# tool/

## `run_web.sh` / `run_web.ps1`

Run one of these instead of `flutter run -d web-server` directly — they make
a first run on a clean checkout work without any manual setup:

```sh
tool/run_web.sh          # macOS/Linux/WSL
.\tool\run_web.ps1        # Windows PowerShell
```

They do two things:

### 1. Fetch Thermion's web runtime files, if missing

Thermion's web support needs `thermion_dart.js` and `thermion_dart.wasm`
sitting next to `web/index.html`. They're not committed to this repo (see
"Why not commit them?" below), so the first run fetches them via Thermion's
own `dart run thermion_dart:download_web`.

Running that command directly can crash with something like
`'C:\Program' is not recognized as an internal or external command` on
Windows, if your project path contains spaces (e.g.
`C:\Users\you\Desktop\3D Playground\`). The actual cause: `dart run`
unconditionally probes for a native C++ toolchain before running *any*
script in a project with native-asset hooks — even a pure-HTTP download
script that never needs one — and that probe shells out via
`cmd /c <unquoted path>` on Windows, which breaks on spaces. It's a gap in
the underlying `native_toolchain_c` tooling, not something in this project
or in Thermion's own download logic.

`thermion_dart` ships its own escape hatch for exactly this: a
`skip_native_build` user-define that short-circuits that probe before it
runs. The scripts here set it in `pubspec.yaml` **only for the duration of
the fetch**, then remove it again (guaranteed, even if the fetch fails —
`trap`/`try`-`finally`), so it can never linger and silently break a real
native build (Android/iOS/desktop), which does need that toolchain probe to
succeed. If `pubspec.yaml` already has its own `hooks:` section, the script
stops and asks you to add the define by hand instead of guessing how to
merge into it.

Once fetched, `web/thermion_dart.js`/`.wasm` stay on disk — every run after
the first skips this step entirely.

### 2. Launch with cross-origin isolation

Thermion's web runtime uses `SharedArrayBuffer` to hand data to a Web
Worker, which the browser only allows on a cross-origin-isolated page —
i.e. one served with:

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: credentialless
```

(`credentialless` rather than the sometimes-cited `require-corp` — the two
are alternative ways to satisfy the same `crossOriginIsolated` requirement,
and everything this app loads is same-origin, so the choice makes no
practical difference here.)

Flutter's dev server does **not** add these by default for the `canvaskit`
renderer this project uses (only for `skwasm`), but it has a first-party
flag that does: `--cross-origin-isolation`. Plain `flutter run -d web-server`
would build and load fine but hit
`DataCloneError: SharedArrayBuffer transfer requires self.crossOriginIsolated`
as soon as Thermion tries to hand off to its worker.

Both scripts just forward any extra arguments you pass, e.g.
`tool/run_web.sh --web-port=5000`.

Neither step touches `build/web/` or any generated file — nothing to redo
after a build. `flutter build web` output has no server of its own; the
same headers need to be configured wherever you actually deploy
`build/web/`, but that's a hosting concern outside this repo's scope.

### Why not commit `thermion_dart.js`/`.wasm`?

They're sizeable binary build artifacts tied to a specific Thermion release,
not source — committing them would bloat the repo's history and go stale
silently on a version bump. If your environment can't reach
`pub-c8b6266320924116aaddce03b5313c0a.r2.dev` (the host Thermion fetches
from) at all — some sandboxes and locked-down networks block it — fetch
`web/thermion_dart.js`/`.wasm` once somewhere that can, then either commit
them to this repo yourself, or copy them into `web/` on the restricted
machine directly; either way the scripts here see the files already exist
and skip straight to launching.
