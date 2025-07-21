#!/bin/bash

# cleanpr - Cleanup script after merging PR on GitHub
# Usage: ./cleanpr <PR_NUMBER>

PR="$1"

if [ -z "$PR" ]; then
  echo "Please provide the PR number of branch you need to clean up (e.g. ./cleanpr 6)"
  exit 1
fi

BRANCH="pr-$PR"

echo "Switching to main branch..."
git checkout main

echo "Checking for stale origin/codex* remote branches..."
for stale in $(git branch -r | grep 'origin/codex'); do
  echo "🧹 Deleting stale remote branch: $stale"
  git push origin --delete "${stale#origin/}" 2>/dev/null || true
done

echo "Pulling latest updates from GitHub..."
git pull

echo "Deleting local branch $BRANCH..."
git branch -D "$BRANCH"

echo "Pruning stale remote references..."
git remote prune origin

echo "✅ Cleanup complete."
sleep 1
clear
