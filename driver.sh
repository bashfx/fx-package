#!/usr/bin/env bash
#
# driver.sh - v7 Stable Test Driver for packagex
#

# --- ❗ MANDATORY CONFIGURATION ❗ ---
readonly SRC_TREE="/home/nulltron/.repos/bashfx/fx-catalog"
# --- END CONFIGURATION ---

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PKG_CMD="${SCRIPT_DIR}/packagex.sh"
readonly WORK_DIR="${SRC_TREE}/.work"
readonly TEST_PACKAGES=("fx.semver")

_run_cmd() {
    echo
    echo "# RUNNING: pkgx $*"
    "$PKG_CMD" "$@"
    printf "#--[EXIT:%d]--\n" "$?"
    read -p "Press [Enter] to continue..."
}

_setup() {
    echo "--- Setting up test environment ---"
    if [[ ! -d "$SRC_TREE" ]]; then
        echo "!! ERROR: Set SRC_TREE in driver.sh !!"
        exit 1
    fi
    _cleanup
    sed -i "s|^readonly SRC_TREE=.*|readonly SRC_TREE=\"${SRC_TREE}\";|" "$PKG_CMD"
    chmod +x "$PKG_CMD"
    echo "--- Setup Complete ---"
}

_cleanup() {
    echo "--- Running Cleanup Routine ---"
    if [[ -f "$PKG_CMD" ]]; then
        sed -i 's|^readonly SRC_TREE=.*|readonly SRC_TREE=""; # IMPORTANT: User must set this path.|' "$PKG_CMD"
    fi
    if [[ -f ~/.pkg_manifest ]]; then
        rm -f ~/.pkg_manifest
    fi
    if [[ -d "$WORK_DIR" ]]; then
        rm -rf "$WORK_DIR"
    fi
    if [[ -d "${SRC_TREE}/pkgs" ]]; then
        # This is a safe way to revert changes to test files
        git -C "$SRC_TREE" checkout -- "${SRC_TREE}/pkgs/" &>/dev/null || true
        git -C "$SRC_TREE" clean -fd "${SRC_TREE}/pkgs/" &>/dev/null || true
    fi
    echo "--- Cleanup Complete ---"
}

_get_true_source_path() {
    # Local implementation for the driver's use to avoid calling the script itself for pathing
    local pkg_name="$1"
    local p=${pkg_name%%.*}
    local s=${pkg_name#*.}
    if [[ "$p" == "util" ]]; then
        p="utils"
    fi
    printf "%s" "${SRC_TREE}/pkgs/${p}/${s}/${s}.sh"
}

main() {
    trap _cleanup EXIT
    _setup

    echo "### SCENARIO: Full Lifecycle ###"
    _run_cmd register fx.semver
    _run_cmd install fx.semver
    
    echo "--- Simulating developer update ---"
    echo "# new line" >> "$(_get_true_source_path fx.semver)"
    
    _run_cmd update fx.semver
    _run_cmd install -f fx.semver
    _run_cmd uninstall fx.semver
    _run_cmd restore fx.semver
    _run_cmd clean fx.semver

    echo -e "\n### ALL TESTS COMPLETE ###"
}

main "$@"
