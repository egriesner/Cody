#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
PRESET_NAME="${PRESET_NAME:-Android}"
MODE="${1:-debug}"
GODOT_BIN="${GODOT_BIN:-godot4}"
INSTALL_ANDROID_BUILD_TEMPLATE="${INSTALL_ANDROID_BUILD_TEMPLATE:-0}"

if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
  if command -v godot >/dev/null 2>&1; then
    GODOT_BIN="godot"
  else
    echo "Error: Godot binary not found. Install Godot 4 and ensure 'godot4' or 'godot' is in PATH."
    exit 1
  fi
fi

if [[ ! -f "$PROJECT_ROOT/project.godot" ]]; then
  echo "Error: project.godot not found at $PROJECT_ROOT"
  exit 1
fi

mkdir -p "$BUILD_DIR"

case "$MODE" in
  debug)
    OUTPUT_PATH="$BUILD_DIR/rift-bestiary-protocol-debug.apk"
    EXPORT_CMD=(--headless --path "$PROJECT_ROOT" --export-debug "$PRESET_NAME" "$OUTPUT_PATH")
    ;;
  release)
    OUTPUT_PATH="$BUILD_DIR/rift-bestiary-protocol-release.apk"
    EXPORT_CMD=(--headless --path "$PROJECT_ROOT" --export-release "$PRESET_NAME" "$OUTPUT_PATH")
    ;;
  *)
    echo "Usage: $0 [debug|release]"
    exit 1
    ;;
esac

EXTRA_ARGS=()
if [[ "$INSTALL_ANDROID_BUILD_TEMPLATE" == "1" ]]; then
  EXTRA_ARGS+=(--install-android-build-template)
fi

echo "Building APK in $MODE mode using preset '$PRESET_NAME'..."
"$GODOT_BIN" "${EXPORT_CMD[@]}" "${EXTRA_ARGS[@]}"

echo
echo "APK created:"
echo "  $OUTPUT_PATH"
echo
echo "Install on connected Android device:"
echo "  adb install -r \"$OUTPUT_PATH\""
