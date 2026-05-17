# Android Release Guide (Code Maxx Studios)

This guide covers how to share builds and publish to Google Play.

## 1) Recommended Toolchain

- Godot 4.2+ (or newer stable 4.x)
- Android SDK + platform tools
- Java 17+
- A Google Play Console developer account

## 2) Configure Android Build in Godot

1. Open project in Godot.
2. Install Android export templates:
   - `Editor -> Manage Export Templates`
3. Configure Android SDK paths:
   - `Editor -> Editor Settings -> Export -> Android`
4. Verify the preset in `export_presets.cfg`:
   - package id: `com.codemaxstudios.rift`
   - app name: `RIFT: The Bestiary Protocol`

## 3) Create Signing Keystore

You need a release keystore for Play Store uploads.

Example:

```bash
keytool -genkeypair -v -keystore codemax-release.jks -alias codemax-rift -keyalg RSA -keysize 2048 -validity 10000
```

Then set in Godot Android preset:

- Release Keystore
- Alias
- Store password
- Key password

Keep this keystore safe and backed up.

## 4) Build Artifacts

Quick path for local APK generation:

```bash
./tools/build_apk.sh debug
```

### Shareable test build (APK)

- Use Android export preset path:
  - `build/rift-bestiary-protocol.apk`
- Install directly on tablets for playtesting.
- Or use CI artifacts from `Android APK CI` workflow runs in GitHub Actions.
- For permanent hosted links, use `Android APK Release` workflow outputs in GitHub Releases.
- CI workflows use a generated debug keystore by default (testing/distribution only).
- For Play Store, switch workflow to your private release keystore + credentials.

### Play Store build (AAB)

- In Android preset, enable app bundle export.
- Export `.aab` for Play Console upload.
- CLI shortcut:
  - `./tools/build_aab.sh`

## 5) Play Store Readiness Checklist

- Landscape screenshots from real tablet gameplay.
- Feature graphic and icon.
- Privacy policy URL.
- Data Safety form completed in Play Console.
- Increment `version/code` for every new upload.
- Target API level matching current Play requirements.
- Content rating questionnaire completed.
- Internal testing track first, then closed/open, then production.

## 6) Child-Tablet Quality Gates Before Publish

- All critical controls reachable with two-thumb grip.
- No accidental input from edge palms (dead-zones verified).
- Session pacing: frequent rewards and minimal long text.
- Stable 60fps target on low/mid-tier tablets where possible.
- Clear state feedback for `EXHAUSTED`, `EAT`, and `RHINO_CHARGE`.
- Verify `performance_mode` presets (`quality`, `balanced`, `performance`) on real devices.

## 7) Full-Game Playtest Acceptance Gates

Before production store submission, verify:

1. New run starts from main menu and reaches wave gameplay.
2. Continue run restores inventory/progression correctly.
3. Objective completion unlocks boss phase (Overlord Vex).
4. Victory and defeat both return cleanly to main menu.
5. Profile stats update after each run (wins/runs/wave/pages).
6. Android orientation stays landscape and touch controls remain accurate.
7. No soft lock when pausing/resuming or ending a run.
8. First-run tutorial appears for new profiles and can be skipped/replayed.
9. Feedback hooks work on device: hit flash, vibration, and no visual spam.
10. Daily reward claims once per day and streak value increments.
11. Mid-run auto-checkpoint restores correctly when continuing.
12. UI scale and high-contrast settings persist and apply in runtime.

## 8) Branding

- Studio name in metadata: **Code Maxx Studios**
- Suggested publisher title in Play Console:
  - `Code Maxx Studios`

## 9) Balance and Tuning Entry Points

Tune these sections in `android_ui_state_config.json` for release balancing:

- `waveCombat`: pacing and pressure
- `progression`: level curve and survivability growth
- `crafting`: recipe costs and unlock levels
- `runGoals`: boss unlock gates
- `boss`: encounter durability and damage
- `tutorial`: onboarding steps and skip behavior

## 10) CI Setup for Play Store Upload

Workflow file:

- `.github/workflows/android-play-publish.yml`

Required repository variable:

- `GOOGLE_PLAY_PACKAGE_NAME` (example: `com.codemaxstudios.rift`)

Required repository secrets:

- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
- `ANDROID_KEYSTORE_BASE64` (base64 of your release keystore file)
- `ANDROID_KEYSTORE_ALIAS`
- `ANDROID_KEYSTORE_PASSWORD`

Then run:

- **Actions -> Android Play Store Publish -> Run workflow**
- Select track (`internal`, `alpha`, `beta`, `production`)
- Select release status (`completed`, `draft`, `inProgress`)

## 11) Store Listing and Policy Templates

Use these project templates to speed submission preparation:

- `docs/PLAY_STORE_LISTING_TEMPLATE.md`
- `docs/PRIVACY_POLICY_TEMPLATE.md`
- `docs/RELEASE_CANDIDATE_CHECKLIST.md`
- `docs/INTERNAL_TEST_REPORT_TEMPLATE.md`
- `docs/RELEASE_NOTES_2_0_0.md`
- `docs/PLAY_UPLOAD_HANDOFF.md`

## 12) One-Command Preflight Check

Before creating a release build, run:

```bash
./tools/preflight_release_check.sh
```

This verifies:

- release docs/templates are present
- workflow files required for APK/AAB/Play upload exist
- package ID and Play workflow variable references
- JSON config syntax validity
