#!/bin/bash

# Cross-platform script to check if LDTK is running
# Works on Linux, macOS, and Windows (with Git Bash/WSL)

check_ldtk() {
    local os_type=$(uname -s)
    
    case "$os_type" in
        Linux*|Darwin*)
            # Linux and macOS - use ps, exclude grep and this script
            if ps aux | grep -i "ldtk" | grep -v grep | grep -v "check_ldtk" > /dev/null; then
                echo "LDTK is running"
                return 0
            else
                echo "LDTK is not running"
                return 1
            fi
            ;;
        CYGWIN*|MINGW*|MSYS*)
            # Windows with Git Bash/MSYS2 - use tasklist, exclude this script
            if tasklist 2>/dev/null | grep -i "ldtk" | grep -v "check_ldtk" > /dev/null; then
                echo "LDTK is running"
                return 0
            else
                echo "LDTK is not running"
                return 1
            fi
            ;;
        *)
            echo "Unsupported operating system: $os_type"
            return 2
            ;;
    esac
}

# Run the check
check_ldtk
exit $?