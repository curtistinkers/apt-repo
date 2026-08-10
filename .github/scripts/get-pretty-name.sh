#!/usr/bin/env bash
# ==============================================================================
# REUSABLE DISTRO PRETTY-NAME GENERATION ENGINE (DRY HOOK)
# ==============================================================================
# Usage: ./get-pretty-name.sh "<target_suite>" "<json_suites_array>"
#
# Description:
#   Evaluates a target Linux suite against a chronological global array string.
#   Uses a state-machine parser loop to dynamically separate Debian, Proxmox, 
#   and Ubuntu tracks based on the placement of 'pve' suites in the array matrix.
# ==============================================================================
set -euo pipefail

# ------------------------------------------------------------------------------
# 1. INPUT ARGUMENT ARRAYS VALIDATION GATES
# ------------------------------------------------------------------------------
if [ "$#" -ne 2 ]; then
    echo "ERROR: Missing required arguments." >&2
    echo "Usage: $0 <target_suite> <json_suites_array>" >&2
    exit 1
fi

TARGET_DIST="$1"
RAW_JSON_ARRAY="$2"

# ------------------------------------------------------------------------------
# 2. PARSE GLOBAL REPO MATRIX DIRECTLY INTO NATIVE BASH ARRAYS
# ------------------------------------------------------------------------------
# jq -r '.[]' cleanly converts '["a", "b"]' into a safe space-separated text stream
mapfile -t SUITES_ARRAY < <(jq -r '.[]' <<<"${RAW_JSON_ARRAY}")

# Default the flag state machine to classic Debian classification rules
CURRENT_OS_TYPE="Debian"

# ------------------------------------------------------------------------------
# 3. RUN CHRONOLOGICAL AUTOMATED STATE-MACHINE SORTING LOOP
# ------------------------------------------------------------------------------
for SUITE in "${SUITES_ARRAY[@]}"; do
    if [[ "$SUITE" == pve* ]]; then
        # Check if the active matrix target matches this exact PVE version
        if [ "$TARGET_DIST" = "$SUITE" ]; then
            CURRENT_OS_TYPE="Proxmox"
            break
        fi
        # THE STATE SWITCH FLIP: The moment the iterator crosses a pve suite entry, 
        # any subsequent suite entries in the array are permanently flagged as Ubuntu
        CURRENT_OS_TYPE="Ubuntu"
    elif [ "$TARGET_DIST" = "$SUITE" ]; then
        # Found our active matrix target; halt execution to process current flag state
        break
    fi
done

# ------------------------------------------------------------------------------
# 4. COMPUTE FINALISED PRETTY STRINGS NATIVELY VIA TEXT MANIPULATION
# ------------------------------------------------------------------------------
if [ "$CURRENT_OS_TYPE" = "Proxmox" ]; then
    # Strips the 'pve' letters off the front to extract the raw integer version
    echo "Proxmox VE ${TARGET_DIST#pve}"
elif [ "$CURRENT_OS_TYPE" = "Ubuntu" ]; then
    # ${VAR^} natively converts the first character of the string to uppercase
    echo "Ubuntu ${TARGET_DIST^}"
else
    # Natively converts the first character of the Debian codename to uppercase
    echo "Debian ${TARGET_DIST^}"
fi

exit 0
