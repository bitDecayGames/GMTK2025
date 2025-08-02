#!/bin/bash

# Safe git pull script that checks if LDTK is running first
# Usage: ./bin/safe_pull.sh [git pull arguments...]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Get the directory of this script
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CHECK_LDTK_SCRIPT="$SCRIPT_DIR/check_ldtk.sh"

echo "Checking if LDTK is running..."

# Check if LDTK check script exists
if [ ! -f "$CHECK_LDTK_SCRIPT" ]; then
    echo -e "${YELLOW}Warning: Could not find LDTK check script at $CHECK_LDTK_SCRIPT${NC}"
    echo "Proceeding with git pull anyway..."
else
    # Run LDTK check
    if "$CHECK_LDTK_SCRIPT" | grep -q "LDTK is running"; then
        echo -e "${RED}ERROR: LDTK is currently running!${NC}"
        echo -e "${YELLOW}Please close LDTK before pulling to avoid potential conflicts.${NC}"
        echo "LDTK may auto-save changes that could conflict with incoming updates."
        echo ""
        echo "To force pull anyway (not recommended), use git pull directly"
        exit 1
    else
        echo -e "${GREEN}LDTK is not running. Safe to pull.${NC}"
    fi
fi

# Run git pull with any arguments passed to this script
echo "Running: git pull $@"
git pull "$@"