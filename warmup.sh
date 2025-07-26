#!/usr/bin/env bash
#
# warmup.sh - v2 - A manual command guide for the Workspace Paradigm.
#
# This script demonstrates the two primary workflows for packagex v2.
#

#===============================================================================
#  STEP 0: PREREQUISITES (MANDATORY)
#-------------------------------------------------------------------------------
# 1. Manually edit './packagex.sh' and set the 'SRC_TREE' variable.
# 2. To ensure a clean test, run:
#    rm -f ~/.pkg_manifest && rm -rf /path/to/your/src_tree/.work
#===============================================================================


# --- SETUP ---
alias pkgx='./packagex.sh'
echo "Test alias 'pkgx' is set. Starting test sequence..."


#===============================================================================
#  SCENARIO 1: Standard Lifecycle for a NEW script (fx.semver)
#===============================================================================
echo "### Starting Scenario 1: Standard Lifecycle ###"

# --- 1.1 Registration (The NEW First Step) ---
# This command now creates the .work/ directory and prepares the files.
pkgx register fx.semver

# Verify the outcome in the workspace.
ls -l /path/to/your/src_tree/.work/
# You should see: fx.semver.orig.sh and fx.semver.pkg.sh

# Verify that the working copy header was enriched.
pkgx meta fx.semver

# --- 1.2 Installation ---
pkgx install fx.semver

# Verify the final installation. Note the new filename.
ls -l ~/.my/lib/tmp/fx.semver.sh
ls -l ~/.my/bin/tmp/semver

# --- 1.3 Update Cycle (CRITICAL NEW WORKFLOW) ---
# Simulate a developer making a change to the *pristine* source file.
echo "# A new comment" >> /path/to/your/src_tree/pkgs/fx/semver/semver.sh

# Run the new 'update' command. It will detect the change and refresh the workspace.
pkgx update fx.semver

# The workspace is updated, but the installed version is still the old one.
# You must now re-install to deploy the changes.
pkgx install -f fx.semver

# --- 1.4 Cleanup ---
# The rest of the lifecycle (disable, enable, uninstall, clean) remains the same.
pkgx uninstall fx.semver
pkgx clean fx.semver

# Manually revert the change to the pristine source file.
# git checkout /path/to/your/src_tree/pkgs/fx/semver/semver.sh


#===============================================================================
#  SCENARIO 2: Caching & Preservation
#===============================================================================
echo -e "\n### Starting Scenario 2: Caching & Preservation ###"

# The workflow for caching remains the same, but it now operates on the workspace.
pkgx cache util.logger
pkgx status util.logger
pkgx register util.logger
pkgx meta util.logger


# --- FINAL ---
echo -e "\n### Warmup guide complete. ###"
