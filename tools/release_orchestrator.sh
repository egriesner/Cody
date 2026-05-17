#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
mkdir -p "$BUILD_DIR"

cd "$PROJECT_ROOT"

echo "[release] running smoke + preflight gates..."
./tools/smoke_check.sh

echo "[release] building release APK..."
./tools/build_apk.sh release

echo "[release] building release AAB..."
./tools/build_apk.sh release aab

APK_PATH="$BUILD_DIR/rift-bestiary-protocol-release.apk"
AAB_PATH="$BUILD_DIR/rift-bestiary-protocol-release.aab"

[[ -f "$APK_PATH" ]] || { echo "[release] missing APK: $APK_PATH" >&2; exit 1; }
[[ -f "$AAB_PATH" ]] || { echo "[release] missing AAB: $AAB_PATH" >&2; exit 1; }

VERSION="$(rg -No 'config/version=\"([^\"]+)\"' project.godot -r '$1' | head -n 1)"
if [[ -z "$VERSION" ]]; then
  VERSION="unknown"
fi

CHECKSUM_FILE="$BUILD_DIR/release-checksums-${VERSION}.txt"
MANIFEST_FILE="$BUILD_DIR/release-manifest-${VERSION}.json"
SUMMARY_FILE="$BUILD_DIR/release-summary-${VERSION}.md"

echo "[release] computing checksums..."
sha256sum "$APK_PATH" "$AAB_PATH" | tee "$CHECKSUM_FILE"

echo "[release] writing release manifest..."
python3 - "$APK_PATH" "$AAB_PATH" "$CHECKSUM_FILE" "$MANIFEST_FILE" "$VERSION" <<'PY'
import json
import os
import subprocess
import sys
from datetime import datetime, timezone

apk_path, aab_path, checksum_file, manifest_file, version = sys.argv[1:]

def sha_from_file(path: str) -> dict[str, str]:
    out = {}
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            sha, artifact = line.split("  ", 1)
            out[os.path.basename(artifact)] = sha
    return out

def git(cmd: list[str]) -> str:
    return subprocess.check_output(["git", *cmd], text=True).strip()

checksums = sha_from_file(checksum_file)
manifest = {
    "version": version,
    "generated_utc": datetime.now(timezone.utc).isoformat(),
    "git": {
        "commit": git(["rev-parse", "HEAD"]),
        "branch": git(["rev-parse", "--abbrev-ref", "HEAD"]),
    },
    "artifacts": [
        {
            "name": os.path.basename(apk_path),
            "path": apk_path,
            "size_bytes": os.path.getsize(apk_path),
            "sha256": checksums.get(os.path.basename(apk_path), ""),
        },
        {
            "name": os.path.basename(aab_path),
            "path": aab_path,
            "size_bytes": os.path.getsize(aab_path),
            "sha256": checksums.get(os.path.basename(aab_path), ""),
        },
    ],
}

with open(manifest_file, "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2)
    f.write("\n")
PY

echo "[release] writing markdown summary..."
{
  echo "# Release Summary ($VERSION)"
  echo
  echo "- Generated at: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo "- Branch: $(git rev-parse --abbrev-ref HEAD)"
  echo "- Commit: $(git rev-parse HEAD)"
  echo
  echo "## Artifacts"
  echo
  echo "- $APK_PATH"
  echo "- $AAB_PATH"
  echo
  echo "## Checksums"
  echo
  cat "$CHECKSUM_FILE"
} > "$SUMMARY_FILE"

echo "[release] complete."
echo "[release] checksum file: $CHECKSUM_FILE"
echo "[release] manifest file: $MANIFEST_FILE"
echo "[release] summary file: $SUMMARY_FILE"
