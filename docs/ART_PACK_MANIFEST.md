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

## Runtime integration

`scripts/GameRuntime.gd` now loads these assets by default and maps:

- `drone` -> `drone.svg`
- `brute` -> `brute.svg`
- `spitter` -> `spitter.svg`
- `boss` -> `boss_overlord_vex.svg`
- biome index 0/1/2 -> scrap dunes / whispering archives / plasma crater backgrounds

## Notes

- These are starter production-style vector assets and are intended as a skin pack baseline.
- You can replace any SVG with higher fidelity art using the same filenames to preserve integration.
