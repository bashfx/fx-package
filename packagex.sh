#!/usr/bin/env bash
#
# ----- packagex SKELETON_SENTINEL | lines: 329 | functions: 21 | readonly_vars: 10 | option_vars: 8 ----- #
#
# packagex: A utility to manage local bash scripts.
#

# --- META & PORTABLE ---
#
# meta:
#   version: v0.1.0
#   author: BashFX
#
# portable:
#   sha256sum, git, cp, mkdir, ln, rm
# builtins:
#   printf, echo, readonly, local, case, while, shift, declare, awk, grep, sed, sort

# --- CONFIGURATION ---

# These variables define the core paths and settings.
readonly APP_NAME="packagex";
readonly ALIAS_NAME="pkgx";
readonly SRC_TREE=""; # IMPORTANT: User must set this path.
readonly TARGET_BASE_DIR="${HOME}/.my";
readonly TARGET_NAMESPACE="tmp";
readonly TARGET_LIB_DIR="${TARGET_BASE_DIR}/lib";
readonly TARGET_BIN_DIR="${TARGET_BASE_DIR}/bin";
readonly MANIFEST_PATH="${HOME}/.pkg_manifest";
readonly BACKUP_DIR="${SRC_TREE}/.orig";
readonly BUILD_START_NUMBER=1000;

# These variables hold the state of command-line options.
opt_debug=0;
opt_trace=0;
opt_quiet=0;
opt_force=0;
opt_yes=0;
opt_dev=0;
QUIET_MODE=0; # Master quiet mode toggle
DEV_MODE=0;   # Master dev mode toggle


# --- HELPERS ---

################################################################################
#
#  stderr
#
#  Prints messages to the standard error stream. Obeys QUIET_MODE.
#
################################################################################
function stderr() {
    if [[ "$QUIET_MODE" -eq 1 ]]; then
        return 0;
    fi;
    printf "%s\n" "$*" >&2;
}

################################################################################
#
#  noop
#
#  A no-operation function to use as a placeholder in stubs.
#
################################################################################
function noop() {
    :; # This function intentionally does nothing.
}


# --- DEV HELPERS ---

