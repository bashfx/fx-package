#!/usr/bin/env bash
#
# ----- packagex-v2.1-SKELETON_SENTINEL | lines: 309 | functions: 20 | readonly_vars: 10 | option_vars: 7 ----- #
#
# packagex: A utility to manage a non-destructive workspace of local bash scripts.
#

# --- META & PORTABLE ---
#
# meta:
#   version: v2.1.0
#   author: BashFX
#
# portable:
#   git, cp, mkdir, ln, rm, sha256sum
# builtins:
#   printf, echo, readonly, local, case, while, shift, declare, awk, grep, sed, sort

# --- CONFIGURATION ---

readonly APP_NAME="packagex";
readonly ALIAS_NAME="pkgx";
readonly SRC_TREE=""; # IMPORTANT: User must set this path.
readonly WORK_DIR="${SRC_TREE}/.work";
readonly TARGET_BASE_DIR="${HOME}/.my";
readonly TARGET_NAMESPACE="tmp";
readonly TARGET_LIB_DIR="${TARGET_BASE_DIR}/lib";
readonly TARGET_BIN_DIR="${TARGET_BASE_DIR}/bin";
readonly MANIFEST_PATH="${HOME}/.pkg_manifest";
readonly BUILD_START_NUMBER=1000;

opt_debug=0;
opt_trace=0;
opt_quiet=0;
opt_force=0;
opt_yes=0;
QUIET_MODE=0;
DEV_MODE=0;


# --- HELPERS ---

stderr() { if [[ "$QUIET_MODE" -eq 1 ]]; then return 0; fi; printf "%s\n" "$*" >&2; }
noop() { :; }
is_dev() { [[ "$DEV_MODE" -eq 1 ]]; }


# --- DEV HELPERS ---

