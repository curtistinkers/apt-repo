#!/usr/bin/env bash
# ==============================================================================
# REPOSITORY INDEX SCANNER & MAIN SHELL CONTROLLER
# ==============================================================================
# Target Path: .github/apt/scripts/scan-repository-indexes.sh
# Usage: ./scan-repository-indexes.sh
#
# Description:
#   Validates the existence of the 'dists/' repository metadata tree.
#   Initializes the main '_data/packages.yml' data file and coordinates
#   the sequential lookup of all uncompressed 'Packages' manifest files.
#   Discovered manifests are fed down to the processing compilation script.
# ==============================================================================
set -euo pipefail

# ------------------------------------------------------------------------------
# DIAGNOSTIC CONTROL SWITCH (SET TO "true" TO LOG, "false" TO SILENCE)
# ------------------------------------------------------------------------------
DEBUG_MODE="true"

# Define shared script execution relative paths
SCRIPT_DIR=".github/scripts"
PARSER_SCRIPT="${SCRIPT_DIR}/compile-packages-data.sh"

OUTPUT_DIR="_data"
OUTPUT_FILE="${OUTPUT_DIR}/packages.yml"

mkdir -p "${OUTPUT_DIR}"

# 1. Verification Gate: Confirm the parsing engine engine is available
if [ ! -x "${PARSER_SCRIPT}" ]; then
    echo "[DIAGNOSTIC ERROR] Parsing script not executable or missing: ${PARSER_SCRIPT}" >&2
    exit 1
fi

# 2. Environmental Existence Guard Check
if [ ! -d "dists" ] || [ -z "$(find dists/ -type f -name "Packages" 2>/dev/null)" ]; then
    echo "WARNING: No active APT indices ('dists/**/Packages') discovered." >&2
    echo "Creating an empty package database schema for Jekyll stability..." >&2
    echo "packages: []" > "${OUTPUT_FILE}"
    exit 0
fi

# 3. Initialize the Master Database Header
echo "packages:" > "${OUTPUT_FILE}"
echo "Scanning plain-text index manifests for high-performance table generation..."

# 4. Recursively locate every uncompressed Packages manifest file on the disk
find dists/ -type f -name "Packages" | sort | while read -r INDEX_FILE; do
    if [ "${DEBUG_MODE}" = "true" ]; then
        echo "=== [SCANNER INTERCEPT] Discovered Manifest File Target: ${INDEX_FILE} ===" >&2
    fi
    
    # Pass the active manifest file to the parser engine script
    # Standard output is appended smoothly to our centralized database file
    "${PARSER_SCRIPT}" "${INDEX_FILE}" "${DEBUG_MODE}" >> "${OUTPUT_FILE}"
    
    if [ "${DEBUG_MODE}" = "true" ]; then
        echo "=== [SCANNER INTERCEPT END] ===" >&2
    fi
done

echo "Apt repository data compilation loops finalized successfully."

if [ "${DEBUG_MODE}" = "true" ]; then
    echo "=== [DEBUG START] RAW OUTPUT DUMP OF THE GENERATED BACKUP DATABASE ==="
    cat "${OUTPUT_FILE}"
    echo "=== [DEBUG END] ==="
fi

exit 0
