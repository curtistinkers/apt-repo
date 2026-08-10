#!/usr/bin/env bash
# ==============================================================================
# PLAIN-TEXT APT MANIFEST PARSER FOR JEKYLL
# ==============================================================================
# Target Path: .github/apt/scripts/compile-packages-data.sh
# Usage: ./compile-packages-data.sh
#
# Description:
#   Recursively scans uncompressed 'Packages' manifests inside the 'dists/'
#   directory. Uses an awk text processing block to extract core 
#   metadata (Package, Version, Description, Filename) and formats it into 
#   a single structured '_data/packages.yml' database for Jekyll site loops.
#
# Non-Failing Guard:
#   If the 'dists/' folder is missing or contains no index data, the script
#   safely creates an empty database file and exits gracefully (status 0)
#   so the main web compilation step does not fail.
# ==============================================================================
set -euo pipefail

# Initialize clean output destination variables
OUTPUT_DIR="_data"
OUTPUT_FILE="${OUTPUT_DIR}/packages.yml"

mkdir -p "${OUTPUT_DIR}"

# ------------------------------------------------------------------------------
# 1. NON-FAILING ENVIRONMENTAL GUARD CHECK
# ------------------------------------------------------------------------------
# Checks if the dists directory is missing OR completely empty of index maps
if [ ! -d "dists" ] || [ -z "$(find dists/ -type f -name "Packages" 2>/dev/null)" ]; then
    echo "WARNING: No active APT indices ('dists/**/Packages') discovered." >&2
    echo "Creating an empty package database schema for Jekyll stability..." >&2
    # Writes a safe, blank array header so Jekyll templates do not crash on null variables
    echo "packages: []" > "${OUTPUT_FILE}"
    exit 0
fi

# ------------------------------------------------------------------------------
# 2. INITIALIZE POPULATED DATABASE MATRIX
# ------------------------------------------------------------------------------
echo "packages:" > "${OUTPUT_FILE}"
echo "Scanning plain-text index manifests for high-performance table generation..."

# ------------------------------------------------------------------------------
# 3. RECURSIVELY PROCESS AND CONVERT PLAIN-TEXT REPO INDEXES TO YAML
# ------------------------------------------------------------------------------
find dists/ -type f -name "Packages" | sort | while read -r INDEX_FILE; do
    echo "Parsing index map: ${INDEX_FILE}" >&2
    
    awk '
        BEGIN { FS=": "; RS="" }
        {
            pkg="" ; ver="" ; desc="" ; file=""
            for(i=1; i<=NF; i++) {
                # Cleanly extracts the text directly following the field labels
                if($i ~ /^Package/)     { pkg=substr($0, index($0, $i)+length($i)+2); sub(/\n.*/, "", pkg) }
                if($i ~ /^Version/)     { ver=substr($0, index($0, $i)+length($i)+2); sub(/\n.*/, "", ver) }
                if($i ~ /^Description/) { desc=substr($0, index($0, $i)+length($i)+2); sub(/\n.*/, "", desc) }
                if($i ~ /^Filename/)    { file=substr($0, index($0, $i)+length($i)+2); sub(/\n.*/, "", file) }
            }
            
            if(file != "") {
                split(file, path_parts, "/")
                suite=path_parts[2]
                component=path_parts[3]
                filename=path_parts[4]
                
                print "  - name: \"" pkg "\""
                print "    version: \"" ver "\""
                print "    suite: \"" suite "\""
                print "    component: \"" component "\""
                print "    file: \"" filename "\""
                print "    description: \"" desc "\""
            }
        }
    ' "${INDEX_FILE}" >> "${OUTPUT_FILE}"
done

echo "Apt repository data successfully written to: ${OUTPUT_FILE}"
cat "${OUTPUT_FILE}"
exit 0
