# RIFT: The Bestiary Protocol - Release Notes (2.0.0)

Developer: **Code Maxx Studios**

## 2.0 Ultra Upgrade Highlights

- New high-impact combat systems:
  - **Rift Burst** ultimate ability (charge + detonate + area damage + enemy slow field)
  - **Elite enemy variants** with boosted stats, visuals, and reward bonuses
  - **Wave Mutator Director** introducing rotating anomaly rules each wave
- Advanced encounter pressure and variety:
  - Mutator-driven adjustments to spawn pressure, projectile speed, damage, loot, and XP
  - Elite spawn scaling with wave progression
- Premium readability and game feel polish:
  - Floating hit markers for criticals, misses, boss hits, downs, and near-miss moments
  - Combat reticle rendering and stronger in-run clarity cues
  - Dynamic HUD updates for mutators, Rift energy, and cooldown state
- Audio and presentation upgrades:
  - Menu theme + startup studio sting
  - Dynamic in-run music ducking/intensity behavior
  - Multi-channel SFX playback for cleaner overlap during heavy action
- Progression and scoring enhancements:
  - Run score now accounts for elite takedowns and Rift Burst usage
  - Expanded run summary metrics and continuation snapshot coverage
- Launch-readiness operations:
  - Runtime telemetry + unclean-shutdown diagnostics (`user://telemetry_events.jsonl`, `user://telemetry_state.json`)
  - New automated smoke gate (`./tools/smoke_check.sh`)
  - One-command release candidate orchestrator (`./tools/release_orchestrator.sh`)
  - Dedicated CI smoke workflow (`.github/workflows/android-smoke.yml`)
  - Dedicated CI release-candidate artifact bundle workflow (`.github/workflows/android-release-candidate.yml`)

## Build Artifacts (2.0)

- Debug APK: `build/rift-bestiary-protocol-debug.apk`
- Release APK: `build/rift-bestiary-protocol-release.apk`
- Release AAB: `build/rift-bestiary-protocol-release.aab`

## Publishing Note

For production store publishing, generate final signed artifacts with your private release keystore and Play Console credentials.
