#!/bin/bash
# Generate version.json with build metadata

# Get git info
GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
GIT_COMMIT_SHORT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Get version from pubspec.yaml
VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' || echo "0.0.0")

# Create version.json
cat > web/version.json << EOF
{
  "version": "$VERSION",
  "gitCommit": "$GIT_COMMIT",
  "gitCommitShort": "$GIT_COMMIT_SHORT",
  "gitBranch": "$GIT_BRANCH",
  "buildTime": "$BUILD_TIME",
  "buildEnvironment": "${CF_PAGES_BRANCH:-local}"
}
EOF

echo "Generated version.json:"
cat web/version.json
