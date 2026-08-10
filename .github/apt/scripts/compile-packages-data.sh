#!/usr/bin/env bash
# ==============================================================================
# AUTOMATED PLAIN-TEXT APT MANIFEST PARSER ENGINE
# ==============================================================================
# Target Path: .github/apt/scripts/compile-packages-data.sh
# Usage: ./compile-packages-data.sh <target_index_file> <debug_mode_flag>
#
# Description:
#   Processes a single uncompressed Debian 'Packages' manifest file.
#   Extracts context metrics from the directory structure track path,
#   runs a robust line-by-line awk filter, and streams out the cleanly 
#   formatted YAML property rows straight to standard output (stdout).
# ==============================================================================
set -euo pipefail

# 1. Input Argument Validation Gate
if [ "$#" -ne 2 ]; then
    echo "ERROR: Missing required input parameters." >&2
    echo "Usage: $0 <target_index_file> <debug_mode_flag>" >&2
    exit 1
fi

INDEX_FILE="$1"
DEBUG_MODE="$2"

# 2. Validate Target File Status Context
if [ ! -s "${INDEX_FILE}" ]; then
    if [ "${DEBUG_MODE}" = "true" ]; then
        echo "    -> [PARSER NOTICE] Target manifest exists but holds 0 bytes (empty). Skipping blocks." >&2
    fi
    exit 0
fi

# 3. Isolate the Suite and Component attributes directly from the directory path
# Example path: dists/bookworm/main/binary-all/Packages
CURRENT_SUITE=$(echo "${INDEX_FILE}" | cut -d'/' -f2)      # Extracts: bookworm
CURRENT_COMPONENT=$(echo "${INDEX_FILE}" | cut -d'/' -f3)  # Extracts: main

if [ "${DEBUG_MODE}" = "true" ]; then
    echo "    -> [PARSER ENGAGED] Processing Suite='${CURRENT_SUITE}', Component='${CURRENT_COMPONENT}'" >&2
fi

# 4. Execute the Robust Line-By-Line text processing algorithm matrix
awk -v suite="${CURRENT_SUITE}" -v component="${CURRENT_COMPONENT}" -v debug="${DEBUG_MODE}" '
    BEGIN {
        FS=": "
        pkg="" ; ver="" ; desc="" ; file=""
        record_count = 0
        lines_in_block = 0
    }
    
    # Track data lines to provide granular logging offsets
    { lines_in_block++ }
    
    # Match standard distribution configuration parameters
    $1 == "Package"     { pkg=$2 }
    $1 == "Version"     { ver=$2 }
    $1 == "Filename"    { file=$2 }
    $1 == "Description" { desc=$2; in_desc=1; next }
    
    # Safely track multi-line indented paragraph blocks
    /^[ \t]/ && in_desc == 1 {
        desc = desc "\n" $0
        next
    }
    
    # Clear description flags when hitting a normal standard header tag
    $1 ~ /^[A-Za-z\-]+$/ { in_desc=0 }

    # A completely blank line signals the end of an isolated package record block
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
                print "        [TRACE] Block #" record_count " (Lines: " lines_in_block "): Successfully matched and wrote Package=[" pkg "]" > "/dev/stderr"
            }
        } else if (debug == "true") {
            print "        [WARNING] Block #" record_count " (Lines: " lines_in_block "): Skipping record layout because required metadata fields are missing." > "/dev/stderr"
        }
        # Reset local cache tracking configurations
        pkg="" ; ver="" ; desc="" ; file="" ; in_desc=0 ; lines_in_block = 0
    }
    
    # Catch the final trailing data block if the file lacks a trailing newline
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
                print "        [TRACE] Terminal Block #" record_count " (Lines: " lines_in_block "): Successfully parsed trailing record Package=[" pkg "]" > "/dev/stderr"
            }
        }
        if (debug == "true") {
            print "        [TRACE] Stream finalized. Total blocks captured inside this instance: " record_count > "/dev/stderr"
        }
    }
' "${INDEX_FILE}"

exit 0