################################################################################
#
#  __low_inspect
#
#  Lists declared functions, optionally filtered by prefix.
#
################################################################################
__low_inspect(){
	local pattern="^(${1:-do_})"; # def to do
	if [[ $# -gt 1 ]]; then
		pattern="^($1"
		shift
		for p in "$@"; do
			pattern+="|$p"
		done
		pattern+=")"
	fi

	declare -F \
		| awk '{print $3}' \
		| grep -E "$pattern" \
		| sed 's/^/ /' \
		| sort;
}

################################################################################
#
#  dev_dispatch
#
#  A pre-dispatcher for developer-mode direct function calls.
#
################################################################################
function dev_dispatch() {
    # This dispatcher only activates if the first argument is '$'
    if [[ "$1" != '$' ]]; then
        return 1;
    fi;
    shift; # Consume '$'

    local func_to_call="$1";
    if [[ -z "$func_to_call" ]]; then
        stderr "Dev Dispatcher: No function specified after '\$'."
        exit 1;
    fi;
    shift; # Consume function name

    # Special case: 'func' command lists available functions
    if [[ "$func_to_call" == "func" ]]; then
        stderr "Available functions:";
        __low_inspect _ __ do_;
        exit 0;
    fi;

    # Check if the requested function exists
    if [[ $(type -t "$func_to_call") == "function" ]]; then
        stderr "--- DEV CALL: $func_to_call $* ---";
        "$func_to_call" "$@";
        local ret=$?;
        stderr "--- END DEV CALL (Exit: $ret) ---";
        exit "$ret";
    else
        stderr "Error: Function '$func_to_call' not found.";
        stderr "Available functions:";
        __low_inspect _ __ do_;
        exit 1;
    fi;
}


# ------------------------------------------------------------------------------
#  Implementation Stubs (from PRD Technical Breakdown)
# ------------------------------------------------------------------------------

# --- Mid-Level Helpers ---

#-------------------------------------------------------------------------------
# @_resolve_pkg_prefix
#-------------------------------------------------------------------------------
_resolve_pkg_prefix() {
    local pkg_dir_name="$1";
    
    # As per PRD, 'utils' directory maps to 'util' prefix.
    case "$pkg_dir_name" in
        (utils)
            printf "%s" "util";
            ;;
        (*)
            printf "%s" "$pkg_dir_name";
            ;;
    esac
    return 0;
}

#-------------------------------------------------------------------------------
# @_gather_package_meta
#-------------------------------------------------------------------------------
_gather_package_meta() {
    local pkg_name="$1";
    local src_path;

    src_path=$(_get_source_path "$pkg_name");
    if [[ ! -r "$src_path" ]]; then
        stderr "Error: Source path for '$pkg_name' not found: $src_path";
        return 1;
    fi;

    # Gather all metadata, providing sensible defaults.
    local ver;
    ver=$(__get_header_meta "$src_path" "version");
    [[ -z "$ver" ]] && ver="v0.1.0";

    local alias;
    alias=$(__get_header_meta "$src_path" "alias");
    [[ -z "$alias" ]] && alias=$(printf "%s" "$pkg_name" | cut -d'.' -f2);

    local deps;
    deps=$(__get_header_meta "$src_path" "deps");
    [[ -z "$deps" ]] && deps="none";
    
    local checksum;
    checksum=$(__get_file_checksum "$src_path");

    # Determine status based on completeness of metadata
    local status="KNOWN";
    if [[ "$ver" == "v0.1.0" || "$alias" == "$(printf "%s" "$pkg_name" | cut -d'.' -f2)" ]]; then
        status="INCOMPLETE";
    fi;

    # The order of fields here MUST match the manifest header.
    # pkg_name, status, version, build, alias, path, checksum, deps
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s" \
        "$pkg_name" \
        "$status" \
        "$ver" \
        "$BUILD_START_NUMBER" \
        "$alias" \
        "$src_path" \
        "$checksum" \
        "$deps";

    return 0;
}

#-------------------------------------------------------------------------------
# @_get_field_index
#-------------------------------------------------------------------------------
_get_field_index() {
    local field_name="$1";
    local header;
    local ret=1;
    local res="";

    header=$(__get_manifest_header);
    if [[ -z "$header" ]]; then
        stderr "Error: Could not read manifest header.";
        return 1;
    fi;

    # Use awk to find the column number of the field name
    res=$(printf "%s" "$header" | awk -v field="$field_name" '
        BEGIN { RS="\t"; }
        { if ($0 == field) { print NR; exit; } }
    ');

    if [[ -n "$res" ]]; then
        ret=0;
    fi;

    printf "%s" "$res";
    return "$ret";
}

#-------------------------------------------------------------------------------
# @_get_manifest_row
#-------------------------------------------------------------------------------
_get_manifest_row() {
    local pkg_name="$1";
    local ret=1;
    local res="";

    # Ensure the global manifest data is loaded
    __read_manifest_file;

    # Grep for the package name at the beginning of a line
    res=$(printf "%s\n" "${MANIFEST_DATA[@]}" | grep -E "^${pkg_name}\t");

    if [[ -n "$res" ]]; then
        ret=0;
    fi;

    printf "%s" "$res";
    return "$ret";
}

#-------------------------------------------------------------------------------
# @_get_manifest_field
#-------------------------------------------------------------------------------
_get_manifest_field() {
    local pkg_name="$1";
    local field_name="$2";
    local ret=1;
    local res="";
    local row;
    local index;

    row=$(_get_manifest_row "$pkg_name");
    if [[ -z "$row" ]]; then
        # This is not an error; the package may not be registered yet.
        return 1;
    fi;

    index=$(_get_field_index "$field_name");
    if [[ -z "$index" ]]; then
        stderr "Error: Field '$field_name' not found in manifest header.";
        return 1;
    fi;

    # Use awk to extract the field by its index
    res=$(printf "%s" "$row" | awk -v idx="$index" -F'\t' '{print $idx}');

    if [[ -n "$res" ]]; then
        ret=0;
    fi;

    printf "%s" "$res";
    return "$ret";
}

#-------------------------------------------------------------------------------
# @_get_source_path
#-------------------------------------------------------------------------------
_get_source_path() {
    local pkg_name="$1";
    local ret=1;
    local res="";
    local prefix;
    local script_name;

    # The prefix is the part before the first '.'
    prefix=$(printf "%s" "$pkg_name" | awk -F'.' '{print $1}');
    # The script name is the part after the first '.'
    script_name=$(printf "%s" "$pkg_name" | awk -F'.' '{print $2}');

    if [[ -z "$prefix" || -z "$script_name" ]]; then
        stderr "Error: Invalid package name format: '$pkg_name'. Expected 'prefix.name'.";
        return 1;
    fi;
    
    # Resolve 'util' to 'utils' for the directory name
    if [[ "$prefix" == "util" ]]; then
        prefix="utils";
    fi;

    res="${SRC_TREE}/pkgs/${prefix}/${script_name}.sh";

    if [[ -f "$res" ]]; then
        ret=0;
    fi;

    printf "%s" "$res";
    return "$ret";
}

#-------------------------------------------------------------------------------
# @_check_git_status
#-------------------------------------------------------------------------------
_check_git_status() {
    local path="$1";

    if ! command -v git &> /dev/null; then
        stderr "Warning: 'git' command not found. Cannot check file status.";
        return 0; # Non-fatal, allow proceeding
    fi;

    # Check if the file is in a git repository
    if ! git -C "$(dirname "$path")" rev-parse --is-inside-work-tree &> /dev/null; then
        return 0; # Not a git repo, nothing to check
    fi;

    local status;
    status=$(git -C "$(dirname "$path")" status --porcelain -- "$path");

    if [[ -n "$status" ]]; then
        stderr "Error: Git status for '$path' is not clean:";
        stderr "$status";
        stderr "Please commit or stash changes before normalizing.";
        return 1;
    fi;

    return 0;
}

#-------------------------------------------------------------------------------
# @_build_manifest_row
#-------------------------------------------------------------------------------
_build_manifest_row() {
    # This function takes all manifest fields as arguments in order.
    # $1: pkg_name, $2: status, $3: version, $4: build, $5: alias, etc.
    local fields=("$@");
    local row="";

    # Build the tab-delimited string
    printf -v row '%s\t' "${fields[@]}";
    
    # Trim the trailing tab and add the EOL marker
    printf "%s" "${row%?}\t::";

    return 0;
}

#-------------------------------------------------------------------------------
# @_update_manifest_field
#-------------------------------------------------------------------------------
_update_manifest_field() {
    local pkg_name="$1";
    local field_name="$2";
    local new_value="$3";
    local field_index;

    field_index=$(_get_field_index "$field_name");
    if [[ -z "$field_index" ]]; then
        stderr "Error: Cannot update. Field '$field_name' not found.";
        return 1;
    fi;

    # Use awk for robust, in-place field replacement.
    # This is safer than sed for variable-based column replacement.
    awk -i inplace -v pkg="$pkg_name" -v idx="$field_index" -v val="$new_value" \
        'BEGIN { FS=OFS="\t" } { if ($1 == pkg) $idx = val; print }' \
        "$MANIFEST_PATH";

    return $?;
}


#-------------------------------------------------------------------------------
# @__backup_file
#-------------------------------------------------------------------------------
__backup_file() {
    local path="$1";

    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR";
        if [[ $? -ne 0 ]]; then
            stderr "Error: Could not create backup directory: $BACKUP_DIR";
            return 1;
        fi;
    fi;

    cp -p "$path" "${BACKUP_DIR}/$(basename "$path").orig";
    return $?;
}

#-------------------------------------------------------------------------------
# @__inject_header
#-------------------------------------------------------------------------------
__inject_header() {
    local path="$1";
    local header_content;

    # Using printf for clean multi-line variable assignment.
    # This defines the standard APP_* variables injected into scripts.
    printf -v header_content '%s\n' \
        '' \
        '# --- AUTO-INJECTED BY packagex ---' \
        'readonly APP_NAME="%s";' \
        'readonly APP_ALIAS="%s";' \
        'readonly APP_VERSION="%s";' \
        'readonly APP_BUILD="%s";' \
        '# --- END ---' \
        '';
    
    # Use sed to insert the block of text at line 2 (after the shebang)
    sed -i "2r /dev/stdin" "$path" <<< "$header_content";
    return $?;
}

#-------------------------------------------------------------------------------
# @__add_row_to_manifest
#-------------------------------------------------------------------------------
__add_row_to_manifest() {
    local row_string="$1";
    local header="pkg_name\tstatus\tversion\tbuild\talias\tpath\tchecksum\tdeps\t::";

    if [[ ! -f "$MANIFEST_PATH" ]]; then
        printf "%s\n" "$header" > "$MANIFEST_PATH";
        if [[ $? -ne 0 ]]; then
            stderr "Error: Could not create manifest file: $MANIFEST_PATH";
            return 1;
        fi;
    fi;

    printf "%s\n" "$row_string" >> "$MANIFEST_PATH";
    return $?;
}

#-------------------------------------------------------------------------------
# @__copy_file
#-------------------------------------------------------------------------------
__copy_file() {
    local src_path="$1";
    local dest_path="$2";
    local dest_dir;

    dest_dir=$(dirname "$dest_path");
    if [[ ! -d "$dest_dir" ]]; then
        mkdir -p "$dest_dir";
        if [[ $? -ne 0 ]]; then
            stderr "Error: Could not create destination directory: $dest_dir";
            return 1;
        fi;
    fi;

    cp -p "$src_path" "$dest_path";
    return $?;
}

#-------------------------------------------------------------------------------
# @__create_symlink
#-------------------------------------------------------------------------------
__create_symlink() {
    local src_path="$1";
    local link_path="$2";
    local link_dir;

    link_dir=$(dirname "$link_path");
     if [[ ! -d "$link_dir" ]]; then
        mkdir -p "$link_dir";
        if [[ $? -ne 0 ]]; then
            stderr "Error: Could not create link directory: $link_dir";
            return 1;
        fi;
    fi;

    # -s for symbolic, -f to overwrite if it exists
    ln -sf "$src_path" "$link_path";
    return $?;
}


#-------------------------------------------------------------------------------
# @_load_package
#-------------------------------------------------------------------------------
_load_package() {
    local pkg_name="$1";
    local src_path;
    local dest_path;

    stderr "Loading package artifacts...";
    src_path=$(_get_source_path "$pkg_name");
    dest_path="${TARGET_LIB_DIR}/${TARGET_NAMESPACE}/$(basename "$src_path")";

    if ! __copy_file "$src_path" "$dest_path"; then
        stderr "Error: Failed to copy '$src_path' to library.";
        return 1;
    fi;

    if ! _update_manifest_field "$pkg_name" "status" "LOADED"; then
        stderr "Error: Failed to update manifest status to LOADED.";
        return 1;
    fi;

    stderr "Package loaded to: $dest_path";
    return 0;
}

#-------------------------------------------------------------------------------
# @_link_package
#-------------------------------------------------------------------------------
_link_package() {
    local pkg_name="$1";
    local src_path;
    local lib_path;
    local link_path;
    local alias;

    stderr "Linking package executable...";
    src_path=$(_get_source_path "$pkg_name");
    alias=$(_get_manifest_field "$pkg_name" "alias");
    
    lib_path="${TARGET_LIB_DIR}/${TARGET_NAMESPACE}/$(basename "$src_path")";
    link_path="${TARGET_BIN_DIR}/${TARGET_NAMESPACE}/${alias}";

    if ! __create_symlink "$lib_path" "$link_path"; then
        stderr "Error: Failed to create symlink at '$link_path'.";
        return 1;
    fi;

    if ! _update_manifest_field "$pkg_name" "status" "INSTALLED"; then
        stderr "Error: Failed to update manifest status to INSTALLED.";
        return 1;
    fi;

    stderr "Package linked to: $link_path";
    return 0;
}


#-------------------------------------------------------------------------------
# @_uninstall_package
#-------------------------------------------------------------------------------
_uninstall_package() {
    local pkg_name="$1";
    local src_path;
    local lib_path;
    local link_path;
    local alias;

    src_path=$(_get_source_path "$pkg_name");
    alias=$(_get_manifest_field "$pkg_name" "alias");
    lib_path="${TARGET_LIB_DIR}/${TARGET_NAMESPACE}/$(basename "$src_path")";
    link_path="${TARGET_BIN_DIR}/${TARGET_NAMESPACE}/${alias}";

    stderr "Removing symlink...";
    if ! __remove_symlink "$link_path"; then return 1; fi;
    
    stderr "Removing library file...";
    if ! __remove_file "$lib_path"; then return 1; fi;

    _update_manifest_field "$pkg_name" "status" "REMOVED";

    return 0;
}


#-------------------------------------------------------------------------------
# @_confirm_action
#-------------------------------------------------------------------------------
_confirm_action() {
    local prompt_string="$1";
    local answer;

    # If -y flag is passed, automatically confirm.
    if [[ "$opt_yes" -eq 1 ]]; then
        return 0;
    fi;

    read -r -p "$prompt_string [y/N] " answer;
    case "$answer" in
        (y|Y)
            return 0;
            ;;
        (*)
            return 1;
            ;;
    esac;
}




__get_file_checksum() {
    local path="$1";
    local ret=1;
    local res="";

    if [[ ! -r "$path" ]]; then
        stderr "Error: File not found or not readable: $path";
        return 1;
    fi;

    res=$(sha256sum "$path" 2>/dev/null | awk '{print $1}');
    if [[ -n "$res" ]]; then
        ret=0;
    fi;

    printf "%s" "$res";
    return "$ret";
}



#-------------------------------------------------------------------------------
# @__get_header_meta
#-------------------------------------------------------------------------------
__get_header_meta() {
    local path="$1";
    local key="$2";
    local ret=1;
    local res="";

    if [[ ! -r "$path" ]]; then
        stderr "Error: File not found or not readable: $path";
        return 1;
    fi;

    # Grep for the key in comments, get the first match, then extract the value.
    res=$(grep -E "^#\s*${key}:" "$path" | head -n 1 | awk -F': ' '{print $2}');

    if [[ -n "$res" ]]; then
        ret=0;
    fi;

    printf "%s" "$res";
    return "$ret";
}

#-------------------------------------------------------------------------------
# @__read_manifest_file
#-------------------------------------------------------------------------------
__read_manifest_file() {
    # This function populates the global MANIFEST_DATA array.
    # It's memoized; it only reads the file once per script execution.
    if [[ ${#MANIFEST_DATA[@]} -gt 0 ]]; then
        return 0;
    fi;

    if [[ ! -r "$MANIFEST_PATH" ]]; then
        # It's not an error for the manifest to not exist yet.
        return 1;
    fi;

    # Read the file line by line into the global array.
    mapfile -t MANIFEST_DATA < "$MANIFEST_PATH";
    return 0;
}

#-------------------------------------------------------------------------------
# @__get_manifest_header
#-------------------------------------------------------------------------------
__get_manifest_header() {
    # This function returns the header line of the manifest.
    # It's memoized; it only reads the file once.
    if [[ -n "$MANIFEST_HEADER" ]]; then
        printf "%s" "$MANIFEST_HEADER";
        return 0;
    fi;

    if [[ ! -r "$MANIFEST_PATH" ]]; then
        return 1;
    fi;

    # Read the first line and cache it in a global variable.
    read -r MANIFEST_HEADER < "$MANIFEST_PATH";
    printf "%s" "$MANIFEST_HEADER";
    return 0;
}


#-------------------------------------------------------------------------------
# @__remove_symlink
#-------------------------------------------------------------------------------
__remove_symlink() {
    local link_path="$1";

    if [[ -L "$link_path" ]]; then
        rm "$link_path";
        if [[ $? -ne 0 ]]; then
            stderr "Error: Failed to remove symlink: $link_path";
            return 1;
        fi;
    else
        # It's not an error if the link is already gone.
        stderr "Notice: Symlink not found at $link_path, nothing to remove.";
    fi;

    return 0;
}



#-------------------------------------------------------------------------------
# @__remove_file
#-------------------------------------------------------------------------------
__remove_file() {
    local path="$1";
    
    if [[ -f "$path" ]]; then
        rm "$path";
        if [[ $? -ne 0 ]]; then
            stderr "Error: Failed to remove file: $path";
            return 1;
        fi;
    else
        stderr "Notice: File not found at $path, nothing to remove.";
    fi;

    return 0;
}


#-------------------------------------------------------------------------------
# @__remove_row_from_manifest
#-------------------------------------------------------------------------------
__remove_row_from_manifest() {
    local pkg_name="$1";
    
    # Use sed to find and delete the line starting with the package name.
    sed -i "/^${pkg_name}\t/d" "$MANIFEST_PATH";
    return $?;
}


# --- API FUNCTIONS ---

#-------------------------------------------------------------------------------
# @do_install
#-------------------------------------------------------------------------------
do_install() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then
        stderr "Error: install command requires a package name.";
        usage;
        return 1;
    fi;

    local status;
    status=$(_get_manifest_field "$pkg_name" "status");

    if [[ -z "$status" ]]; then
        stderr "Package '$pkg_name' not in manifest. Registering first...";
        if ! do_register "$pkg_name"; then
            stderr "Installation failed during registration.";
            return 1;
        fi;
        status=$(_get_manifest_field "$pkg_name" "status");
    fi;

    if [[ "$status" == "INSTALLED" && "$opt_force" -eq 0 ]]; then
        stderr "Package '$pkg_name' is already installed. Use -f to force.";
        return 0;
    fi;

    if [[ "$status" == "REMOVED" ]]; then
        stderr "Package '$pkg_name' was previously uninstalled. Use 'restore' to proceed.";
        return 1;
    fi;

    # --- Load Step ---
    if [[ "$status" != "LOADED" ]]; then
        if ! _load_package "$pkg_name"; then
            stderr "Installation failed during load step.";
            return 1;
        fi;
    fi;

    # --- Link Step ---
    if ! _link_package "$pkg_name"; then
        stderr "Installation failed during link step.";
        return 1;
    fi;

    stderr "Installation of '$pkg_name' complete.";
    do_status "$pkg_name";
    return 0;
}

#-------------------------------------------------------------------------------
# @do_disable
#-------------------------------------------------------------------------------
do_disable() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then
        stderr "Error: disable command requires a package name.";
        usage;
        return 1;
    fi;

    local status;
    status=$(_get_manifest_field "$pkg_name" "status");
    if [[ "$status" != "INSTALLED" ]]; then
        stderr "Error: Package '$pkg_name' is not in INSTALLED state (current: $status).";
        return 1;
    fi;

    local alias;
    alias=$(_get_manifest_field "$pkg_name" "alias");
    local link_path="${TARGET_BIN_DIR}/${TARGET_NAMESPACE}/${alias}";

    if ! __remove_symlink "$link_path"; then
        return 1;
    fi;
    
    _update_manifest_field "$pkg_name" "status" "DISABLED";
    
    stderr "Package '$pkg_name' has been disabled.";
    do_status "$pkg_name";
    return 0;
}

#-------------------------------------------------------------------------------
# @do_enable
#-------------------------------------------------------------------------------
do_enable() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then
        stderr "Error: enable command requires a package name.";
        usage;
        return 1;
    fi;

    local status;
    status=$(_get_manifest_field "$pkg_name" "status");
    if [[ "$status" != "DISABLED" ]]; then
        stderr "Error: Package '$pkg_name' is not in DISABLED state (current: $status).";
        return 1;
    fi;
    
    # Re-use the existing link helper; it sets status to INSTALLED.
    if ! _link_package "$pkg_name"; then
        stderr "Error: Failed to re-link package.";
        return 1;
    fi;

    stderr "Package '$pkg_name' has been enabled.";
    do_status "$pkg_name";
    return 0;
}

#-------------------------------------------------------------------------------
# @do_uninstall
#-------------------------------------------------------------------------------
do_uninstall() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then
        stderr "Error: uninstall command requires a package name.";
        usage;
        return 1;
    fi;

    local status;
    status=$(_get_manifest_field "$pkg_name" "status");

    if [[ "$status" != "INSTALLED" && "$status" != "DISABLED" ]]; then
        stderr "Error: Package '$pkg_name' cannot be uninstalled. Current state: $status";
        return 1;
    fi;

    if ! _uninstall_package "$pkg_name"; then
        stderr "Uninstall failed.";
        return 1;
    fi;

    stderr "Package '$pkg_name' has been uninstalled.";
    do_status "$pkg_name";
    return 0;
}

#-------------------------------------------------------------------------------
# @do_restore
#-------------------------------------------------------------------------------
do_restore() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then
        stderr "Error: restore command requires a package name.";
        usage;
        return 1;
    fi;

    local status;
    status=$(_get_manifest_field "$pkg_name" "status");
    if [[ "$status" != "REMOVED" ]]; then
        stderr "Error: Package '$pkg_name' is not in REMOVED state (current: $status).";
        return 1;
    fi;

    stderr "Restoring package from manifest data...";

    # Re-use the existing load and link helpers.
    if ! _load_package "$pkg_name"; then
        stderr "Restore failed during load step.";
        return 1;
    fi;

    if ! _link_package "$pkg_name"; then
        stderr "Restore failed during link step.";
        return 1;
    fi;

    stderr "Package '$pkg_name' has been restored.";
    do_status "$pkg_name";
    return 0;
}

#-------------------------------------------------------------------------------
# @do_clean
#-------------------------------------------------------------------------------
do_clean() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then
        stderr "Error: clean command requires a package name.";
        usage;
        return 1;
    fi;

    local status;
    status=$(_get_manifest_field "$pkg_name" "status");
    if [[ "$status" != "REMOVED" ]]; then
        stderr "Error: Package '$pkg_name' is not in REMOVED state (current: $status).";
        return 1;
    fi;

    local prompt="This will permanently remove '$pkg_name' from the manifest. This cannot be undone. Continue?";
    if ! _confirm_action "$prompt"; then
        stderr "Clean operation aborted by user.";
        return 1;
    fi;

    if ! __remove_row_from_manifest "$pkg_name"; then
        stderr "Error: Failed to remove row from manifest.";
        return 1;
    fi;
    
    stderr "Package '$pkg_name' has been cleaned from the manifest.";
    return 0;
}

