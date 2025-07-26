# Set an alias for convenience
alias pkgx='./packagex'

# --- 1. Initial State & Registration ---
# Verify we can read metadata from the source file.
pkgx meta fx.semver

# Register the package. Creates the manifest file if it doesn't exist.
pkgx register fx.semver

# Check the status. Should show as INCOMPLETE or KNOWN.
pkgx status fx.semver
pkgx status all # View the whole manifest

# --- 2. Installation Lifecycle ---
# Install the package. This will copy the file and create the symlink.
pkgx install fx.semver

# Verify the outcome.
ls -l ~/.my/lib/tmp/semver.sh   # Check that the library file exists.
ls -l ~/.my/bin/tmp/semver     # Check that the symlink exists.
pkgx status fx.semver          # Status should now be INSTALLED.

# --- 3. Disable / Enable Cycle ---
# Disable the package. This removes the symlink but keeps the lib file.
pkgx disable fx.semver

# Verify the outcome.
ls -l ~/.my/bin/tmp/semver     # This command should now fail (file not found).
pkgx status fx.semver          # Status should now be DISABLED.

# Enable the package. This re-creates the symlink.
pkgx enable fx.semver

# Verify the outcome.
ls -l ~/.my/bin/tmp/semver     # Link should exist again.
pkgx status fx.semver          # Status should be INSTALLED.

# --- 4. Uninstall / Restore Cycle ---
# Uninstall the package. Removes both link and library file.
pkgx uninstall fx.semver

# Verify the outcome.
ls -l ~/.my/lib/tmp/semver.sh   # This should fail.
ls -l ~/.my/bin/tmp/semver     # This should fail.
pkgx status fx.semver          # Status should be REMOVED.

# Restore the package. Re-installs using manifest data.
pkgx restore fx.semver

# Verify the outcome.
ls -l ~/.my/lib/tmp/semver.sh   # File should be back.
ls -l ~/.my/bin/tmp/semver     # Link should be back.
pkgx status fx.semver          # Status should be INSTALLED.

# --- 5. Final Cleanup ---
# Uninstall one last time to prepare for cleaning.
pkgx uninstall fx.semver

# Clean the package entry from the manifest permanently.
pkgx clean fx.semver

# Verify the outcome.
pkgx status fx.semver          # This command should now fail, stating the package is not in the manifest.
pkgx status all                # The semver row should be gone.
