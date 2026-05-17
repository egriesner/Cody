# Production Launch Runbook (2.0.0)

This runbook covers everything that can be automated in-repo and the final manual Play Console actions.

## 1) One-command release candidate (local)

```bash
./tools/release_orchestrator.sh
```

This command performs:

- smoke checks (`tools/smoke_check.sh`)
- preflight checks (`tools/preflight_release_check.sh`)
- release APK build
- release AAB build
- checksum generation
- manifest generation

Outputs:

- `build/rift-bestiary-protocol-release.apk`
- `build/rift-bestiary-protocol-release.aab`
- `build/release-checksums-<version>.txt`
- `build/release-manifest-<version>.json`
- `build/release-summary-<version>.md`

## 2) One-click release candidate (CI)

Run workflow:

- **Actions -> Android Release Candidate Bundle -> Run workflow**

Artifacts uploaded:

- release APK/AAB
- checksums
- release manifest
- markdown summary

## 2b) Browser build path (managed devices / no install)

If test devices block APK install, build and host the browser bundle:

```bash
./tools/build_web.sh release
```

Then host `build/web` on static hosting and test via URL on the device browser.

For GitHub-native hosting, run:

- **Actions -> Web Pages Deploy -> Run workflow**

Then use the Pages deployment URL on the device.

## 3) Production signing + Play publish (CI path)

Set repository variable:

- `GOOGLE_PLAY_PACKAGE_NAME`

Set repository secrets:

- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_ALIAS`
- `ANDROID_KEYSTORE_PASSWORD`

Then run:

- **Actions -> Android Play Store Publish -> Run workflow**

Recommended order:

1. `internal` track
2. `alpha` / `beta`
3. production staged rollout

## 4) Final manual checks in Play Console

These remain manual by design:

- verify Data Safety answers
- verify content rating and audience settings
- verify store listing text/screenshots/graphics
- confirm release notes and rollout percentage

## 5) Telemetry diagnostics after release

The app writes telemetry diagnostics to:

- `user://telemetry_events.jsonl`
- `user://telemetry_state.json`

For field bug triage, collect these files from test devices when possible.
