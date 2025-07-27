#!/usr/bin/env bash
#
# ----- packagex-v2.1-FINAL | lines: 817 | functions: 54 | readonly_vars: 10 | option_vars: 7 ----- #
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
#   git, cp, mkdir, ln, rm, sha256sum, column
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

# --- IMPLEMENTATION (v2.1) ---

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

    map_ref["pkg_name"]="$pkg_name";
    map_ref["path"]="$true_path";
    map_ref["checksum"]=$(__get_file_checksum "$working_path");
    
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
    
    if grep -q "# --- META ---" "$path"; then
        header_content+="\n#\n# --- META ---\n#\n# meta:\n";
        for key in $(printf "%s\n" "${!data_map_ref[@]}" | sort); do
            header_content+=$(printf "#   %s: %s\n" "$key" "${data_map_ref[$key]}");
        done
        header_content+="#\n";
        sed -i "/^# --- META ---$/,/^#\s*$/c\\${header_content}" "$path";
    else
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
    local -n map_ref="$1"; 

    if [[ ${#map_ref[@]} -eq 0 ]]; then
        stderr "Notice: No metadata to display.";
        return 0;
    fi;

    for key in $(printf "%s\n" "${!map_ref[@]}" | sort); do
        printf "%s: %s\n" "$key" "${map_ref[$key]}";
    done

    return 0;
}

#-------------------------------------------------------------------------------
# @_register_package
#-------------------------------------------------------------------------------
_register_package() {
    local pkg_name="$1";
    
    declare -A canonical_map;
    _get_canonical_meta "$pkg_name" canonical_map;

    local manifest_fields=("pkg_name" "status" "version" "build" "alias" "path" "checksum" "deps");
    local row_data=();
    
    canonical_map["status"]="KNOWN";
    canonical_map["build"]="${BUILD_START_NUMBER}";
    
    for field in "${manifest_fields[@]}"; do
        row_data+=("${canonical_map[$field]:-n/a}");
    done

    local row_string;
    printf -v row_string '%s\t' "${row_data[@]}";
    row_string="${row_string%?}\t::";

    if ! __write_manifest_row "$pkg_name" "$row_string"; then
        stderr "Error: Failed to write to manifest.";
        return 1;
    fi;

    return 0;
}

#-------------------------------------------------------------------------------
# @__write_manifest_row
#-------------------------------------------------------------------------------
__write_manifest_row() {
    local pkg_name="$1";
    local row_string="$2";
    local header="pkg_name\tstatus\tversion\tbuild\talias\tpath\tchecksum\tdeps\t::";

    if [[ ! -f "$MANIFEST_PATH" ]]; then
        printf "%s\n" "$header" > "$MANIFEST_PATH";
    fi;

    if grep -q "^${pkg_name}\t" "$MANIFEST_PATH"; then
        sed -i "s|^${pkg_name}\t.*|${row_string//&/\\&}|" "$MANIFEST_PATH";
    else
        printf "%s\n" "$row_string" >> "$MANIFEST_PATH";
    fi;

    return $?;
}

#-------------------------------------------------------------------------------
# @_get_manifest_row
#-------------------------------------------------------------------------------
_get_manifest_row() {
    local pkg_name="$1";
    if [[ ! -r "$MANIFEST_PATH" ]]; then
        return 1;
    fi;
    grep "^${pkg_name}\t" "$MANIFEST_PATH";
    return $?;
}

#-------------------------------------------------------------------------------
# @_display_status_info
#-------------------------------------------------------------------------------
_display_status_info() {
    local row_string="$1";
    local header;
    header=$(_get_manifest_header);
    
    (printf "%s\n" "$header"; printf "%s\n" "$row_string") | column -t -s $'\t';
}

#-------------------------------------------------------------------------------
# @_deploy_package
#-------------------------------------------------------------------------------
_deploy_package() {
    local pkg_name="$1";
    local working_copy_path;
    working_copy_path=$(_get_workspace_path "$pkg_name" "pkg");
    
    if ! __copy_to_lib "$working_copy_path" "$pkg_name"; then
        return 1;
    fi;

    if ! __create_bin_symlink "$pkg_name"; then
        return 1;
    fi;
    
    return 0;
}

#-------------------------------------------------------------------------------
# @_update_manifest_status
#-------------------------------------------------------------------------------
_update_manifest_status() {
    local pkg_name="$1";
    local new_status="$2";

    awk -v pkg="$pkg_name" -v status="$new_status" 'BEGIN {FS=OFS="\t"} {if ($1==pkg) $2=status; print}' "$MANIFEST_PATH" > "${MANIFEST_PATH}.tmp" && mv "${MANIFEST_PATH}.tmp" "$MANIFEST_PATH";
    
    return $?;
}

#-------------------------------------------------------------------------------
# @__copy_to_lib
#-------------------------------------------------------------------------------
__copy_to_lib() {
    local src_path="$1";
    local pkg_name="$2";
    local dest_path="${TARGET_LIB_DIR}/${TARGET_NAMESPACE}/${pkg_name}.sh";

    mkdir -p "$(dirname "$dest_path")";
    cp -p "$src_path" "$dest_path";
    return $?;
}

#-------------------------------------------------------------------------------
# @__create_bin_symlink
#-------------------------------------------------------------------------------
__create_bin_symlink() {
    local pkg_name="$1";
    local row;
    row=$(_get_manifest_row "$pkg_name");
    
    local alias;
    alias=$(printf "%s" "$row" | awk -F'\t' '{print $5}');

    local lib_path="${TARGET_LIB_DIR}/${TARGET_NAMESPACE}/${pkg_name}.sh";
    local bin_path="${TARGET_BIN_DIR}/${TARGET_NAMESPACE}/${alias}";

    mkdir -p "$(dirname "$bin_path")";
    ln -sf "$lib_path" "$bin_path";
    return $?;
}

#-------------------------------------------------------------------------------
# @_deactivate_package
#-------------------------------------------------------------------------------
_deactivate_package() {
    local pkg_name="$1";

    if ! __remove_bin_symlink "$pkg_name"; then
        return 1;
    fi;

    if ! __remove_lib_file "$pkg_name"; then
        return 1;
    fi;

    return 0;
}

#-------------------------------------------------------------------------------
# @__remove_bin_symlink
#-------------------------------------------------------------------------------
__remove_bin_symlink() {
    local pkg_name="$1";
    local row;
    row=$(_get_manifest_row "$pkg_name");
    local alias;
    alias=$(printf "%s" "$row" | awk -F'\t' '{print $5}');
    local bin_path="${TARGET_BIN_DIR}/${TARGET_NAMESPACE}/${alias}";

    if [[ -L "$bin_path" ]]; then
        rm "$bin_path";
    fi;
    return $?;
}

#-------------------------------------------------------------------------------
# @__remove_lib_file
#-------------------------------------------------------------------------------
__remove_lib_file() {
    local pkg_name="$1";
    local lib_path="${TARGET_LIB_DIR}/${TARGET_NAMESPACE}/${pkg_name}.sh";
    
    if [[ -f "$lib_path" ]]; then
        rm "$lib_path";
    fi;
    return $?;
}

#-------------------------------------------------------------------------------
# @_purge_package
#-------------------------------------------------------------------------------
_purge_package() {
    local pkg_name="$1";

    if ! __remove_manifest_row "$pkg_name"; then
        return 1;
    fi;

    if ! __remove_from_workspace "$pkg_name"; then
        return 1;
    fi;

    return 0;
}

#-------------------------------------------------------------------------------
# @__remove_manifest_row
#-------------------------------------------------------------------------------
__remove_manifest_row() {
    local pkg_name="$1";
    
    # Use sed to delete the line starting with the package name.
    sed -i "/^${pkg_name}\t/d" "$MANIFEST_PATH";
    return $?;
}

#-------------------------------------------------------------------------------
# @__remove_from_workspace
#-------------------------------------------------------------------------------
__remove_from_workspace() {
    local pkg_name="$1";
    local pkg_path;
    pkg_path=$(_get_workspace_path "$pkg_name" "pkg");
    local orig_path;
    orig_path=$(_get_workspace_path "$pkg_name" "orig");

    if [[ -f "$pkg_path" ]]; then
        rm "$pkg_path";
    fi;
    if [[ -f "$orig_path" ]]; then
        rm "$orig_path";
    fi;
    
    return 0;
}

#-------------------------------------------------------------------------------
# @_is_update_required
#-------------------------------------------------------------------------------
_is_update_required() {
    local pkg_name="$1";
    local true_source_path;
    true_source_path=$(_get_true_source_path "$pkg_name");
    local orig_path;
    orig_path=$(_get_workspace_path "$pkg_name" "orig");

    if [[ ! -f "$orig_path" ]]; then
        # If no backup exists, an update is implicitly required.
        return 0;
    fi;

    local true_sum;
    true_sum=$(__get_file_checksum "$true_source_path");
    local orig_sum;
    orig_sum=$(__get_file_checksum "$orig_path");

    if [[ "$true_sum" != "$orig_sum" ]]; then
        return 0; # 0 means true, an update is required
    fi;
    
    return 1; # 1 means false, no update needed
}

#-------------------------------------------------------------------------------
# @_re_register_package
#-------------------------------------------------------------------------------
_re_register_package() {
    local pkg_name="$1";

    stderr "Refreshing workspace files from pristine source...";
    if ! _prepare_workspace_for_pkg "$pkg_name"; then
        return 1;
    fi;

    stderr "Re-normalizing and re-registering package...";
    if ! do_normalize "$pkg_name" || ! do_register "$pkg_name"; then
        return 1;
    fi;

    return 0;
}


# --- API FUNCTIONS (v2.1) ---

# M1 Commands
function do_prepare() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    stderr "Preparing workspace for '$pkg_name'...";
    if ! _prepare_workspace_for_pkg "$pkg_name"; then
        stderr "Workspace preparation failed."; return 1;
    fi;
    stderr "Workspace for '$pkg_name' is ready."; return 0;
}
function do_normalize() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    stderr "Normalizing (enriching) workspace for '$pkg_name'...";
    if ! _enrich_working_copy "$pkg_name"; then
        stderr "Normalization failed."; return 1;
    fi;
    stderr "Normalization complete."; return 0;
}
function do_meta() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
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
function do_register() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    stderr "Registering '$pkg_name' to manifest...";
    if ! _register_package "$pkg_name"; then
        stderr "Registration failed."; return 1;
    fi;
    stderr "Registration complete."; return 0;
}
function do_status() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    local row;
    row=$(_get_manifest_row "$pkg_name");
    if [[ -z "$row" ]]; then
        stderr "Package '$pkg_name' not found in manifest."; return 1;
    fi;
    _display_status_info "$row";
    return 0;
}
function do_install() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    local status;
    status=$(_get_manifest_row "$pkg_name" | awk -F'\t' '{print $2}');

    if [[ -z "$status" ]]; then
        stderr "Package '$pkg_name' is not registered. Run 'register' first.";
        return 1;
    fi;

    if [[ "$status" == "INSTALLED" && "$opt_force" -eq 0 ]]; then
        stderr "Package is already installed. Use -f to force re-installation.";
        return 0;
    fi;

    stderr "Deploying '$pkg_name'...";
    if ! _deploy_package "$pkg_name"; then
        stderr "Deployment failed.";
        return 1;
    fi;
    
    if ! _update_manifest_status "$pkg_name" "INSTALLED"; then
        stderr "Warning: Deployment successful, but failed to update manifest status.";
    fi;

    stderr "Installation of '$pkg_name' complete.";
    return 0;
}

