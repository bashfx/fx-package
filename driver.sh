#!/usr/bin/env bash

#===============================================================================
#  warmup.sh - An external test driver for packagex
#
#  This script creates a temporary test environment and provides selectable
#  test scenarios to verify the functionality of the packagex script.
#
#  Usage:
#    ./warmup.sh [all|s1|s2]
#
#    all - (Default) Runs all test scenarios.
#    s1  - Runs Scenario 1: Standard Lifecycle.
#    s2  - Runs Scenario 2: Caching & Preservation Workflow.
#
#===============================================================================

# --- Configuration ---
readonly PKG_CMD="./packagex"
readonly TEST_ROOT="$(pwd)/__pkgx_test_env"
readonly SRC_TREE="${TEST_ROOT}/src"

# --- Helper Functions ---

_run_cmd() {
    printf "\n#===============================================================================\n"
    printf "# RUNNING: pkgx %s\n" "$*"
    printf "#===============================================================================\n"
    "$PKG_CMD" "$@"
    printf "#---[ EXIT CODE: %d ]---\n" "$?"
    read -p "Press [Enter] to continue..."
}

_setup_test_env() {
    printf "--- Setting up test environment in %s ---\n" "$TEST_ROOT"
    rm -rf "$TEST_ROOT"
    rm -f ~/.pkg_manifest
    mkdir -p "${SRC_TREE}/pkgs/fx/semver"
    mkdir -p "${SRC_TREE}/pkgs/utils/logger"
    printf "#!/usr/bin/env bash\necho 'Semver v1'\n" > "${SRC_TREE}/pkgs/fx/semver/semver.sh"
    printf "#!/usr/bin/env bash\n#\n# --- META ---\n#\n# meta:\n#   author: CustomUser\n#   my_custom_field: some_value\n#\n\necho 'Logger v1'\n" > "${SRC_TREE}/pkgs/utils/logger/logger.sh"
    sed -i "s|^readonly SRC_TREE=.*|readonly SRC_TREE=\"${SRC_TREE}\";|" "$PKG_CMD"
    chmod +x "$PKG_CMD"
    printf "--- Setup Complete ---\n"
}

_cleanup() {
    printf "\n--- Cleaning up test environment ---\n"
    rm -rf "$TEST_ROOT"
    rm -f ~/.pkg_manifest
    sed -i 's|^readonly SRC_TREE=.*|readonly SRC_TREE=""; # IMPORTANT: User must set this path.|' "$PKG_CMD"
    printf "--- Cleanup Complete ---\n"
}

# --- Test Scenario Functions ---

#-------------------------------------------------------------------------------
# @test_scenario_1
# Tests the normalize -> register -> install -> uninstall -> clean cycle.
#-------------------------------------------------------------------------------
test_scenario_1() {
    echo "### SCENARIO 1: Testing 'fx.semver' Standard Lifecycle ###"
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

#-------------------------------------------------------------------------------
# @test_scenario_2
# Tests the 'cache' command and preservation of custom metadata.
#-------------------------------------------------------------------------------
test_scenario_2() {
    echo "### SCENARIO 2: Testing 'util.logger' Caching & Preservation ###"
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
    # Ensure cleanup happens on any exit
    trap _cleanup EXIT
    _setup_test_env

    local test_to_run="${1:-all}" # Default to 'all' if no argument is provided

    case "$test_to_run" in
        (s1)
            test_scenario_1
            ;;
        (s2)
            test_scenario_2
            ;;
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
