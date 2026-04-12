#!/usr/bin/env bash
set -euo pipefail

LAMBDA_ROOT="${1:-}"
if [[ -z "$LAMBDA_ROOT" ]]; then
  echo "Usage: sync_dependencies.sh <python_lambda_functions_path>" >&2
  exit 1
fi

if [[ ! -f "$LAMBDA_ROOT/requirements.txt" ]]; then
  echo "requirements.txt not found in $LAMBDA_ROOT" >&2
  exit 1
fi

LOCK_DIR="$LAMBDA_ROOT/.dependencies.lock"
for _ in $(seq 1 120); do
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    break
  fi
  sleep 1
done

if [[ ! -d "$LOCK_DIR" ]]; then
  echo "Failed to acquire dependency sync lock at $LOCK_DIR" >&2
  exit 1
fi

cleanup() {
  rm -rf "$LOCK_DIR"
}
trap cleanup EXIT

PY_BIN="python3"
if ! command -v "$PY_BIN" >/dev/null 2>&1; then
  PY_BIN="python"
fi

if ! command -v "$PY_BIN" >/dev/null 2>&1; then
  echo "No Python interpreter found (python3/python)." >&2
  exit 1
fi

if command -v md5 >/dev/null 2>&1; then
  REQ_HASH="$(md5 -q "$LAMBDA_ROOT/requirements.txt")"
else
  REQ_HASH="$(md5sum "$LAMBDA_ROOT/requirements.txt" | awk '{print $1}')"
fi

HASH_FILE="$LAMBDA_ROOT/.dependencies/.requirements.hash"
if [[ -f "$HASH_FILE" ]] && [[ "$(cat "$HASH_FILE")" == "$REQ_HASH" ]]; then
  echo "Dependencies already up to date in $LAMBDA_ROOT/.dependencies"
  exit 0
fi

TMP_DIR="$LAMBDA_ROOT/.dependencies.tmp"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
"$PY_BIN" -m pip install --upgrade --target "$TMP_DIR" -r "$LAMBDA_ROOT/requirements.txt"

echo "$REQ_HASH" > "$TMP_DIR/.requirements.hash"
rm -rf "$LAMBDA_ROOT/.dependencies"
mv "$TMP_DIR" "$LAMBDA_ROOT/.dependencies"

echo "Synced Lambda dependencies into $LAMBDA_ROOT/.dependencies"
