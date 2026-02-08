#!/bin/bash
set -e

echo "🔧 Starting DexGuide build..."

# Install Flutter if not available
if ! command -v flutter &> /dev/null; then
  echo "📦 Installing Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
  export PATH="$PATH:`pwd`/flutter/bin"
  flutter doctor -v
fi

cd pokemondb

echo "📝 Generating version.json..."
./scripts/generate_version.sh

echo "🚀 Building Flutter web..."
flutter pub get
flutter build web --release

echo "✅ Build complete!"