#-------------------------------------------------------------------------------
# @do_status
#-------------------------------------------------------------------------------
do_status() {
    local pkg_target="$1";
    local ret=1;

    if [[ -z "$pkg_target" ]]; then
        stderr "Error: status command requires a package name or 'all'.";
        usage;
        return 1;
    fi;

    # Ensure manifest data is loaded into memory
    __read_manifest_file;
    if [[ $? -ne 0 ]]; then
        stderr "Notice: Manifest file not found or is empty.";
        return 1;
    fi;

    local header;
    header=$(__get_manifest_header);
    printf "%s\n" "$header";

    if [[ "$pkg_target" == "all" ]]; then
        # Print all rows except the header
        printf "%s\n" "${MANIFEST_DATA[@]}" | tail -n +2;
        ret=0;
    else
        local row;
        row=$(_get_manifest_row "$pkg_target");
        if [[ -n "$row" ]]; then
            printf "%s\n" "$row";
            ret=0;
        else
            stderr "Error: Package '$pkg_target' not found in manifest.";
        fi;
    fi;

    return "$ret";
}

#-------------------------------------------------------------------------------
# @do_meta
#-------------------------------------------------------------------------------
do_meta() {
    local pkg_name="$1";
    local ret=1;
    local src_path;

    if [[ -z "$pkg_name" ]]; then
        stderr "Error: meta command requires a package name.";
        usage;
        return 1;
    fi;

    src_path=$(_get_source_path "$pkg_name");
    if [[ ! -r "$src_path" ]]; then
        stderr "Error: Source file for '$pkg_name' not found at: $src_path";
        return 1;
    fi;

    # Find all '# key: value' pairs in the file and format them.
    grep -E "^#\s*[a-zA-Z0-9_]+:" "$src_path" \
        | sed -e 's/^#\s*//' -e 's/:\s*/: /';

    # Check if grep found anything
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        ret=0;
    fi;
    
    return "$ret";
}
#-------------------------------------------------------------------------------
# @do_normalize
#-------------------------------------------------------------------------------
do_normalize() {
    local pkg_name="$1";
    local src_path;

    if [[ -z "$pkg_name" ]]; then
        stderr "Error: normalize command requires a package name.";
        usage;
        return 1;
    fi;

    src_path=$(_get_source_path "$pkg_name");
    if [[ ! -w "$src_path" ]]; then
        stderr "Error: Source file for '$pkg_name' not found or not writable: $src_path";
        return 1;
    fi;

    if [[ "$opt_force" -eq 0 ]]; then
        if ! _check_git_status "$src_path"; then
            return 1;
        fi;
    fi;

    stderr "Backing up original file...";
    if ! __backup_file "$src_path"; then
        stderr "Error: Failed to back up file.";
        return 1;
    fi;

    stderr "Injecting standard header...";
    if ! __inject_header "$src_path"; then
        stderr "Error: Failed to inject header.";
        # Consider a restore step here in the future.
        return 1;
    fi;

    stderr "Normalization complete for '$pkg_name'.";
    return 0;
}

