# RIFT Runtime State Machine (Android Tablet)

This state map aligns the artwork, the master SVG, and `android_ui_state_config.json`.

## 1) Player Core States

### `NORMAL`

- Default exploration/combat state.
- Active UI:
  - Left movement stick
  - Right aim/attack stick
  - 5-slot hotbar
- Can transition to:
  - `EXHAUSTED` when Hunger == 0
  - `RHINO_CHARGE` on mutation trigger
  - `SUPER_BEAST` only in Overlord arena and after Bestiary condition

### `EXHAUSTED`

- Enter condition: Hunger reaches 0.
- Effects:
  - Movement speed reduction
  - Sprint disabled
- Exit condition:
  - Hunger restored above threshold

### `RHINO_CHARGE`

- Enter condition: Rhino mutation trigger.
- Fixed duration: 6 seconds.
- UI overrides:
  - Hide hotbar
  - Replace right joystick with `RAMMING SPEED` button
- Gameplay overrides:
  - Collision damage boost
  - Secret wall break enabled
- Exit condition:
  - Timer expires -> return to `NORMAL` or `EXHAUSTED` based on Hunger

### `SUPER_BEAST`

- Locked behind:
  - Titan Protocol completion gate
  - Current map == Overlord arena
- Exit condition:
  - Arena phase end

### `RIFT_WEAVER`

- Final boss progression state after Alpha Strain extraction.
- Enables rapid-tap channeling minigame to open final rift.

## 2) Input Mode Substates

Input mode updates independently from locomotion states but must respect state locks.

### `ATTACK_MODE`

- Default right-side action while weapon/tool selected.

### `EAT_MODE`

- Enter when hotbar selected item has tag `food`.
- Right-side control morphs into button labeled `EAT`.
- Exit when selected item not `food`.

### `RHINO_BOOST_MODE`

- Forced while in `RHINO_CHARGE`.
- Blocks other right-side combat actions.

## 3) Companion Trigger States

## Keeley

### `KEELEY_IDLE`

- Monitoring nearby threat density.

### `KEELEY_SONIC_SCREAM`

- Trigger: enemies in radius >= 5.
- Emits fear/dispersion wave.

### `KEELEY_NEURO_TOXIC_WAIL`

- Upgrade variant of sonic scream.
- Adds poison damage-over-time.

## Annalize

### `ANNALIZE_PASSIVE_BUFF`

- Always applies loot multiplier while active companion.

### `ANNALIZE_RAILGUN_BURST`

- Triggered heavy support attack.

## 4) Quest/Meta Progression States

### `TITAN_PROTOCOL_ACTIVE`

- Collect hidden pages and complete Bestiary entries.

### `OVERLORD_FIGHT_UNLOCKED`

- Requirements met for final arena access.

### `ALPHA_STRAIN_ACQUIRED`

- Drops after Overlord defeat.

### `FINAL_RIFT_CHANNEL`

- Rapid tap sequence to complete narrative closure.

## 5) Transition Rules (Pseudo-Code)

```text
if hunger <= 0 and playerState != RHINO_CHARGE:
    playerState = EXHAUSTED

if rhinoTrigger and playerState in [NORMAL, EXHAUSTED]:
    playerState = RHINO_CHARGE
    inputMode = RHINO_BOOST_MODE
    setTimer(6.0)

if playerState == RHINO_CHARGE and timerExpired:
    playerState = EXHAUSTED if hunger <= 0 else NORMAL
    inputMode = EAT_MODE if selectedItemTag == food else ATTACK_MODE

if selectedItemTag == food and playerState != RHINO_CHARGE:
    inputMode = EAT_MODE
else if playerState != RHINO_CHARGE:
    inputMode = ATTACK_MODE

if isOverlordArena and bestiaryComplete:
    unlockState(SUPER_BEAST)
```

## 6) Child-Tablet Gameplay Safety Rules

- Avoid precision-required fail states in mandatory objectives.
- Keep all required actions reachable with two-thumb grip.
- Never hide essential state feedback (Health/Hunger must remain readable).
