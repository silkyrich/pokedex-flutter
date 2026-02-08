#!/bin/bash
set -e

echo "🔧 Starting DexGuide build..."
cd pokemondb

echo "📝 Generating version.json..."
./scripts/generate_version.sh

echo "🚀 Building Flutter web..."
flutter build web --release

echo "✅ Build complete!"
