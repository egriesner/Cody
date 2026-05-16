#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
MODE="${1:-debug}"
PACKAGE_FORMAT="${2:-apk}"
GODOT_BIN="${GODOT_BIN:-godot4}"
INSTALL_ANDROID_BUILD_TEMPLATE="${INSTALL_ANDROID_BUILD_TEMPLATE:-0}"

if [[ -z "${PRESET_NAME:-}" ]]; then
  if [[ "$PACKAGE_FORMAT" == "aab" ]]; then
    PRESET_NAME="Android AAB"
  else
    PRESET_NAME="Android"
  fi
fi

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
    if [[ "$PACKAGE_FORMAT" == "aab" ]]; then
      echo "Error: AAB exports should use release mode. Use: ./tools/build_apk.sh release aab"
      exit 1
    fi
    OUTPUT_PATH="$BUILD_DIR/rift-bestiary-protocol-debug.apk"
    EXPORT_CMD=(--headless --path "$PROJECT_ROOT" --export-debug "$PRESET_NAME" "$OUTPUT_PATH")
    ;;
  release)
    if [[ "$PACKAGE_FORMAT" == "aab" ]]; then
      OUTPUT_PATH="$BUILD_DIR/rift-bestiary-protocol-release.aab"
    else
      OUTPUT_PATH="$BUILD_DIR/rift-bestiary-protocol-release.apk"
    fi
    EXPORT_CMD=(--headless --path "$PROJECT_ROOT" --export-release "$PRESET_NAME" "$OUTPUT_PATH")
    ;;
  *)
    echo "Usage: $0 [debug|release] [apk|aab]"
    exit 1
    ;;
esac

EXTRA_ARGS=()
if [[ "$INSTALL_ANDROID_BUILD_TEMPLATE" == "1" ]]; then
  EXTRA_ARGS+=(--install-android-build-template)
fi

if [[ "$PACKAGE_FORMAT" != "apk" && "$PACKAGE_FORMAT" != "aab" ]]; then
  echo "Error: package format must be apk or aab."
  exit 1
fi

echo "Building $PACKAGE_FORMAT in $MODE mode using preset '$PRESET_NAME'..."
"$GODOT_BIN" "${EXPORT_CMD[@]}" "${EXTRA_ARGS[@]}"

echo
echo "Package created:"
echo "  $OUTPUT_PATH"
echo
if [[ "$PACKAGE_FORMAT" == "apk" ]]; then
  echo "Install on connected Android device:"
  echo "  adb install -r \"$OUTPUT_PATH\""
else
  echo "Upload this .aab to Google Play Console (Internal testing track first)."
fi
