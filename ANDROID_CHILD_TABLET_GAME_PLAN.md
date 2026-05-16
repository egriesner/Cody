# RIFT: Android Child-Tablet Game Plan

This document turns the master artwork into a build-ready mobile game blueprint for an Android tablet used by kids.

## 1) Product Direction

- **Game:** RIFT: The Bestiary Protocol
- **Audience:** Kids (roughly 7-12)
- **Platform:** Android tablets (multi-touch, landscape-first)
- **Feel:** Fast, colorful, readable, low-friction controls, short satisfying wins
- **Design goal:** Very engaging and replayable without frustrating controls or heavy text

## 2) Core Engagement Formula (Fun + Repeat Play)

Use short loops and constant positive feedback:

1. **Explore**
   - Move through biomes with hidden pickups and quick surprises.
2. **Collect**
   - Gather Scrap, Crystals, and food quickly (frequent rewards every 10-20 seconds).
3. **Craft/Upgrade**
   - Unlock visible power jumps early and often.
4. **Battle Burst**
   - Short combat bursts with clear hit feedback and forgiving aim assist.
5. **Transform/Companion Moment**
   - Periodic "wow" events (Rhino Charge, Sonic Scream, railgun shots).
6. **Meta Progress**
   - Bestiary pages, cosmetics, and permanent upgrades to trigger next session.

### Kid-Friendly Retention Drivers

- Daily objective sets with simple verbs: "Find 3 pages", "Craft 1 item", "Use Rhino Charge once".
- Large visual rewards (stickers, skins, animated badges), not text-heavy rewards.
- Session target: **6-12 minutes** average, with optional extension.
- Frequent mini-victories so failure never feels harsh.

## 3) Tablet Control & UX Rules

Derived from the artwork and optimized for child hand size:

- Keep game in **landscape**.
- Ignore accidental palm touches near side edges:
  - Left dead-zone: `100px`
  - Right dead-zone: `100px`
- **Left thumb:** movement joystick (dynamic spawn in allowed area).
- **Right thumb:** drag-to-aim joystick + quick-tap auto-fire.
- **Bottom center:** 5-slot hotbar with high-contrast icons.
- Minimum touch target size: **64dp**, preferred **72-88dp** for major actions.
- Always show action labels for transformed buttons (example: `EAT`, `RAMMING SPEED`).

## 4) State-Driven Combat/Survival Rules

### Survival

- **Health** and **Hunger (Energy)** are always visible.
- If Hunger reaches zero:
  - Enter `EXHAUSTED` state.
  - Reduce move speed and sprint capability.
  - Use clear icon + short tooltip (no long sentence prompts).

### Hotbar Context Morph

- If selected item is heavy weapon:
  - Apply movement speed penalty.
  - Update walk animation tempo.
- If selected item is food:
  - Replace right attack action with `EAT`.
  - On consume, restore Hunger and play satisfying VFX/audio ping.

### Rhino Charge (Temporary Mutation)

- Triggered pickup/ability event enters `RHINO_CHARGE`.
- Duration: `6.0s`.
- UI override:
  - Hide hotbar.
  - Replace right combat joystick with single boost action: `RAMMING SPEED`.
- During charge:
  - Smash drone lines.
  - Break secret walls.
  - Reduce incoming interruption for "power fantasy" feel.

## 5) Companion Protocol Implementation

### Keeley (Tech Scout)

- Passive support and crowd utility.
- Auto-trigger **Sonic Scream** when enemies within radius >= 5.
- Upgrade branch enables **Neuro-Toxic Wail**:
  - Same trigger.
  - Adds poison damage-over-time.

### Annalize (Master Engineer)

- Heavy support attacker.
- Grants passive `+30%` loot modifier.
- Unlocks high-tier `Quantum Forge` crafting options.
- Signature burst weapon: Vex-Shatterer railgun (line pierce).

## 6) Bestiary and Endgame Progression

Main quest progression loop:

1. Find hidden holographic pages.
2. Fill Bestiary entries.
3. Unlock `SUPER_BEAST` form only in Overlord arena.
4. Defeat Overlord Vex.
5. Collect Alpha Strain DNA.
6. Become Rift Weaver and complete rapid-tap rift channel sequence.

## 7) Child-Tablet Quality Guardrails

- No tiny text in gameplay-critical UI.
- No mandatory precision swipes for core progression.
- No punishment spirals after a single loss.
- Keep loading transitions short and visually informative.
- Use color + icon pairing for key statuses (never color-only communication).

## 8) Implementation Order (Cursor-Friendly)

1. Build input layer with dead-zones, dual sticks, and hotbar.
2. Implement player state machine (`NORMAL`, `EXHAUSTED`, `RHINO_CHARGE`).
3. Add contextual action morphing (`ATTACK` <-> `EAT` <-> `RAMMING SPEED`).
4. Add companion controller with trigger hooks and upgrade variants.
5. Add survival/crafting economy and quest progression.
6. Add Bestiary gates and final Overlord/Rift Weaver flow.
