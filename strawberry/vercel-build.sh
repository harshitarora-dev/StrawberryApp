#!/bin/bash
set -e

echo "=== Installing Flutter SDK ==="
if [ ! -d "flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
else
  echo "Flutter directory already exists, skipping clone."
fi

export PATH="$PATH:$(pwd)/flutter/bin"

echo "=== Flutter Version ==="
flutter --version

echo "=== Enabling Web ==="
flutter config --enable-web

echo "=== Installing Dependencies ==="
flutter pub get

echo "=== Building Flutter Web for Release ==="
flutter build web --release --base-href /

echo "=== Build Completed Successfully ==="
