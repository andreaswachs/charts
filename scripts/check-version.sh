#!/usr/bin/env bash
# Check if chart version was properly updated and follows semver rules
# Usage: ./check-version.sh <chart_path> [base_ref]
# Exit codes:
#   0 - Version check passed
#   1 - Version check failed

set -euo pipefail

CHART_PATH="$1"
BASE_REF="${2:-origin/main}"

if [ ! -f "$CHART_PATH/Chart.yaml" ]; then
    echo "ERROR: Chart.yaml not found in $CHART_PATH"
    exit 1
fi

CHART_NAME=$(basename "$CHART_PATH")

# Get current version
CURRENT_VERSION=$(grep '^version:' "$CHART_PATH/Chart.yaml" | awk '{print $2}' | tr -d '"' | tr -d "'")

if [ -z "$CURRENT_VERSION" ]; then
    echo "ERROR: Could not read version from $CHART_PATH/Chart.yaml"
    exit 1
fi

# Validate current version is valid semver
if ! [[ "$CURRENT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?(\+[a-zA-Z0-9.-]+)?$ ]]; then
    echo "ERROR: Current version '$CURRENT_VERSION' is not valid semver"
    exit 1
fi

# Try to get the version from main branch
BASE_VERSION=$(git show "$BASE_REF:$CHART_PATH/Chart.yaml" 2>/dev/null | grep '^version:' | awk '{print $2}' | tr -d '"' | tr -d "'" || echo "")

if [ -z "$BASE_VERSION" ]; then
    # Chart doesn't exist on main - this is a new chart
    echo "NEW_CHART"
    echo "Chart: $CHART_NAME"
    echo "Version: $CURRENT_VERSION"
    echo "Status: New chart, no version comparison needed"
    exit 0
fi

echo "EXISTING_CHART"
echo "Chart: $CHART_NAME"
echo "Base version: $BASE_VERSION"
echo "Current version: $CURRENT_VERSION"

# Compare versions using sort -V
compare_versions() {
    local v1="$1"
    local v2="$2"

    # Strip any pre-release/build metadata for comparison
    v1_core=$(echo "$v1" | sed 's/[-+].*//')
    v2_core=$(echo "$v2" | sed 's/[-+].*//')

    if [ "$v1_core" = "$v2_core" ]; then
        echo "equal"
    elif [ "$(printf '%s\n%s' "$v1_core" "$v2_core" | sort -V | head -n1)" = "$v1_core" ]; then
        echo "greater"
    else
        echo "lesser"
    fi
}

result=$(compare_versions "$BASE_VERSION" "$CURRENT_VERSION")

case "$result" in
    "greater")
        echo "Status: Version increased from $BASE_VERSION to $CURRENT_VERSION ✓"
        exit 0
        ;;
    "equal")
        echo "Status: Version unchanged ($CURRENT_VERSION = $BASE_VERSION)"
        echo "ERROR: Chart was modified but version was not updated"
        exit 1
        ;;
    "lesser")
        echo "Status: Version decreased from $BASE_VERSION to $CURRENT_VERSION"
        echo "ERROR: Version must not decrease"
        exit 1
        ;;
esac
