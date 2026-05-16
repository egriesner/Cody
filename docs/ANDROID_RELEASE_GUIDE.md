# Android Release Guide (Code Max Studios)

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

### Shareable test build (APK)

- Use Android export preset path:
  - `build/rift-bestiary-protocol.apk`
- Install directly on tablets for playtesting.

### Play Store build (AAB)

- In Android preset, enable app bundle export.
- Export `.aab` for Play Console upload.

## 5) Play Store Readiness Checklist

- Landscape screenshots from real tablet gameplay.
- Feature graphic and icon.
- Privacy policy URL.
- Target API level matching current Play requirements.
- Content rating questionnaire completed.
- Internal testing track first, then closed/open, then production.

## 6) Child-Tablet Quality Gates Before Publish

- All critical controls reachable with two-thumb grip.
- No accidental input from edge palms (dead-zones verified).
- Session pacing: frequent rewards and minimal long text.
- Stable 60fps target on low/mid-tier tablets where possible.
- Clear state feedback for `EXHAUSTED`, `EAT`, and `RHINO_CHARGE`.

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

- Studio name in metadata: **Code Max Studios**
- Suggested publisher title in Play Console:
  - `Code Max Studios`

## 9) Balance and Tuning Entry Points

Tune these sections in `android_ui_state_config.json` for release balancing:

- `waveCombat`: pacing and pressure
- `progression`: level curve and survivability growth
- `crafting`: recipe costs and unlock levels
- `runGoals`: boss unlock gates
- `boss`: encounter durability and damage
- `tutorial`: onboarding steps and skip behavior
