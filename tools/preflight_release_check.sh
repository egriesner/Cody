#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "[preflight] validating json config..."
python3 -m json.tool "android_ui_state_config.json" >/dev/null

echo "[preflight] checking required release docs/files..."
required_files=(
  "docs/ANDROID_RELEASE_GUIDE.md"
  "docs/PLAYTEST_MATRIX.md"
  "docs/INTERNAL_TEST_REPORT_TEMPLATE.md"
  "docs/QA_SMOKE_CHECKLIST_2_0.md"
  "docs/PRODUCTION_LAUNCH_RUNBOOK_2_0.md"
  "docs/RELEASE_NOTES_2_0_0.md"
  "docs/PLAY_UPLOAD_HANDOFF.md"
  "docs/PLAY_STORE_LISTING_TEMPLATE.md"
  "docs/PRIVACY_POLICY_TEMPLATE.md"
  "docs/RELEASE_CANDIDATE_CHECKLIST.md"
  "docs/ART_PACK_MANIFEST.md"
  "export_presets.cfg"
  ".github/workflows/android-apk.yml"
  ".github/workflows/android-aab.yml"
  ".github/workflows/android-play-publish.yml"
  ".github/workflows/android-smoke.yml"
  ".github/workflows/android-release-candidate.yml"
  "tools/smoke_check.sh"
  "tools/release_orchestrator.sh"
  "scripts/Telemetry.gd"
)

for f in "${required_files[@]}"; do
  if [[ ! -f "$f" ]]; then
    echo "[preflight] missing required file: $f" >&2
    exit 1
  fi
done

echo "[preflight] checking package id and workflow variables..."
rg -q "com\\.codemaxstudios\\.rift" "export_presets.cfg" || {
  echo "[preflight] package id check failed in export_presets.cfg" >&2
  exit 1
}
rg -q "GOOGLE_PLAY_PACKAGE_NAME" ".github/workflows/android-play-publish.yml" || {
  echo "[preflight] GOOGLE_PLAY_PACKAGE_NAME missing in play publish workflow" >&2
  exit 1
}

echo "[preflight] checking art pack + audio assets..."
rg -q "assets/artpack" "docs/ART_PACK_MANIFEST.md" || {
  echo "[preflight] art pack manifest appears incomplete" >&2
  exit 1
}
for f in \
  "assets/audio/sfx/attack.wav" \
  "assets/audio/sfx/hit.wav" \
  "assets/audio/sfx/dash.wav" \
  "assets/audio/music/biome_scrap_dunes.wav" \
  "assets/audio/music/biome_whispering_archives.wav" \
  "assets/audio/music/biome_plasma_crater.wav"; do
  [[ -f "$f" ]] || {
    echo "[preflight] missing expected audio asset: $f" >&2
    exit 1
  }
done

echo "[preflight] checking workflow guardrails..."
rg -q "tools/smoke_check\\.sh" ".github/workflows/android-smoke.yml" || {
  echo "[preflight] android-smoke workflow missing smoke invocation" >&2
  exit 1
}
rg -q "tools/smoke_check\\.sh" ".github/workflows/android-apk.yml" || {
  echo "[preflight] android-apk workflow missing smoke invocation" >&2
  exit 1
}
rg -q "tools/smoke_check\\.sh" ".github/workflows/android-aab.yml" || {
  echo "[preflight] android-aab workflow missing smoke invocation" >&2
  exit 1
}
rg -q "tools/smoke_check\\.sh" ".github/workflows/android-play-publish.yml" || {
  echo "[preflight] android-play-publish workflow missing smoke invocation" >&2
  exit 1
}
rg -q "tools/release_orchestrator\\.sh" ".github/workflows/android-release-candidate.yml" || {
  echo "[preflight] android-release-candidate workflow missing orchestrator invocation" >&2
  exit 1
}

echo "[preflight] checking tool executability..."
[[ -x "tools/preflight_release_check.sh" ]] || {
  echo "[preflight] tools/preflight_release_check.sh is not executable" >&2
  exit 1
}
[[ -x "tools/smoke_check.sh" ]] || {
  echo "[preflight] tools/smoke_check.sh is not executable" >&2
  exit 1
}
[[ -x "tools/release_orchestrator.sh" ]] || {
  echo "[preflight] tools/release_orchestrator.sh is not executable" >&2
  exit 1
}

echo "[preflight] all checks passed."
