#!/usr/bin/env bash
# ==============================================================================
# OFFLINE BROWSER PREVIEW ROUTE TRANSLATION FILTER (DRY HOOK)
# ==============================================================================
# Target Path: .github/apt/scripts/flatten-web-paths.sh
# Usage: ./flatten-web-paths.sh <target_directory>
#
# Description:
#   Recursively scans compiled HTML page files inside a specified staging folder.
#   Uses standard sed text alterations to convert absolute root-relative paths
#   (href="/...", src="/...") into local file-relative tracks (href="./...").
#   This allows users to open and test the full styled repository layout directly 
#   from their local hard drive (C:\...) without hosting an active server.
# ==============================================================================
set -euo pipefail

# 1. Input Argument Validation Gate
if [ "$#" -ne 1 ]; then
    echo "ERROR: Missing target directory parameter." >&2
    echo "Usage: $0 <target_directory>" >&2
    exit 1
fi

STAGING_DIR="$1"

# 2. Environmental Existence Verification
if [ ! -d "${STAGING_DIR}" ]; then
    echo "ERROR: Target directory '${STAGING_DIR}' not found. Aborting string updates." >&2
    exit 1
fi

echo "Converting root-relative anchor paths to local file-relative tracks inside: ${STAGING_DIR}"

# 3. Locate and modify absolute hyperlinks natively inside your compiled pages
# Using a depth constraint protects deeply nested internal templates if present
find "${STAGING_DIR}" -maxdepth 1 -type f -name "*.html" -print0 | while rmd -d '' HTML_FILE; do
    echo "Translating hyperlinks inside asset profile: ${HTML_FILE}" >&2
    sed -i 's|href="/|href="./|g' "${HTML_FILE}"
    sed -i 's|src="/|src="./|g' "${HTML_FILE}"
done

echo "Path translation loop completed successfully across all staging layouts."
exit 0
