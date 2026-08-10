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
    echo "=== START DEBUG LOG FOR FILE: ${INDEX_FILE} ===" >&2
    
    # Check if the file is completely empty before passing to awk
    if [ ! -s "${INDEX_FILE}" ]; then
        echo "  [DIAGNOSTIC] File exists but is 0 bytes (empty). Skipping blocks." >&2
        echo "=== END DEBUG LOG ===" >&2
        continue
    fi

    # Read the first 15 lines of the manifest to see exactly how fields are formatted
    echo "  [DIAGNOSTIC] Displaying top context headers raw text:" >&2
    head -n 15 "${INDEX_FILE}" | sed 's/^/    | /' >&2

    CURRENT_SUITE=$(echo "${INDEX_FILE}" | cut -d'/' -f2)
    CURRENT_COMPONENT=$(echo "${INDEX_FILE}" | cut -d'/' -f3)

    echo "  [DIAGNOSTIC] Extracted context: Suite='${CURRENT_SUITE}', Component='${CURRENT_COMPONENT}'" >&2
    echo "  [DIAGNOSTIC] Executing text extraction matrix..." >&2

    # Run awk with interior print trackers
    awk -v suite="${CURRENT_SUITE}" -v component="${CURRENT_COMPONENT}" '
        BEGIN { FS=": "; RS="" }
        {
            pkg="" ; ver="" ; desc="" ; file=""
            block_count++
            
            for(i=1; i<=NF; i++) {
                if($i ~ /^Package/)     { pkg=substr($0, index($0, $i)+length($i)+2); sub(/\n.*/, "", pkg) }
                if($i ~ /^Version/)     { ver=substr($0, index($0, $i)+length($i)+2); sub(/\n.*/, "", ver) }
                if($i ~ /^Description/) { desc=substr($0, index($0, $i)+length($i)+2); sub(/\n.*/, "", desc) }
                if($i ~ /^Filename/)    { file=substr($0, index($0, $i)+length($i)+2); sub(/\n.*/, "", file) }
            }
            
            # Diagnostic: Report what variables were extracted from this specific text paragraph block
            print "    - Block #" block_count ": Found Pkg=[" pkg "], Ver=[" ver "], File=[" file "]" > "/dev/stderr"
            
            if(file != "") {
                split(file, file_parts, "/")
                filename=file_parts[length(file_parts)]
                
                print "  - name: \"" pkg "\""
                print "    version: \"" ver "\""
                print "    suite: \"" suite "\""
                print "    component: \"" component "\""
                print "    file: \"" filename "\""
                print "    description: \"" desc "\""
                
                print "      -> SUCCESSFULLY MATCHED AND WRITTEN PACKAGES ENTRY TO YAML STACK" > "/dev/stderr"
            } else {
                print "      -> WARNING: Skipping block #" block_count " because Filename field is empty" > "/dev/stderr"
            }
        }
        END {
            print "  [DIAGNOSTIC] Total blocks evaluated inside this file: " block_count > "/dev/stderr"
        }
    ' "${INDEX_FILE}" >> "${OUTPUT_FILE}"
    
    echo "=== END DEBUG LOG FOR FILE: ${INDEX_FILE} ===" >&2
done

echo "Apt repository data successfully written to: ${OUTPUT_FILE}"
cat "${OUTPUT_FILE}"
exit 0
