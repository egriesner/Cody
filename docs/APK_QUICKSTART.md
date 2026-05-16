# APK Quickstart (Share to Tablets Fast)

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

## 5) If build fails

- Verify preset name `Android` exists in `export_presets.cfg`
- Confirm Android SDK paths are set in Godot editor settings
- Confirm export templates are installed for your Godot version
- Run with explicit binary if needed:

```bash
GODOT_BIN=/path/to/godot4 ./tools/build_apk.sh debug
```

## 6) Automatic APK builds on GitHub

This repo now includes `.github/workflows/android-apk.yml`.

- Every push to `main` and `cursor/*` builds an APK artifact.
- You can also run it manually from **Actions -> Android APK CI -> Run workflow**.
- Download from:
  - **GitHub -> Actions -> Android APK CI -> latest run -> Artifacts**

## 7) Permanent APK links via GitHub Releases

This repo also includes `.github/workflows/android-apk-release.yml`.

- Runs automatically on push to `main`
- Can be run manually from **Actions -> Android APK Release -> Run workflow**
- Creates a GitHub Release and attaches the APK

Download permanent APK URLs from:

- **GitHub -> Releases -> latest `apk-*` release -> Assets**
