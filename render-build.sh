#!/usr/bin/env bash
# Builds the BorrowIT web app on Render.
# Render doesn't have Flutter installed, so this downloads it first.
set -euo pipefail

FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"
FLUTTER_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/flutter-sdk"

if [ -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "==> Updating cached Flutter SDK ($FLUTTER_CHANNEL)"
  git -C "$FLUTTER_DIR" fetch --depth 1 origin "$FLUTTER_CHANNEL"
  git -C "$FLUTTER_DIR" reset --hard FETCH_HEAD
else
  echo "==> Downloading Flutter SDK ($FLUTTER_CHANNEL)"
  rm -rf "$FLUTTER_DIR"
  mkdir -p "$(dirname "$FLUTTER_DIR")"
  git clone --depth 1 --branch "$FLUTTER_CHANNEL" \
    https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter config --no-analytics >/dev/null 2>&1 || true
flutter --version

echo "==> Getting packages"
flutter pub get

echo "==> Building web app"
flutter build web --release

echo "==> Done. Output is in build/web"
