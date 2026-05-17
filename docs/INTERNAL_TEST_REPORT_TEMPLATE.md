# Internal Test Report Template (RIFT)

Use this report for each release candidate tested on internal or closed tracks.

## Build Metadata

- Build tag / commit:
- Version name:
- Version code:
- Build date:
- Track tested (`internal` / `alpha` / `beta`):

## Device Matrix

| Device | Android Version | Performance Mode | Result | Notes |
|---|---|---|---|---|
| 8-inch Tablet |  |  |  |  |
| 10-11 inch Tablet |  |  |  |  |
| Low-memory device |  |  |  |  |

## Core Flow Results

- [ ] Launch -> Main Menu -> New Run
- [ ] Continue Run restore
- [ ] Pause/Resume + Save & Return
- [ ] Boss transition + victory flow
- [ ] Defeat flow + retry

## Mechanics Validation

- [ ] Dash behavior + cooldown + evade timing
- [ ] Combo multiplier behavior and reset
- [ ] Enemy projectile behavior (spawn/hit/despawn)
- [ ] Difficulty presets feel distinct (easy/normal/hard)

## UX and Accessibility

- [ ] Touch controls accurate on all tested devices
- [ ] UI scale options applied correctly
- [ ] High contrast mode readability verified
- [ ] Optional perf HUD output sane when enabled

## Audio/Visual

- [ ] Master/music/SFX sliders persist and apply
- [ ] Audio mix has no clipping on tablet speakers
- [ ] VFX readable and not obscuring gameplay

## Performance Summary

- Typical FPS range:
- Worst-case FPS during heavy combat:
- Max enemies observed:
- Max projectiles observed:
- Max VFX particles observed:
- Thermal/performance notes:

## Bugs Found

| ID | Severity | Area | Repro Steps | Status |
|---|---|---|---|---|
|  |  |  |  |  |

## Release Recommendation

- [ ] Pass: promote to next track
- [ ] Blocked: requires fixes before promotion

Decision notes:
