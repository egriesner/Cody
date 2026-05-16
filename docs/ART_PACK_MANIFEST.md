# RIFT Art Pack Manifest (Concept-Derived)

This pack is generated from the original concept board style (neon cyan + violet, high-tech fantasy silhouette, child-friendly readability).

## Included files

- `assets/artpack/skins/player_cody.svg`
- `assets/artpack/enemies/drone.svg`
- `assets/artpack/enemies/brute.svg`
- `assets/artpack/enemies/spitter.svg`
- `assets/artpack/enemies/boss_overlord_vex.svg`
- `assets/artpack/backgrounds/biome_scrap_dunes.svg`
- `assets/artpack/backgrounds/biome_whispering_archives.svg`
- `assets/artpack/backgrounds/biome_plasma_crater.svg`
- `assets/artpack/companions/keeley_portrait.svg`
- `assets/artpack/companions/annalize_portrait.svg`
- `assets/artpack/icons/pulse_tool.svg`
- `assets/artpack/icons/titan_hammer.svg`
- `assets/artpack/icons/glow_berry.svg`
- `assets/artpack/icons/arc_blaster.svg`
- `assets/artpack/icons/med_snack.svg`
- `assets/artpack/ui/hud_top_panel.svg`
- `assets/artpack/ui/hud_bottom_panel.svg`
- `assets/artpack/ui/button_primary.svg`
- `assets/artpack/ui/button_secondary.svg`
- `assets/artpack/ui/companion_frame.svg`
- `assets/artpack/ui/joystick_move_base.svg`
- `assets/artpack/ui/joystick_move_knob.svg`
- `assets/artpack/ui/joystick_aim_base.svg`
- `assets/artpack/ui/joystick_aim_knob.svg`

## Runtime integration

`scripts/GameRuntime.gd` now loads these assets by default and maps:

- `drone` -> `drone.svg`
- `brute` -> `brute.svg`
- `spitter` -> `spitter.svg`
- `boss` -> `boss_overlord_vex.svg`
- biome index 0/1/2 -> scrap dunes / whispering archives / plasma crater backgrounds
- companion state -> Keeley/Annalize portrait panel
- hotbar slots -> icon textures for tool/hammer/food/blaster/med snack
- HUD panels, joystick pads, and primary/secondary buttons -> dedicated UI skin textures

## Notes

- These are starter production-style vector assets and are intended as a skin pack baseline.
- You can replace any SVG with higher fidelity art using the same filenames to preserve integration.
