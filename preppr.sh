#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: ./preppr.sh <PR_NUMBER>"
  exit 1
fi

PR_NUMBER="$1"
BRANCH_NAME="pr-$PR_NUMBER"

# Fetch latest remote branches
git fetch origin

# Get the source branch for the PR
SOURCE_BRANCH=$(gh pr view "$PR_NUMBER" --json headRefName -q .headRefName)

if [ -z "$SOURCE_BRANCH" ]; then
  echo "❌ Failed to get source branch for PR #$PR_NUMBER"
  exit 1
fi

# Check if local pr-N branch exists
if git show-ref --quiet refs/heads/$BRANCH_NAME; then
  echo "✔️ Branch $BRANCH_NAME already exists. Checking it out..."
  git checkout "$BRANCH_NAME"
else
  echo "📦 Creating branch $BRANCH_NAME from origin/$SOURCE_BRANCH..."
  git checkout -b "$BRANCH_NAME" "origin/$SOURCE_BRANCH" || {
    echo "❌ Failed to create branch."
    exit 1
  }
fi

# Set upstream if not already set
git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1 || {
  git branch --set-upstream-to="origin/$SOURCE_BRANCH" "$BRANCH_NAME" || echo "⚠️ Could not set upstream."
}

# Start Rojo
rojo serve
