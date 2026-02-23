#!/bin/bash
set -euo pipefail

# Deploy PillChecker frontend to Hetzner server
# Builds the React app and syncs to the backend's frontend-dist directory

REMOTE_HOST="${PILLCHECKER_HOST:-pillchecker}"
REMOTE_DIR="${PILLCHECKER_REMOTE_DIR:-/opt/pillchecker-api/frontend-dist}"

echo "Building production bundle..."
npm run build

echo "Syncing to ${REMOTE_HOST}:${REMOTE_DIR}..."
rsync -avz --delete dist/ "${REMOTE_HOST}:${REMOTE_DIR}/"

echo "Restarting nginx..."
ssh "${REMOTE_HOST}" "cd /opt/pillchecker-api && docker compose restart nginx"

echo "Deployed successfully!"
