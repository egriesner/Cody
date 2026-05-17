# Release Candidate Checklist (Code Maxx Studios)

Use this checklist immediately before promoting a build to Google Play production.

## Build + Signing

- [ ] `./tools/preflight_release_check.sh` passes with no warnings.
- [ ] Release keystore path/alias/password validated.
- [ ] New version code + version name set for this release.
- [ ] Signed AAB generated successfully.

## Device QA (physical tablets)

- [ ] 8-inch tablet: no blocking UI overlaps, no soft locks.
- [ ] 10-11 inch tablet: HUD spacing and touch targets still comfortable.
- [ ] Lower-end tablet: stable gameplay in `performance_mode=performance`.
- [ ] Mid/high tablet: visual quality validated in `quality` mode.
- [ ] Internal test report completed using `docs/INTERNAL_TEST_REPORT_TEMPLATE.md`.

## Core Gameplay Validation

- [ ] New run, continue run, pause/resume, save-and-return all work.
- [ ] Dash, combo, and projectile mechanics behave correctly.
- [ ] Boss phase transition and run end states (victory/defeat) verified.
- [ ] Difficulty presets feel distinct and fair.

## Audio + Visual Validation

- [ ] Master/music/SFX sliders apply correctly and persist.
- [ ] No clipping or harsh distortion on tablet speakers.
- [ ] VFX readable and not obstructing controls/HUD.
- [ ] Optional perf HUD toggle works and can remain disabled for release.

## Store Metadata + Policy

- [ ] Play listing text finalized from `docs/PLAY_STORE_LISTING_TEMPLATE.md`.
- [ ] Privacy policy published at live URL (based on template).
- [ ] Data Safety form completed and reviewed.
- [ ] Content rating + target audience configuration completed.
- [ ] Screenshots + feature graphic + icon set uploaded and correct.

## Release Rollout

- [ ] Internal test track upload validated.
- [ ] Closed test feedback reviewed and regressions fixed.
- [ ] Production rollout plan defined (staged rollout recommended).
