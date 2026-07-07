#!/bin/bash
set -e

echo "=== 🔍 1. Locating Project Folders ==="
if [ -d "$HOME/cleanair_project" ]; then
    PROJECT_ROOT="$HOME/cleanair_project"
elif [ -d "./cleanair_dashboard" ]; then
    PROJECT_ROOT=$(pwd)
else
    echo "❌ Error: Could not automatically locate the cleanair_project directory."
    exit 1
fi

cd "$PROJECT_ROOT"
cd cleanair_dashboard
flutter pub get
flutter build web --release
cd "$PROJECT_ROOT"

echo "=== 🚀 2. Deploying to Cloud Run ==="
gcloud run deploy cleanair-api \
    --source . \
    --region us-central1 \
    --clear-base-image \
    --allow-unauthenticated

echo "=== 🎉 Deployment Complete! ==="
