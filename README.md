# Cody

RIFT project assets and a runnable Godot starter game for Android tablet deployment.

Developer/Studio: **Code Max Studios**

## Project Layout

- `project.godot`
  - Godot project entry point.
- `scenes/Main.tscn`
  - Main playable scene.
- `scripts/Main.gd`
  - Runtime logic for touch controls, state machine hooks, survival, hotbar context switching, companion triggers, enemy waves, crafting, objectives, and save/load.
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

## Current Prototype Features (Phase 2)

- Continuous wave combat with drone variants (drone, brute, spitter)
- Resource economy (`human_scrap`, `alien_crystals`, foods) and scavenge bursts
- Crafting loop with weapon recipes and level gates
- Companion behaviors:
  - Keeley Sonic Scream / Neuro-Toxic Wail
  - Annalize railgun support + loot bonus
- Daily-style objective tracker with XP rewards
- Leveling + progression stats + bestiary page tracking
- Save/Load to `user://rift_save.json`

## Android Release

See `docs/ANDROID_RELEASE_GUIDE.md` for keystore setup, export steps, sharing APKs, and Play Store app bundle publishing.