#-------------------------------------------------------------------------------
# @do_register
#-------------------------------------------------------------------------------
do_register() {
    local pkg_name="$1";
    local meta_data;

    if [[ -z "$pkg_name" ]]; then
        stderr "Error: register command requires a package name.";
        usage;
        return 1;
    fi;
    
    stderr "Gathering metadata for '$pkg_name'...";
    meta_data=$(_gather_package_meta "$pkg_name");
    if [[ $? -ne 0 ]]; then
        # _gather_package_meta prints its own errors
        return 1;
    fi;
    
    local new_row;
    new_row=$(_build_manifest_row $meta_data);

    local existing_row;
    existing_row=$(_get_manifest_row "$pkg_name");

    if [[ -n "$existing_row" ]]; then
        stderr "Updating existing entry in manifest...";
        # Use sed to replace the existing line. The & is escaped to handle paths.
        sed -i "s|^${pkg_name}\t.*|${new_row//&/\\&}|" "$MANIFEST_PATH";
    else
        stderr "Adding new entry to manifest...";
        __add_row_to_manifest "$new_row";
    fi;
    
    if [[ $? -eq 0 ]]; then
        stderr "Registration complete.";
        do_status "$pkg_name"; # Show the result
    else
        stderr "Error: Failed to write to manifest.";
        return 1;
    fi;

    return 0;
}

