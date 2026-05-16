# Cody

RIFT project assets and a runnable Godot starter game for Android tablet deployment.

Developer/Studio: **Code Max Studios**

## Project Layout

- `project.godot`
  - Godot project entry point.
- `scenes/Main.tscn`
  - App shell scene (main menu, settings, run launcher).
- `scenes/Game.tscn`
  - Standalone gameplay runtime scene.
- `scripts/Main.gd`
  - App controller (menu, settings, profile flow, new run/continue run).
- `scripts/GameRuntime.gd`
  - Full gameplay runtime: touch controls, survival loop, wave combat, companions, crafting, objectives, onboarding tutorial, boss phase, and run completion states.
- `scripts/SaveManager.gd`
  - Persistent profile storage and session result application (`user://rift_profile.json`).
- `scripts/FeedbackBus.gd`
  - Audio/vibration/flash feedback hook layer for gameplay events.
- `assets/icon.svg`
  - Base app icon.
- `export_presets.cfg`
  - Android export preset with package ID `com.codemaxstudios.rift`.

## Design & Technical Blueprint Files

- `rift-master-concept-technical-ui-blueprint.svg`
  - Master visual blueprint sheet (sections, UI map, systems flow).
- `ANDROID_CHILD_TABLET_GAME_PLAN.md`
  - Product/gameplay plan for child-tablet optimization.
- `android_ui_state_config.json`
  - Machine-readable config for UI layout, input rules, survival/companion/mutation data.
- `RIFT_STATE_MACHINE.md`
  - Runtime state and transition map for implementation.

## Run Locally (Godot 4)

1. Open this folder in Godot 4.x.
2. Run `scenes/Main.tscn` (or press Play from project root).
3. On desktop:
   - Left-click + drag in left zone to move.
   - Left-click + drag in right zone to aim/fire.
   - Use hotbar buttons to switch to food/heavy weapon behaviors.

## Current Game Features

- Continuous wave combat with drone variants (drone, brute, spitter)
- Resource economy (`human_scrap`, `alien_crystals`, foods) and scavenge bursts
- Crafting loop with weapon recipes and level gates
- Companion behaviors:
  - Keeley Sonic Scream / Neuro-Toxic Wail
  - Annalize railgun support + loot bonus
- Daily-style objective tracker with XP rewards
- Leveling + progression stats + bestiary page tracking
- Main menu with profile summary and continue support
- Settings panel (difficulty, vibration/hit flash toggles, UI scale, high-contrast mode)
- First-run guided onboarding tutorial with replay toggle from settings
- Feedback hooks for event flash + vibration and future SFX assets
- Daily reward claim loop with profile streak tracking
- Auto-checkpoint continue snapshots during active runs
- Overlord Vex boss phase unlock after progression gates
- Victory/defeat flow with run summary panel
- Profile save/continue persistence via `user://rift_profile.json`

## Android Release

See `docs/ANDROID_RELEASE_GUIDE.md` for keystore setup, export steps, sharing APKs, and Play Store app bundle publishing.
Use `docs/PLAYTEST_MATRIX.md` as the final QA checklist before external tester rollout.
Use `docs/APK_QUICKSTART.md` for the fastest debug/release APK build commands.
GitHub Actions now auto-builds APK artifacts via `.github/workflows/android-apk.yml`.
