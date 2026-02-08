#!/bin/bash
# Quick script to verify deployment version

SITE_URL="${1:-https://dexguide.gg}"

echo "🔍 Checking deployment at $SITE_URL..."
echo ""

# Fetch version info
VERSION_JSON=$(curl -s "$SITE_URL/api/version")

if [ -z "$VERSION_JSON" ]; then
  echo "❌ Failed to fetch version info from $SITE_URL/api/version"
  exit 1
fi

# Extract key fields using jq if available, fallback to grep
if command -v jq &> /dev/null; then
  DEPLOYED_COMMIT=$(echo "$VERSION_JSON" | jq -r '.gitCommitShort // (.cfCommitSha // "unknown" | .[0:7])')
  DEPLOYED_VERSION=$(echo "$VERSION_JSON" | jq -r '.version // ""')
  DEPLOYED_TIME=$(echo "$VERSION_JSON" | jq -r '.buildTime // .deployedAt // ""')
  ENVIRONMENT=$(echo "$VERSION_JSON" | jq -r '.environment // ""')
else
  # Fallback to grep (less reliable)
  DEPLOYED_COMMIT=$(echo "$VERSION_JSON" | grep -o '"gitCommitShort":"[^"]*"' | cut -d'"' -f4)
  if [ -z "$DEPLOYED_COMMIT" ]; then
    DEPLOYED_COMMIT=$(echo "$VERSION_JSON" | grep -o '"cfCommitSha":"[^"]*"' | cut -d'"' -f4 | cut -c1-7)
  fi
  DEPLOYED_VERSION=$(echo "$VERSION_JSON" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
  DEPLOYED_TIME=$(echo "$VERSION_JSON" | grep -o '"buildTime":"[^"]*"' | cut -d'"' -f4)
  if [ -z "$DEPLOYED_TIME" ]; then
    DEPLOYED_TIME=$(echo "$VERSION_JSON" | grep -o '"deployedAt":"[^"]*"' | cut -d'"' -f4)
  fi
  ENVIRONMENT=$(echo "$VERSION_JSON" | grep -o '"environment":"[^"]*"' | cut -d'"' -f4)
fi

# Get local commit
LOCAL_COMMIT=$(git rev-parse --short HEAD 2>/dev/null)

echo "📦 Deployed Version:"
echo "   Version:     $DEPLOYED_VERSION"
echo "   Commit:      $DEPLOYED_COMMIT"
echo "   Built:       $DEPLOYED_TIME"
echo "   Environment: $ENVIRONMENT"
echo ""
echo "💻 Local:"
echo "   Commit:      $LOCAL_COMMIT"
echo ""

# Compare
if [ "$DEPLOYED_COMMIT" == "$LOCAL_COMMIT" ]; then
  echo "✅ Deployment is UP TO DATE with local"
else
  echo "⚠️  Deployment is DIFFERENT from local"
  echo "   Run 'git push' if you want to deploy $LOCAL_COMMIT"
fi

echo ""
echo "🔗 Full version info:"
echo "$VERSION_JSON" | jq . 2>/dev/null || echo "$VERSION_JSON"
