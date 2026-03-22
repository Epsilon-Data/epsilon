#!/bin/bash

set -euo pipefail

# Wait for Atlas to become responsive
echo "Waiting for Apache Atlas to start..."
until curl -sf -u admin:${ATLAS_ADMIN_PASSWORD} ${ATLAS_URI}/api/atlas/admin/status; do
  sleep 5
done

echo "Atlas is up and running. Import entities..."

# Import entities using the REST API
curl -g -X POST -u admin:${ATLAS_ADMIN_PASSWORD} \
  -H "Content-Type: multipart/form-data" \
  -H "Cache-Control: no-cache" \
  -F request=@/seed/options/import-options.json \
  -F data=@/seed/data/atlas-import.zip \
  "${ATLAS_URI}/api/atlas/admin/import"