# RIFT Playtest Matrix (Pre-Store)

Use this matrix before external tester distribution.

## Device Coverage

- 8-inch Android tablet (mid-tier)
- 10-11 inch Android tablet (mid/high-tier)
- Low-memory Android tablet profile (background apps open)

## Core Flows

1. Launch -> Main Menu -> New Run
2. Launch -> Continue Run
3. Complete run with victory (Overlord Vex defeated)
4. End run by defeat (life depletion)
5. Pause -> Save & Return -> Continue
6. End panel -> Restart run
7. Claim daily reward -> close/reopen app -> claim lockout same day

## Control Validation

- Left/right dead-zone rejection on both tablet sizes.
- Dynamic left stick appears only in allowed zone.
- Right drag aim and quick tap behavior remain responsive.
- Dash button:
  - triggers burst movement immediately
  - enters cooldown and re-enables correctly
  - grants brief damage-evade window during active dash frames
- Hotbar context transitions:
  - weapon -> ATTACK
  - food -> EAT
  - Rhino state -> RAMMING SPEED

## UX / Kid-Friendliness

- Tutorial appears on first profile run.
- Tutorial skip and replay behavior works.
- Critical status labels remain readable during combat.
- Reward cadence feels frequent (no >45s without meaningful reward signal).

## Progression and Persistence

- Profile totals update after each run.
- Meta XP and level carry between sessions.
- Continue snapshot restores objectives/inventory correctly.
- Continue snapshot restores dash cooldown state correctly.
- Auto-checkpoint during active run updates continue data without manual save.
- Settings persistence:
  - difficulty
  - vibration
  - hit flash
  - UI scale
  - high contrast mode
  - volume value
  - difficulty-based enemy pressure scaling

## Stability Checks

- No soft lock after repeated pause/resume cycles.
- No UI panel overlap that blocks gameplay input unexpectedly.
- Boss phase transitions cleanly from wave phase.
- Restart-from-end-panel does not corrupt profile data.
- Spitter ranged projectiles spawn, despawn, and damage without stutter or leaked entities.
- Combo multiplier UI updates in combat and cleanly resets after timeout/taking damage.
- Easy/Normal/Hard each feel distinct:
  - Easy lowers incoming pressure and increases loot comfort.
  - Hard increases enemy pressure while preserving control responsiveness.
