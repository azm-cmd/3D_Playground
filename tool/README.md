# tool/

## `run_web.sh` / `run_web.ps1`

Thermion's web runtime (`thermion_dart.js`/`.wasm`) uses `SharedArrayBuffer`
to hand data to a Web Worker, which the browser only allows on a
cross-origin-isolated page — i.e. one served with:

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
will build and load fine but hit
`DataCloneError: SharedArrayBuffer transfer requires self.crossOriginIsolated`
as soon as Thermion tries to hand off to its worker — use one of these
scripts instead so you don't have to remember the flag:

```sh
tool/run_web.sh          # macOS/Linux/WSL
.\tool\run_web.ps1        # Windows PowerShell
```

Both just forward to `flutter run -d web-server --cross-origin-isolation`,
plus any extra arguments you pass. This only affects the local dev server —
it doesn't touch `build/web/` or any generated file, so there's nothing to
redo after a build.

`flutter build web` output has no server of its own; the same headers need
to be configured wherever you actually deploy `build/web/`, but that's a
hosting concern outside this repo's scope.