__low_inspect(){
	local pattern="^(${1:-do_})";
	if [[ $# -gt 1 ]]; then pattern="^($1"; shift; for p in "$@"; do pattern+="|$p"; done; pattern+=")"; fi
	declare -F | awk '{print $3}' | grep -E "$pattern" | sed 's/^/ /' | sort;
}

dev_dispatch() {
    local func_to_call="$1"; shift;
    if [[ "$func_to_call" == "func" ]]; then stderr "Available functions:"; __low_inspect _ __ do_; exit 0; fi;
    if [[ $(type -t "$func_to_call") == "function" ]]; then
        stderr "--- DEV CALL: $func_to_call $* ---"; "$func_to_call" "$@"; local ret=$?;
        stderr "--- END DEV CALL (Exit: $ret) ---"; exit "$ret";
    else
        stderr "Error: Function '$func_to_call' not found."; exit 1;
    fi;
}

# --- IMPLEMENTATION STUBS (from PRD v2.1) ---

#-------------------------------------------------------------------------------
# @_get_true_source_path
#-------------------------------------------------------------------------------
_get_true_source_path() {
    local pkg_name="$1";
    local prefix=${pkg_name%%.*};
    local script_name=${pkg_name#*.};

    if [[ "$pkg_name" == "$prefix" || -z "$script_name" ]]; then
        stderr "Error: Invalid package name format: '$pkg_name'. Expected 'prefix.name'.";
        return 1;
    fi;
    
    if [[ "$prefix" == "util" ]]; then
        prefix="utils";
    fi;

    printf "%s" "${SRC_TREE}/pkgs/${prefix}/${script_name}/${script_name}.sh";
    return 0;
}

#-------------------------------------------------------------------------------
# @_prepare_workspace_for_pkg
#-------------------------------------------------------------------------------
_prepare_workspace_for_pkg() {
    local pkg_name="$1";
    local true_source_path;
    true_source_path=$(_get_true_source_path "$pkg_name");
    if [[ ! -r "$true_source_path" ]]; then
        stderr "Error: Pristine source file not found at '$true_source_path'.";
        return 1;
    fi;

    if ! __create_workspace_dir "$pkg_name"; then
        return 1;
    fi;

    local working_copy_path;
    working_copy_path=$(_get_workspace_path "$pkg_name" "pkg");
    if ! __create_working_copy "$true_source_path" "$working_copy_path"; then
        return 1;
    fi;

    local pristine_backup_path;
    pristine_backup_path=$(_get_workspace_path "$pkg_name" "orig");
    if ! __create_pristine_backup "$true_source_path" "$pristine_backup_path"; then
        return 1;
    fi;

    return 0;
}

#-------------------------------------------------------------------------------
# @_get_workspace_path
#-------------------------------------------------------------------------------
_get_workspace_path() {
    local pkg_name="$1";
    local type="$2"; # "pkg" or "orig"
    local prefix=${pkg_name%%.*};
    
    printf "%s" "${WORK_DIR}/${prefix}/${pkg_name}.${type}.sh";
    return 0;
}

#-------------------------------------------------------------------------------
# @__create_workspace_dir
#-------------------------------------------------------------------------------
__create_workspace_dir() {
    local pkg_name="$1";
    local prefix=${pkg_name%%.*};
    local dir_path="${WORK_DIR}/${prefix}";

    if [[ ! -d "$dir_path" ]]; then
        mkdir -p "$dir_path";
        if [[ $? -ne 0 ]]; then
            stderr "Error: Failed to create workspace directory: $dir_path";
            return 1;
        fi;
    fi;
    return 0;
}

#-------------------------------------------------------------------------------
# @__create_working_copy
#-------------------------------------------------------------------------------
__create_working_copy() {
    local src_path="$1";
    local dest_path="$2";
    cp -p "$src_path" "$dest_path";
    if [[ $? -ne 0 ]]; then
        stderr "Error: Failed to create working copy at '$dest_path'.";
        return 1;
    fi;
    return 0;
}

#-------------------------------------------------------------------------------
# @__create_pristine_backup
#-------------------------------------------------------------------------------
__create_pristine_backup() {
    local src_path="$1";
    local dest_path="$2";
    cp -p "$src_path" "$dest_path";
    if [[ $? -ne 0 ]]; then
        stderr "Error: Failed to create pristine backup at '$dest_path'.";
        return 1;
    fi;
    return 0;
}

#-------------------------------------------------------------------------------
# @_enrich_working_copy
#-------------------------------------------------------------------------------
_enrich_working_copy() {
    local pkg_name="$1";
    local working_copy_path;
    working_copy_path=$(_get_workspace_path "$pkg_name" "pkg");

    # 1. READ
    declare -A meta_map;
    _get_all_header_meta "$working_copy_path" meta_map;

    # 2. MODIFY
    declare -A canonical_map;
    _get_canonical_meta "$pkg_name" canonical_map;

    # Merge canonical values into the main map, overwriting where necessary
    for key in "${!canonical_map[@]}"; do
        meta_map["$key"]="${canonical_map[$key]}";
    done

    # 3. WRITE
    if ! __write_header_block "$working_copy_path" meta_map; then
        stderr "Error: Failed to write enriched header block.";
        return 1;
    fi;

    return 0;
}

#-------------------------------------------------------------------------------
# @_get_all_header_meta
#-------------------------------------------------------------------------------
_get_all_header_meta() {
    local path="$1";
    local -n map_ref="$2"; # Nameref to the associative array
    map_ref=();

    if [[ ! -r "$path" ]]; then return 1; fi;

    while read -r line; do
        if [[ "$line" =~ ^#\s*([a-zA-Z0-9_]+):[[:space:]]*(.*)$ ]]; then
            local key="${BASH_REMATCH[1]}";
            local value="${BASH_REMATCH[2]}";
            map_ref["$key"]="$value";
        fi;
    done < <(grep -E "^#\s*[a-zA-Z0-9_]+:" "$path");

    return 0;
}

#-------------------------------------------------------------------------------
# @_get_canonical_meta
#-------------------------------------------------------------------------------
_get_canonical_meta() {
    local pkg_name="$1";
    local -n map_ref="$2"; # Nameref to the associative array
    map_ref=();
    
    local working_path;
    working_path=$(_get_workspace_path "$pkg_name" "pkg");
    local true_path;
    true_path=$(_get_true_source_path "$pkg_name");

    # These are the fields that packagex calculates and manages.
    map_ref["pkg_name"]="$pkg_name";
    map_ref["path"]="$true_path";
    map_ref["checksum"]=$(__get_file_checksum "$working_path");
    
    # Provide sensible defaults for core fields if they don't exist
    local ver; ver=$(__get_header_meta "$working_path" "version");
    map_ref["version"]="${ver:-v0.1.0}";
    
    local alias; alias=$(__get_header_meta "$working_path" "alias");
    map_ref["alias"]="${alias:-${pkg_name#*.}}";

    return 0;
}

#-------------------------------------------------------------------------------
# @__write_header_block
#-------------------------------------------------------------------------------
__write_header_block() {
    local path="$1";
    local -n data_map_ref="$2";
    local header_content;
    
    # Check if a meta block already exists to replace it
    if grep -q "# --- META ---" "$path"; then
        header_content+="\n#\n# --- META ---\n#\n# meta:\n";
        for key in $(printf "%s\n" "${!data_map_ref[@]}" | sort); do
            header_content+=$(printf "#   %s: %s\n" "$key" "${data_map_ref[$key]}");
        done
        header_content+="#\n";
        sed -i "/^# --- META ---$/,/^#\s*$/c\\${header_content}" "$path";
    else
        # If no block exists, inject a new one after the shebang
        header_content+='\n#\n# --- META ---\n#\n# meta:\n';
        for key in $(printf "%s\n" "${!data_map_ref[@]}" | sort); do
            header_content+=$(printf '#   %s: %s\n' "$key" "${data_map_ref[$key]}");
        done
        header_content+='#\n';
        sed -i "2r /dev/stdin" "$path" <<< "$header_content";
    fi;

    return $?;
}

#-------------------------------------------------------------------------------
# @_display_meta_array
#-------------------------------------------------------------------------------
_display_meta_array() {
    local -n map_ref="$1"; # Nameref to the associative array

    if [[ ${#map_ref[@]} -eq 0 ]]; then
        stderr "Notice: No metadata to display.";
        return 0;
    fi;

    # Print sorted keys and their values
    for key in $(printf "%s\n" "${!map_ref[@]}" | sort); do
        printf "%s: %s\n" "$key" "${map_ref[$key]}";
    done

    return 0;
}

# Milestone 2: State Persistence & Deployment
# implement _register_package | Ensures workspace is prepared, then builds and writes the manifest row.
# implement __write_manifest_row | Low-level writer that appends or updates a row in the manifest file.
# implement _get_manifest_row | Input: pkg_name. Output: The raw manifest line for the package.
# implement _display_status_info | Input: row_string. Formats and prints manifest data for the user.
# implement _deploy_package | Copies the working copy to lib and creates the symlink in bin.
# implement _update_manifest_status | A dedicated helper to update only the status field in the manifest.
# implement __copy_to_lib | A wrapper around cp to copy the working copy to its final lib destination.
# implement __create_bin_symlink | A wrapper around ln -s to create the executable symlink.

# Milestone 3: Symmetrical Lifecycle & Maintenance
# implement _deactivate_package | Core logic for uninstall. Removes symlink and lib file.
# implement __remove_bin_symlink | Removes the executable symlink from bin.
# implement __remove_lib_file | Removes the script file from lib.
# implement _purge_package | Core logic for clean. Removes manifest row AND workspace assets.
# implement __remove_manifest_row | Removes the entire row for a package from the manifest.
# implement __remove_from_workspace | Removes both .pkg.sh and .orig.sh files from the workspace.
# implement _is_update_required | Compares checksum of pristine source vs. workspace backup.
# implement _re_register_package | Core logic for update. Removes old workspace assets and re-runs the full registration flow.


# --- API FUNCTIONS (v2.1) ---

# M1 Commands
function do_prepare() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then
        usage;
        return 1;
    fi;

    stderr "Preparing workspace for '$pkg_name'...";
    if ! _prepare_workspace_for_pkg "$pkg_name"; then
        stderr "Workspace preparation failed.";
        return 1;
    fi;

    stderr "Workspace for '$pkg_name' is ready.";
    return 0;
}
function do_normalize() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then
        usage;
        return 1;
    fi;

    stderr "Normalizing (enriching) workspace for '$pkg_name'...";
    if ! _enrich_working_copy "$pkg_name"; then
        stderr "Normalization failed.";
        return 1;
    fi;

    stderr "Normalization complete.";
    return 0;
}
function do_meta() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then
        usage;
        return 1;
    fi;

    local working_copy_path;
    working_copy_path=$(_get_workspace_path "$pkg_name" "pkg");

    if [[ ! -r "$working_copy_path" ]]; then
        stderr "Error: Workspace for '$pkg_name' has not been prepared. Run 'prepare' first.";
        return 1;
    fi;

    declare -A meta_map;
    _get_all_header_meta "$working_copy_path" meta_map;
    
    _display_meta_array meta_map;
    return $?;
}

# M2 Commands
function do_register() { # Calls: _register_package
    noop; }
function do_status() { # Calls: _get_manifest_row, _display_status_info
    noop; }
function do_install() { # Calls: _deploy_package
    noop; }

# M3 Commands
function do_uninstall() { # Calls: _deactivate_package
    noop; }
function do_disable() { # Calls: __remove_bin_symlink, _update_manifest_status
    noop; }
function do_enable() { # Calls: __create_bin_symlink, _update_manifest_status
    noop; }
function do_clean() { # Calls: _purge_package
    noop; }
function do_update() { # Calls: _is_update_required, _re_register_package
    noop; }
function do_restore() { # Calls: _deploy_package (re-uses install logic)
    noop; }


# --- CORE FUNCTIONS ---

function usage() {
    printf "Usage: %s <command> [options] <package_name>\n" "$APP_NAME";
    printf "  A utility to manage a non-destructive workspace of local bash scripts.\n\n";
    printf "  Workspace Commands:\n";
    printf "    prepare   [M1] Creates the workspace for a package.\n";
    printf "    normalize [M1] Enriches the header of a package's working copy.\n";
    printf "    update    [M3] Refreshes workspace from the pristine source file.\n\n";
    printf "  Lifecycle Commands:\n";
    printf "    register  [M2] Writes a prepared package's state to the manifest.\n";
    printf "    install   [M2] Deploys a registered package to your system.\n";
    printf "    uninstall [M3] Deactivates a package and removes deployed files.\n";
    printf "    clean     [M3] Purges all records and files for a package.\n\n";
    printf "  Inspection & Utility Commands:\n";
    printf "    status    [M2] Shows a package's status from the manifest.\n";
    printf "    meta      [M1] Reads a package's enriched header from the workspace.\n";
    printf "    enable    [M3] Re-links a disabled package.\n";
    printf "    disable   [M3] Unlinks an installed package.\n";
    printf "    restore   [M3] Re-installs a package from its workspace cache.\n\n";
}

function options() {
    # Per MVP, -D is not implemented. DEV_MODE is set via environment.
    while getopts ":dtqfy" opt; do
        case $opt in
            (d) opt_debug=1;;
            (t) opt_trace=1; opt_debug=1;;
            (q) QUIET_MODE=1; opt_quiet=1;;
            (f) opt_force=1;;
            (y) opt_yes=1;;
            \?) stderr "Error: Invalid option: -$OPTARG" >&2; usage; return 1;;
        esac
    done;
    return 0;
}

function dispatch() {
    local cmd="$1";
    if [[ -z "$cmd" ]]; then usage; return 1; fi;
    shift;

    case "$cmd" in
        (\#)
            if is_dev; then dev_dispatch "$@";
            else stderr "Error: '#' command is only available in DEV_MODE."; return 1; fi;;
        (prepare|normalize|meta|register|status|install|uninstall|disable|enable|clean|update|restore)
            "do_${cmd}" "$@";;
        (*)
            stderr "Error: Unknown command '$cmd'"; usage; return 1;;
    esac;
}

function main() {
    options "$@";
    local shifted_args=("${@:$((OPTIND))}");

    if is_dev && [[ "${shifted_args[0]}" == '$' ]]; then
        local dev_args=("${shifted_args[@]:1}");
        dev_dispatch "${dev_args[@]}";
    fi;

    dispatch "${shifted_args[@]}";
}


# --- MAIN INVOCATION ---

main "$@";
