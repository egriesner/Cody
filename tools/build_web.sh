#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build"
WEB_DIR="$BUILD_ROOT/web"
MODE="${1:-release}"
GODOT_BIN="${GODOT_BIN:-godot4}"
PRESET_NAME="${PRESET_NAME:-Web}"

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

mkdir -p "$WEB_DIR"
OUTPUT_PATH="$WEB_DIR/index.html"
ZIP_PATH="$BUILD_ROOT/rift-bestiary-protocol-web-${MODE}.zip"

case "$MODE" in
  debug)
    EXPORT_CMD=(--headless --path "$PROJECT_ROOT" --export-debug "$PRESET_NAME" "$OUTPUT_PATH")
    ;;
  release)
    EXPORT_CMD=(--headless --path "$PROJECT_ROOT" --export-release "$PRESET_NAME" "$OUTPUT_PATH")
    ;;
  *)
    echo "Usage: $0 [debug|release]"
    exit 1
    ;;
esac

echo "Building Web bundle in $MODE mode using preset '$PRESET_NAME'..."
"$GODOT_BIN" "${EXPORT_CMD[@]}"

[[ -f "$OUTPUT_PATH" ]] || {
  echo "Error: Web export missing expected file $OUTPUT_PATH" >&2
  exit 1
}

if command -v zip >/dev/null 2>&1; then
  rm -f "$ZIP_PATH"
  (
    cd "$WEB_DIR"
    zip -rq "$ZIP_PATH" .
  )
fi

echo
echo "Web bundle created:"
echo "  $OUTPUT_PATH"
if [[ -f "$ZIP_PATH" ]]; then
  echo "Zip package:"
  echo "  $ZIP_PATH"
fi
echo
echo "Local test command:"
echo "  python3 -m http.server --directory \"$WEB_DIR\" 8060"
echo "Then open http://localhost:8060 in a browser."