################################################################################
#  do_update <pkg_name>
################################################################################
function do_update() {
    # Calls: (TBD, likely checksum comparison and copy logic)
    noop;
}

################################################################################
#  do_checksum <pkg_name>
################################################################################
function do_checksum() {
    # Calls: (TBD, likely checksum comparison logic)
    noop;
}

################################################################################
#
#  driver
#
#  A dedicated function for simple, ad-hoc tests. Not for production.
#
################################################################################
function driver() {
    stderr "--- RUNNING DRIVER ---";
    # Add simple test calls here
    noop;
    stderr "--- DRIVER FINISHED ---";
}


# --- CORE FUNCTIONS ---

################################################################################
#
#  usage
#
#  Displays the help text for the script.
#
################################################################################
function usage() {
    printf "Usage: %s <command> [options] [arguments]\n" "$APP_NAME";
    printf "\n";
    printf "  A utility to manage local bash scripts.\n";
    printf "\n";
    printf "Commands:\n";
    printf "  install <pkg>     Install a package.\n";
    printf "  uninstall <pkg>   Uninstall a package.\n";
    printf "  enable <pkg>      Enable a disabled package (relinks).\n";
    printf "  disable <pkg>     Disable an installed package (unlinks).\n";
    printf "  status <pkg|all>  Check the status of package(s).\n";
    printf "  meta <pkg>        Read a script's header metadata.\n";
    printf "  normalize <pkg>   Inject standard header into a source script.\n";
    printf "  register <pkg>    Add/update a package's entry in the manifest.\n";
    printf "  restore <pkg>     Re-install a package marked as REMOVED.\n";
    printf "  clean <pkg>       Purge a REMOVED package from the manifest.\n";
    printf "  update <pkg>      Propagate changes from source to installed.\n";
    printf "  checksum <pkg>    Compare source and installed file checksums.\n";
    printf "\n";
    return 0;
}


