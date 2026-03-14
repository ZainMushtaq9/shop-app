#!/usr/bin/env bash
# Exit on error
set -e

echo "Starting Render build for Flutter Web App..."

# 1. Download Flutter SDK if not already cached
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK (stable branch)..."
  git clone https://github.com/flutter/flutter.git -b stable
fi

# 2. Add Flutter commands to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# 3. Enable Web support and get dependencies
echo "Enabling Flutter Web..."
flutter config --enable-web

echo "Getting packages..."
flutter pub get

# 4. Build the web app
echo "Building Flutter Web application..."
flutter build web --release --web-renderer html

echo "Build complete! Output is in build/web"
