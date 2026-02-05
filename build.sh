#!/bin/bash
set -e

echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

echo "Accepting Flutter licenses..."
flutter doctor -v

echo "Building Flutter web app..."
cd pokemondb
flutter pub get
flutter build web --release

echo "Build complete!"
