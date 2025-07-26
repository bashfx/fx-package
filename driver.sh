#!/usr/bin/env bash

#===============================================================================
#  driver.sh - A "Live File" test driver for packagex
#
#  This script operates directly on a real source code repository.
#  It is designed to be safe but requires configuration before use.
#
#  Usage:
#    ./driver.sh [all|s1|s2]
#===============================================================================

# ---
# --- ❗ MANDATORY CONFIGURATION ❗
# ---
# You MUST set this variable to the absolute path of your BASHFX source repo.
# The script will NOT run until this is set.
readonly SRC_TREE="/home/nulltron/.repos/bashfx/fx-catalog"

# A list of all packages that this test script will touch.
# Used for the automated cleanup routine.
readonly TEST_PACKAGES=("fx.semver" "util.logger")
# ---
# --- END CONFIGURATION ---
# ---

# --- Read-only paths derived from configuration ---
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PKG_CMD="${SCRIPT_DIR}/packagex.sh"


# --- Helper Functions ---

_run_cmd() {
    echo
    echo "#==============================================================================="
    echo "# RUNNING: pkgx $*"
    echo "#==============================================================================="
    "$PKG_CMD" "$@"
    printf "#---[ EXIT CODE: %d ]---\n" "$?"
    read -p "Press [Enter] to continue..."
}

_setup() {
    echo "--- Setting up test environment ---"
    
    # CRITICAL: Validate that the user has configured the SRC_TREE.
    if [[ ! -d "$SRC_TREE" || "$SRC_TREE" == "" ]]; then
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "!! ERROR: You must edit driver.sh and set the SRC_TREE      !!"
        echo "!!        variable to the path of your BASHFX repository.   !!"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        exit 1
    fi
    
    # Perform a pre-run cleanup to ensure a clean slate.
    _cleanup
    
    # Modify the packagex script in-place to point to the configured SRC_TREE
    sed -i "s|^readonly SRC_TREE=.*|readonly SRC_TREE=\"${SRC_TREE}\";|" "$PKG_CMD"
    chmod +x "$PKG_CMD"
    
    echo "--- Setup Complete. Testing on live files in: ${SRC_TREE} ---"
}

_cleanup() {
    echo
    echo "--- Running Cleanup Routine ---"

    if [[ ! -f ~/.pkg_manifest ]]; then
        echo "Manifest not found, no cleanup needed."
        return 0
    fi
    
    for pkg in "${TEST_PACKAGES[@]}"; do
        # We don't care about errors here, just ensuring state is reset.
        "$PKG_CMD" uninstall "$pkg" &>/dev/null
        "$PKG_CMD" clean "$pkg" &>/dev/null
    done
    
    rm -f ~/.pkg_manifest
    
    # Restore the original SRC_TREE line in packagex
    sed -i 's|^readonly SRC_TREE=.*|readonly SRC_TREE=""; # IMPORTANT: User must set this path.|' "$PKG_CMD"
    echo "--- Cleanup Complete ---"
}

# --- Test Scenario Functions ---

test_scenario_1() {
    echo "### SCENARIO 1: Testing 'fx.semver' Standard Lifecycle ###"
    # Note: Assumes fx.semver has no header metadata to start.
    _run_cmd normalize fx.semver
    _run_cmd meta fx.semver
    _run_cmd register fx.semver
    _run_cmd meta fx.semver
    _run_cmd install fx.semver
    _run_cmd disable fx.semver
    _run_cmd enable fx.semver
    _run_cmd uninstall fx.semver
    _run_cmd restore fx.semver
    _run_cmd uninstall fx.semver
    _run_cmd clean fx.semver
}

test_scenario_2() {
    echo "### SCENARIO 2: Testing 'util.logger' Caching & Preservation ###"
    # Note: Assumes a dummy util.logger/logger.sh exists with custom metadata.
    _run_cmd meta util.logger
    _run_cmd cache util.logger
    _run_cmd status util.logger
    _run_cmd register util.logger
    _run_cmd meta util.logger
}

# --- Core Driver ---

usage() {
    printf "Usage: %s [command]\n" "$(basename "$0")"
    printf "  A test driver for the packagex script.\n\n"
    printf "Commands:\n"
    printf "  all (default)  - Run all available test scenarios.\n"
    printf "  s1             - Run Scenario 1: Standard Lifecycle.\n"
    printf "  s2             - Run Scenario 2: Caching & Preservation.\n"
}

main() {
    trap _cleanup EXIT
    _setup

    local test_to_run="${1:-all}"

    case "$test_to_run" in
        (s1) test_scenario_1;;
        (s2) test_scenario_2;;
        (all)
            test_scenario_1
            test_scenario_2
            ;;
        (*)
            echo "Error: Unknown test '$test_to_run'"
            usage
            exit 1
            ;;
    esac

    echo -e "\n### ALL REQUESTED TESTS COMPLETE ###"
}

# --- Main Invocation ---
main "$@"
