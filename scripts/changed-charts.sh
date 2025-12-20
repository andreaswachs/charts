#!/usr/bin/env bash
# Detect charts that have changed between two refs
# Usage: ./changed-charts.sh [base_ref] [head_ref]
#   base_ref: The base reference to compare against (default: origin/main)
#   head_ref: The head reference to compare (default: HEAD)

set -euo pipefail

BASE_REF="${1:-origin/main}"
HEAD_REF="${2:-HEAD}"

# Get list of changed files
changed_files=$(git diff --name-only "$BASE_REF"..."$HEAD_REF" 2>/dev/null || git diff --name-only "$BASE_REF".."$HEAD_REF" 2>/dev/null || echo "")

if [ -z "$changed_files" ]; then
    exit 0
fi

# Extract unique chart directories from changed files
charts=()
while IFS= read -r file; do
    if [[ "$file" =~ ^charts/([^/]+)/ ]]; then
        chart="charts/${BASH_REMATCH[1]}"
        # Only add if Chart.yaml exists and not already in list
        if [ -f "$chart/Chart.yaml" ]; then
            if [[ ! " ${charts[*]:-} " =~ " ${chart} " ]]; then
                charts+=("$chart")
            fi
        fi
    fi
done <<< "$changed_files"

# Output space-separated list of charts
echo "${charts[*]:-}"
