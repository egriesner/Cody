#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

GODOT_BIN="${GODOT_BIN:-godot4}"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  if command -v godot >/dev/null 2>&1; then
    GODOT_BIN="godot"
  else
    echo "[smoke] Missing Godot binary (godot4/godot)." >&2
    exit 1
  fi
fi

echo "[smoke] validating JSON config..."
python3 -m json.tool "android_ui_state_config.json" >/dev/null

echo "[smoke] checking key scripts and docs exist..."
required_paths=(
  "scripts/Main.gd"
  "scripts/GameRuntime.gd"
  "scripts/SaveManager.gd"
  "scripts/Telemetry.gd"
  "tools/smoke_probe.gd"
  "tools/preflight_release_check.sh"
  "docs/QA_SMOKE_CHECKLIST_2_0.md"
)
for p in "${required_paths[@]}"; do
  [[ -f "$p" ]] || { echo "[smoke] missing: $p" >&2; exit 1; }
done

echo "[smoke] running Godot scene/resource probe..."
"$GODOT_BIN" --headless --path "$PROJECT_ROOT" --script "res://tools/smoke_probe.gd"

echo "[smoke] running release preflight..."
./tools/preflight_release_check.sh

echo "[smoke] completed successfully."
