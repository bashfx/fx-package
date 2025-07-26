#!/usr/bin/env bash
#
# warmup.sh - A sequence of commands to manually test packagex functionality.
#
# This script demonstrates the two primary workflows:
#  1. Normalizing and installing a new package.
#  2. Caching and then fully registering a package with custom metadata.
#

#===============================================================================
#  STEP 0: PREREQUISITES (MANDATORY)
#-------------------------------------------------------------------------------
# 1. Edit the './packagex' script and set the 'SRC_TREE' variable to the
#    absolute path of your source code repository (e.g., /path/to/fx-catalog).
#
# 2. To ensure a clean test, remove any previous manifest file:
#    rm -f ~/.pkg_manifest
#
# 3. This test uses 'fx.semver' and a dummy 'util.logger'. Ensure the semver
#    file has NO metadata header to begin with. You can create the dummy
#    logger package with the following commands:
#
#    # In your SRC_TREE directory...
#    mkdir -p pkgs/utils/logger
#    printf "#!/usr/bin/env bash\n#\n# --- META ---\n#\n# meta:\n#   author: CustomUser\n#   my_custom_field: some_value\n#\n\necho 'Logger v1'\n" > pkgs/utils/logger/logger.sh
#===============================================================================


# --- SETUP ---
alias pkgx='./packagex'
echo "Test alias 'pkgx' is set. Starting test sequence..."


#===============================================================================
#  SCENARIO 1: Standard Lifecycle for a NEW script (fx.semver)
#===============================================================================
echo "### Starting Scenario 1: Standard Lifecycle ###"

# --- 1.1 Normalize and Register ---
# Normalize the script. This is the NEW first step for a raw script.
# It adds the minimal metadata header.
pkgx normalize fx.semver

# Verify we can now read the default metadata.
pkgx meta fx.semver

# Register the package. This will read the header, calculate derived data,
# update the manifest, and ENRICH the header in the source file.
pkgx register fx.semver

# Check the status. Should show as KNOWN or INCOMPLETE.
pkgx status fx.semver
pkgx status all # View the whole manifest

# --- 1.2 Installation Lifecycle ---
# Install the package.
pkgx install fx.semver

# Verify the outcome.
ls -l ~/.my/lib/tmp/semver.sh   # Check that the library file exists.
ls -l ~/.my/bin/tmp/semver      # Check that the symlink exists.
pkgx status fx.semver           # Status should now be INSTALLED.

# --- 1.3 Disable / Enable Cycle ---
pkgx disable fx.semver
ls -l ~/.my/bin/tmp/semver      # Should fail (file not found).
pkgx status fx.semver           # Should be DISABLED.

pkgx enable fx.semver
ls -l ~/.my/bin/tmp/semver      # Should exist again.
pkgx status fx.semver           # Should be INSTALLED.

# --- 1.4 Uninstall / Restore / Clean Cycle ---
pkgx uninstall fx.semver
ls -l ~/.my/lib/tmp/semver.sh   # Should fail.
pkgx status fx.semver           # Should be REMOVED.

pkgx restore fx.semver
ls -l ~/.my/lib/tmp/semver.sh   # Should exist again.
pkgx status fx.semver           # Should be INSTALLED.

pkgx uninstall fx.semver        # Uninstall again to prepare for cleaning.
pkgx clean fx.semver
pkgx status fx.semver           # Should fail (package not in manifest).


#===============================================================================
#  SCENARIO 2: Caching & Preservation for a script with EXISTING custom meta
#===============================================================================
echo -e "\n### Starting Scenario 2: Caching & Preservation ###"

# --- 2.1 Cache and Verify ---
# First, view the initial metadata, including our custom field.
pkgx meta util.logger

# Use the NEW 'cache' command to create a partial entry in the manifest.
pkgx cache util.logger

# The status should be INCOMPLETE, and the manifest should only have header data.
pkgx status util.logger

# --- 2.2 Register and Verify Preservation ---
# Now, perform a full registration.
pkgx register util.logger

# CRITICAL VERIFICATION: Check the header again. The 'my_custom_field'
# MUST have been preserved, and the other fields should now be enriched.
pkgx meta util.logger

# The manifest should now show a complete, 'KNOWN' record.
pkgx status util.logger


# --- FINAL ---
echo -e "\n### Warmup script complete. ###"
