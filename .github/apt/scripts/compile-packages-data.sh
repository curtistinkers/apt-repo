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

DEBUG_MODE="true"

# Initialize clean output destination variables
OUTPUT_DIR="_data"
OUTPUT_FILE="${OUTPUT_DIR}/packages.yml"

mkdir -p "${OUTPUT_DIR}"

# ------------------------------------------------------------------------------
# 1. NON-FAILING ENVIRONMENTAL GUARD CHECK
# ------------------------------------------------------------------------------
if [ ! -d "dists" ] || [ -z "$(find dists/ -type f -name "Packages" 2>/dev/null)" ]; then
    echo "WARNING: No active APT indices ('dists/**/Packages') discovered." >&2
    echo "Creating an empty package database schema for Jekyll stability..." >&2
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
    CURRENT_SUITE=$(echo "${INDEX_FILE}" | cut -d'/' -f2)
    CURRENT_COMPONENT=$(echo "${INDEX_FILE}" | cut -d'/' -f3)

    if [ "${DEBUG_MODE}" = "true" ]; then
        echo "=== [DEBUG START] COMPILING METADATA ASSETS FOR: ${INDEX_FILE} ===" >&2
        echo "    -> Extracted Target Space: Suite='${CURRENT_SUITE}', Component='${CURRENT_COMPONENT}'" >&2
        if [ ! -s "${INDEX_FILE}" ]; then
            echo "    -> [NOTICE] Manifest file exists but is 0 bytes (empty). Skipping execution." >&2
            echo "=== [DEBUG END] ===" >&2
            continue
        else
            echo "    -> [NOTICE] File contains active data streams. Launching line-by-line parser matrix..." >&2
        fi
    fi

    # 3. Line-By-Line Parser Execution with Conditional Variable Injections
    awk -v suite="${CURRENT_SUITE}" -v component="${CURRENT_COMPONENT}" -v debug="${DEBUG_MODE}" '
        BEGIN {
            FS=": "
            pkg="" ; ver="" ; desc="" ; file=""
            record_count = 0
            lines_in_block = 0
        }
        
        # Track line data counters for deep error mapping
        { lines_in_block++ }
        
        # Match standard distribution key indicators
        $1 == "Package"     { pkg=$2 }
        $1 == "Version"     { ver=$2 }
        $1 == "Filename"    { file=$2 }
        $1 == "Description" { desc=$2; in_desc=1; next }
        
        # Capture multiline wrapped description blocks
        /^[ \t]/ && in_desc == 1 {
            desc = desc "\n" $0
            next
        }
        
        # Turn off multiline description tracking if any other valid tag is hit
        $1 ~ /^[A-Za-z\-]+$/ { in_desc=0 }

        # A completely empty line marks the end of a single package record block
        /^$/ {
            record_count++
            if (pkg != "" && file != "") {
                split(file, file_parts, "/")
                filename = file_parts[length(file_parts)]
                
                print "  - name: \"" pkg "\""
                print "    version: \"" ver "\""
                print "    suite: \"" suite "\""
                print "    component: \"" component "\""
                print "    file: \"" filename "\""
                print "    description: \"" desc "\""
                
                if (debug == "true") {
                    print "    [TRACE] Block #" record_count " (Lines: " lines_in_block "): Successfully matched and wrote Package=[" pkg "] Ver=[" ver "]" > "/dev/stderr"
                }
            } else if (debug == "true") {
                print "    [WARNING] Block #" record_count " (Lines: " lines_in_block "): Skipping record layout because Package=[" pkg "] or Filename=[" file "] is empty" > "/dev/stderr"
            }
            # Flush variable states for the next incoming record loop pass
            pkg="" ; ver="" ; desc="" ; file="" ; in_desc=0 ; lines_in_block = 0
        }
        
        # Capture the final package block trailing records if a trailing newline is missing
        END {
            if (pkg != "" && file != "") {
                record_count++
                split(file, file_parts, "/")
                filename = file_parts[length(file_parts)]
                
                print "  - name: \"" pkg "\""
                print "    version: \"" ver "\""
                print "    suite: \"" suite "\""
                print "    component: \"" component "\""
                print "    file: \"" filename "\""
                print "    description: \"" desc "\""
                
                if (debug == "true") {
                    print "    [TRACE] Terminal Block #" record_count " (Lines: " lines_in_block "): Successfully matched and wrote Package=[" pkg "]" > "/dev/stderr"
                }
            }
            if (debug == "true") {
                print "    [TRACE] Completed scanning file matrix. Total data blocks processed: " record_count > "/dev/stderr"
            }
        }
    ' "${INDEX_FILE}" >> "${OUTPUT_FILE}"
    
    if [ "${DEBUG_MODE}" = "true" ]; then
        echo "=== [DEBUG END] COMPILING METADATA ASSETS FOR: ${INDEX_FILE} ===" >&2
    fi
done

echo "Apt repository data successfully written to: ${OUTPUT_FILE}"

if [ "${DEBUG_MODE}" = "true" ]; then
    echo "=== [DEBUG START] RAW OUTPUT DUMP OF GENERATED packages.yml COMPONENT IN MEMORY ==="
    cat "${OUTPUT_FILE}"
    echo "=== [DEBUG END] ==="
fi

exit 0
