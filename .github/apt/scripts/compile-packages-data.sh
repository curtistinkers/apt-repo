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
    echo "Parsing index map file path: ${INDEX_FILE}" >&2
    
    # EXTRACT CONTEXT DIRECTLY FROM THE DIRECTORY PATH
    # Example path: dists/bookworm/main/binary-all/Packages
    CURRENT_SUITE=$(echo "${INDEX_FILE}" | cut -d'/' -f2)      # Extracts: bookworm
    CURRENT_COMPONENT=$(echo "${INDEX_FILE}" | cut -d'/' -f3)  # Extracts: main

    # 3. Process text paragraphs cleanly using explicit Bash environment injection
    awk -v suite="${CURRENT_SUITE}" -v component="${CURRENT_COMPONENT}" '
        BEGIN { FS=": "; RS="" }
        {
            pkg="" ; ver="" ; desc="" ; file=""
            for(i=1; i<=NF; i++) {
                if($i ~ /^Package/)     { pkg=substr($0, index($0, $i)+length($i)+2); sub(/\n.*/, "", pkg) }
                if($i ~ /^Version/)     { ver=substr($0, index($0, $i)+length($i)+2); sub(/\n.*/, "", ver) }
                if($i ~ /^Description/) { desc=substr($0, index($0, $i)+length($i)+2); sub(/\n.*/, "", desc) }
                if($i ~ /^Filename/)    { file=substr($0, index($0, $i)+length($i)+2); sub(/\n.*/, "", file) }
            }
            
            if(file != "") {
                # Extract just the flat package filename from the end of the line
                # Example: ./pool/bookworm/main/test.deb -> test.deb
                split(file, file_parts, "/")
                filename=file_parts[length(file_parts)]
                
                # Print the perfect formatted YAML properties directly
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