# M3 Commands
function do_uninstall() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    local status;
    status=$(_get_manifest_row "$pkg_name" | awk -F'\t' '{print $2}');
    if [[ "$status" != "INSTALLED" && "$status" != "DISABLED" ]]; then
        stderr "Error: Package cannot be uninstalled. Current status: $status";
        return 1;
    fi;
    
    stderr "Deactivating '$pkg_name'...";
    if ! _deactivate_package "$pkg_name"; then
        stderr "Deactivation failed."; return 1;
    fi;

    if ! _update_manifest_status "$pkg_name" "REMOVED"; then
        stderr "Warning: Failed to update manifest status to REMOVED.";
    fi;
    
    stderr "Package '$pkg_name' uninstalled.";
    return 0;
}
function do_disable() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    local status;
    status=$(_get_manifest_row "$pkg_name" | awk -F'\t' '{print $2}');
    if [[ "$status" != "INSTALLED" ]]; then
        stderr "Error: Package is not installed."; return 1;
    fi;

    if ! __remove_bin_symlink "$pkg_name"; then
        stderr "Error: Failed to remove symlink."; return 1;
    fi;

    if ! _update_manifest_status "$pkg_name" "DISABLED"; then
        stderr "Warning: Failed to update manifest status to DISABLED.";
    fi;
    
    stderr "Package '$pkg_name' disabled.";
    return 0;
}
function do_enable() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    local status;
    status=$(_get_manifest_row "$pkg_name" | awk -F'\t' '{print $2}');
    if [[ "$status" != "DISABLED" ]]; then
        stderr "Error: Package is not disabled."; return 1;
    fi;
    
    if ! __create_bin_symlink "$pkg_name"; then
        stderr "Error: Failed to create symlink."; return 1;
    fi;
    
    if ! _update_manifest_status "$pkg_name" "INSTALLED"; then
        stderr "Warning: Failed to update manifest status to INSTALLED.";
    fi;
    
    stderr "Package '$pkg_name' enabled.";
    return 0;
}
function do_clean() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    local status;
    status=$(_get_manifest_row "$pkg_name" | awk -F'\t' '{print $2}');
    if [[ "$status" != "REMOVED" ]]; then
        stderr "Error: Package is not in REMOVED state.";
        return 1;
    fi;

    if ! _confirm_action "This will permanently delete the manifest entry and workspace files for '$pkg_name'. Continue?"; then
        stderr "Clean operation aborted by user.";
        return 1;
    fi;
    
    if ! _purge_package "$pkg_name"; then
        stderr "Error: Failed to purge package.";
        return 1;
    fi;

    stderr "Package '$pkg_name' has been cleaned from the system.";
    return 0;
}
function do_update() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then usage; return 1; fi;

    stderr "Checking for updates for '$pkg_name'...";
    if ! _is_update_required "$pkg_name"; then
        stderr "No changes detected in pristine source. Workspace is up-to-date.";
        return 0;
    fi;

    stderr "Update detected in pristine source. Re-registering...";
    if ! _re_register_package "$pkg_name"; then
        stderr "Update failed during re-registration.";
        return 1;
    fi;
    
    stderr "Update complete. Run 'install -f' to deploy the new version.";
    return 0;
}
function do_restore() {
    local pkg_name="$1";
    if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    local status;
    status=$(_get_manifest_row "$pkg_name" | awk -F'\t' '{print $2}');
    if [[ "$status" != "REMOVED" ]]; then
        stderr "Error: Package is not in REMOVED state.";
        return 1;
    fi;

    stderr "Restoring '$pkg_name' from workspace cache...";
    # Re-use the deploy logic, as it's the same operation.
    if ! _deploy_package "$pkg_name"; then
        stderr "Restore failed during deployment.";
        return 1;
    fi;

    if ! _update_manifest_status "$pkg_name" "INSTALLED"; then
        stderr "Warning: Restore successful, but failed to update manifest status.";
    fi;
    
    stderr "Package '$pkg_name' restored.";
    return 0;
}


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