#-------------------------------------------------------------------------------
# @options
#-------------------------------------------------------------------------------
options() {
    # Set option defaults
    opt_debug=0;
    opt_trace=0;
    opt_quiet=0;
    opt_force=0;
    opt_yes=0;
    opt_dev=0;

    while getopts ":dtqfyD" opt; do
        case $opt in
            (d) opt_debug=1;;
            (t) opt_trace=1; opt_debug=1;; # Trace implies debug
            (q) QUIET_MODE=1; opt_quiet=1;;
            (f) opt_force=1;;
            (y) opt_yes=1;;
            (D) DEV_MODE=1; opt_dev=1; opt_debug=1; opt_trace=1;; # Dev implies all verbosity
            \?)
                stderr "Error: Invalid option: -$OPTARG" >&2;
                usage;
                return 1;
                ;;
        esac
    done;

    # Shift away the parsed options
    shift $((OPTIND - 1));
    return 0;
}

################################################################################
#
#  dispatch
#
#  Routes commands to the appropriate 'do_*' functions.
#
################################################################################
function dispatch() {
    local cmd="$1";
    if [[ -z "$cmd" ]]; then
        usage;
        return 1;
    fi;
    shift;

    case "$cmd" in
        (install)     do_install "$@";;
        (uninstall)   do_uninstall "$@";;
        (enable)      do_enable "$@";;
        (disable)     do_disable "$@";;
        (status)      do_status "$@";;
        (meta)        do_meta "$@";;
        (normalize)   do_normalize "$@";;
        (register)    do_register "$@";;
        (restore)     do_restore "$@";;
        (clean)       do_clean "$@";;
        (update)      do_update "$@";;
        (checksum)    do_checksum "$@";;
        (driver)      driver "$@";; # Internal test driver
        (*)
            printf "Error: Unknown command '%s'\n\n" "$cmd";
            usage;
            return 1;
            ;;
    esac;
}


################################################################################
#
#  main
#
#  The main entrypoint for the script.
#
################################################################################
function main() {
    # First, parse all command-line options.
    options "$@";

    # If in DEV_MODE, attempt to use the dev dispatcher first.
    # The dev_dispatch function will exit the script if it successfully
    # handles the command (i.e., if the first arg is '$').
    if [[ "$DEV_MODE" -eq 1 ]]; then
        dev_dispatch "$@";
    fi;

    # If not in dev mode, or if the dev dispatcher didn't activate,
    # proceed with the normal command dispatch.
    local cmd_and_args=("$@");
    dispatch "${cmd_and_args[@]}";
}


# --- MAIN INVOCATION ---

main "$@";
