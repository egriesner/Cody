# Android Package Quickstart (APK + AAB)

Use this for a quick sideloadable APK build.

## 1) Prerequisites

- Godot 4.x installed (`godot4` or `godot` in PATH)
- Android SDK configured in Godot export settings
- Export templates installed in Godot
- Optional for USB install: `adb`

## 2) Build a Debug APK

From repo root:

```bash
./tools/build_apk.sh debug
```

Output:

`build/rift-bestiary-protocol-debug.apk`

## 3) Install on a connected tablet

```bash
adb install -r build/rift-bestiary-protocol-debug.apk
```

You can also copy the APK file to cloud storage/drive and open it directly on tablets.

## 4) Build a Release APK

```bash
./tools/build_apk.sh release
```

Output:

`build/rift-bestiary-protocol-release.apk`

Release builds require signing setup in the Godot Android export preset.

## 5) Build a Play Store AAB

```bash
./tools/build_aab.sh
```

or explicitly:

```bash
./tools/build_apk.sh release aab
```

Output:

`build/rift-bestiary-protocol-release.aab`

## 6) If build fails

- Verify preset name `Android` exists in `export_presets.cfg`
- Confirm Android SDK paths are set in Godot editor settings
- Confirm export templates are installed for your Godot version
- Run with explicit binary if needed:

```bash
GODOT_BIN=/path/to/godot4 ./tools/build_apk.sh debug
```

## 7) Automatic APK builds on GitHub

This repo now includes `.github/workflows/android-apk.yml`.

- Every push to `main` and `cursor/*` builds an APK artifact.
- You can also run it manually from **Actions -> Android APK CI -> Run workflow**.
- Download from:
  - **GitHub -> Actions -> Android APK CI -> latest run -> Artifacts**

## 8) Permanent package links via GitHub Releases

This repo also includes `.github/workflows/android-apk-release.yml`.

- Runs automatically on push to `main`
- Can be run manually from **Actions -> Android APK Release -> Run workflow**
- Creates a GitHub Release and attaches the built APK/AAB

Download permanent APK URLs from:

- **GitHub -> Releases -> latest `apk-*` or `aab-*` release -> Assets**

> Note: CI currently signs with an auto-generated debug keystore for distribution testing.
> For Play Store production signing, configure your release keystore/credentials in workflow secrets.

## 9) Publish directly to Google Play from CI

Workflow: `.github/workflows/android-play-publish.yml`

Run from:

- **Actions -> Android Play Store Publish -> Run workflow**

Required repo configuration:

- Repository variable:
  - `GOOGLE_PLAY_PACKAGE_NAME` (e.g. `com.codemaxstudios.rift`)
- Repository secrets:
  - `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
  - `ANDROID_KEYSTORE_BASE64`
  - `ANDROID_KEYSTORE_ALIAS`
  - `ANDROID_KEYSTORE_PASSWORD`
