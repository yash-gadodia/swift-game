#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
APP_BUNDLE_ID="${APP_BUNDLE_ID:-com.voltade.swiftgame}"
SCHEME="${SCHEME:-SwiftGame}"
BACKEND_PORT="${BACKEND_PORT:-8081}"
SIM_A_NAME="${SIM_A_NAME:-iPhone 17}"
SIM_B_NAME="${SIM_B_NAME:-iPhone 17 Pro}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$HOME/Library/Developer/Xcode/DerivedData/SwiftGame-DevScript}"
LOG_DIR="$ROOT_DIR/.build/logs"
BACKEND_LOG="$LOG_DIR/backend.log"
BUILD_LOG="$LOG_DIR/xcodebuild.log"

mkdir -p "$LOG_DIR"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing command: $1"
    exit 1
  fi
}

require_cmd node
require_cmd xcodebuild
require_cmd xcrun

if ! xcrun simctl help >/dev/null 2>&1; then
  if [[ -d "/Applications/Xcode.app/Contents/Developer" ]]; then
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
  fi
fi

if ! xcrun simctl help >/dev/null 2>&1; then
  echo "simctl unavailable. Set Xcode tools path first:"
  echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  echo "Or launch Xcode once and accept any first-run prompts."
  exit 1
fi

boot_simulator() {
  local name="$1"
  local udid
  udid="$(xcrun simctl list devices available | grep -F "$name (" | head -n1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')"
  if [[ -z "$udid" ]]; then
    echo "Simulator not found: $name"
    exit 1
  fi

  xcrun simctl boot "$udid" >/dev/null 2>&1 || true
  echo "$udid"
}

echo "[1/5] Starting backend on :$BACKEND_PORT"
EXISTING_PID="$(lsof -t -iTCP:"$BACKEND_PORT" -sTCP:LISTEN | head -n1 || true)"
if [[ -n "${EXISTING_PID:-}" ]]; then
  EXISTING_CMD="$(ps -p "$EXISTING_PID" -o command= || true)"
  if [[ "$EXISTING_CMD" == *"node"* ]]; then
    echo "Port :$BACKEND_PORT in use by PID $EXISTING_PID. Stopping stale node backend."
    kill "$EXISTING_PID" >/dev/null 2>&1 || true
    sleep 1
  else
    echo "Port :$BACKEND_PORT is in use by non-node process:"
    echo "  PID $EXISTING_PID -> $EXISTING_CMD"
    echo "Free the port or change BACKEND_PORT."
    exit 1
  fi
fi

(
  cd "$BACKEND_DIR"
  PORT="$BACKEND_PORT" node --watch src/server.js
) >"$BACKEND_LOG" 2>&1 &
BACKEND_PID=$!

cleanup() {
  if ps -p "$BACKEND_PID" >/dev/null 2>&1; then
    kill "$BACKEND_PID" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

sleep 1
if ! curl -fsS "http://127.0.0.1:$BACKEND_PORT/health" >/dev/null; then
  echo "Backend health check failed. See: $BACKEND_LOG"
  exit 1
fi

echo "[2/5] Booting simulators: $SIM_A_NAME + $SIM_B_NAME"
SIM_A_UDID="$(boot_simulator "$SIM_A_NAME")"
SIM_B_UDID="$(boot_simulator "$SIM_B_NAME")"
open -a Simulator >/dev/null 2>&1 || true

echo "[3/5] Building app once"
cd "$ROOT_DIR"
xcodebuild \
  -project SwiftGame.xcodeproj \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIM_A_UDID" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  build >"$BUILD_LOG" 2>&1 || {
    echo "Build failed. Last 120 lines:"
    tail -n 120 "$BUILD_LOG" || true
    exit 1
  }

APP_PATH="$(find "$DERIVED_DATA_PATH/Build/Products/Debug-iphonesimulator" -name "SwiftGame.app" | head -n1)"
if [[ -z "$APP_PATH" ]]; then
  echo "Built app not found in DerivedData"
  exit 1
fi

echo "[4/5] Installing app on both simulators"
xcrun simctl install "$SIM_A_UDID" "$APP_PATH"
xcrun simctl install "$SIM_B_UDID" "$APP_PATH"

echo "[5/5] Launching app on both simulators"
xcrun simctl launch "$SIM_A_UDID" "$APP_BUNDLE_ID" >/dev/null
xcrun simctl launch "$SIM_B_UDID" "$APP_BUNDLE_ID" >/dev/null

echo
echo "Ready."
echo "Backend: http://127.0.0.1:$BACKEND_PORT"
echo "Simulator A: $SIM_A_NAME ($SIM_A_UDID)"
echo "Simulator B: $SIM_B_NAME ($SIM_B_UDID)"
echo "App Bundle: $APP_BUNDLE_ID"
echo "Backend log: $BACKEND_LOG"
echo
echo "Keep this terminal open while testing. Press Ctrl+C to stop backend."

wait "$BACKEND_PID"
