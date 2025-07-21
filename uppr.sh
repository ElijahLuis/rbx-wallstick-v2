#!/bin/bash

# uppr - Update your current PR branch and restart Rojo
# Usage: ./uppr
ROJO_PORT=34872

echo "🔍 Checking if Rojo is running on port $ROJO_PORT..."

# Find any process listening on port 34872
PID=$(lsof -i :$ROJO_PORT -t 2>/dev/null)

if [ -n "$PID" ]; then
  echo "🛑 Rojo process found (PID: $PID), terminating..."
  kill -9 "$PID"
  sleep 1
else
  echo "No Rojo process found."
fi

echo "Pulling latest changes from Git..."
git pull

echo "🚀 Launching Rojo..."
rojo serve
