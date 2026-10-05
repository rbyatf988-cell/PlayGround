#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
PROJECT_ROOT="$(/usr/bin/time -p pwd)"
if ! /usr/bin/time -p test -n "${CAPTURE_URL:-}"; then echo "Set CAPTURE_URL." >&2; exit 1; fi
if ! /usr/bin/time -p test -n "${CAPTURE_DIR:-}"; then echo "Set CAPTURE_DIR." >&2; exit 1; fi
if ! /usr/bin/time -p test -n "${RUNTIME_DIR:-}"; then echo "Set RUNTIME_DIR." >&2; exit 1; fi
/usr/bin/time -p mkdir -p "$CAPTURE_DIR"
/usr/bin/time -p bash -c 'root="$1"; dir="$2"; rroot=$(node -e "console.log(require(\"path\").resolve(process.argv[1]))" "$root"); rdir=$(node -e "console.log(require(\"path\").resolve(process.argv[1]))" "$dir"); if [ "$rdir" = "$rroot" ] || [[ "$rdir" == "$rroot/"* ]]; then echo "CAPTURE_DIR must be outside source." >&2; exit 1; fi' _ "$PROJECT_ROOT" "$CAPTURE_DIR"
/usr/bin/time -p node "${RUNTIME_DIR}/scripts/default-capture.mjs"
/usr/bin/time -p test -f "$CAPTURE_DIR/final-desktop.png"
/usr/bin/time -p test -f "$CAPTURE_DIR/final-mobile.png"
/usr/bin/time -p bash -c 'for f in "$1/final-desktop.png" "$1/final-mobile.png"; do s=$(wc -c < "$f"); if [ "$s" -lt 24 ]; then echo "Capture missing PNG: $f" >&2; exit 1; fi; sig=$(head -c 8 "$f" | od -An -tx1 | tr -d " \n"); if [ "$sig" != "89504e470d0a1a0a" ]; then echo "Capture did not produce a PNG: $f" >&2; exit 1; fi; done' _ "$CAPTURE_DIR"
/usr/bin/time -p ls -l "$CAPTURE_DIR/final-desktop.png" "$CAPTURE_DIR/final-mobile.png"
