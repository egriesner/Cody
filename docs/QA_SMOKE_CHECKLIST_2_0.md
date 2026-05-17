# RIFT 2.0 Smoke Checklist

Use this checklist before promoting any build beyond internal testing.

## 1) Automated smoke gates

Run locally:

```bash
./tools/smoke_check.sh
```

Expected:

- JSON config parses cleanly
- main scenes/scripts load in Godot headless probe
- release preflight passes

## 2) Build artifact smoke

```bash
./tools/build_apk.sh release
./tools/build_apk.sh release aab
sha256sum build/rift-bestiary-protocol-release.apk build/rift-bestiary-protocol-release.aab
```

Verify:

- APK and AAB files are generated
- checksums are recorded in release notes/PR notes

## 3) Runtime play smoke (5-10 minutes)

- Start a new run.
- Confirm move + aim sticks track correctly.
- Confirm wave mutator text changes when a new wave starts.
- Confirm at least one elite enemy appears by later waves.
- Charge and trigger Rift Burst at least once.
- Pause -> resume works.
- Pause -> save and return to menu -> continue run works.

## 4) Session/reporting smoke

- Finish a run (victory or defeat).
- Confirm summary includes:
  - run score/rank
  - elite defeats
  - Rift bursts used
- Return to menu and verify profile stats update.

## 5) Telemetry/crash-diagnostics smoke

- After one run, confirm telemetry files exist in `user://`:
  - `telemetry_events.jsonl`
  - `telemetry_state.json`
- Force-close app during runtime once, relaunch:
  - menu should show recovery notice
  - telemetry should log an `unclean_shutdown_detected` event
