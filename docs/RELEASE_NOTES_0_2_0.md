# RIFT: The Bestiary Protocol - Release Notes (0.2.0)

Developer: **Code Max Studios**

## Highlights

- Major visual polish pass with concept-derived art packs:
  - Player/enemy/boss skins
  - Biome backgrounds
  - Companion portraits
  - Hotbar icon set
  - Themed HUD panel and control skin textures
- Combat improvements:
  - Dash mechanic with cooldown and evade window
  - Combo multiplier flow with XP scaling
  - Spitter ranged projectile pressure
  - Difficulty scaling now affects pressure, damage, and loot economy
- Better run feedback:
  - In-run combo and dash state indicators
  - Run score + rank (C/B/A/S)
  - End-of-run summary with key performance stats
- Profile progression expansion:
  - Best score, best rank, best combo, total dash usage
- Audio/VFX layer added:
  - Biome background music loops
  - Core combat/UI SFX
  - Gameplay feedback particles with performance-aware limits
- Tablet performance controls:
  - Quality / Balanced / Performance presets
  - Optional in-run perf HUD for QA instrumentation
- Release process hardening:
  - One-command preflight checker (`./tools/preflight_release_check.sh`)
  - Release candidate checklist and internal test report template
  - CI workflows run preflight guardrails before AAB/Play publish jobs

## Build Artifacts

- Debug APK: `build/rift-bestiary-protocol-debug.apk`
- Release APK: `build/rift-bestiary-protocol-release.apk`
- Release AAB: `build/rift-bestiary-protocol-release.aab`

## Important Notes

- Debug artifacts are for device testing/sideloading.
- Production Play upload should use your private release keystore and Play Console configuration.
