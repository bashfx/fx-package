#!/usr/bin/env bash
#
# ----- packagex-v2.0.0-final | lines: 1387 | functions: 56 | readonly_vars: 11 | option_vars: 8 ----- #
#
# packagex: A utility to manage a workspace of local bash scripts.
#

# --- META & PORTABLE ---
#
# meta:
#   version: v2.0.0
#   author: BashFX
#
# portable:
#   sha256sum, git, cp, mkdir, ln, rm
# builtins:
#   printf, echo, readonly, local, case, while, shift, declare, awk, grep, sed, sort, mapfile, read

# --- CONFIGURATION ---

readonly APP_NAME="packagex";
readonly ALIAS_NAME="pkgx";
readonly SRC_TREE="/home/nulltron/.repos/bashfx/fx-catalog";
readonly WORK_DIR="${SRC_TREE}/.work"; # The managed workspace for packagex.
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
opt_dev=0;
QUIET_MODE=0;
DEV_MODE=0;


# --- SIMPLE HELPERS ---

stderr() { if [[ "$QUIET_MODE" -eq 1 ]]; then return 0; fi; printf "%s\n" "$*" >&2; }
noop() { :; }


# --- DEV HELPERS ---

__low_inspect(){
	local pattern="^(${1:-do_})";
	if [[ $# -gt 1 ]]; then pattern="^($1"; shift; for p in "$@"; do pattern+="|$p"; done; pattern+=")"; fi
	declare -F | awk '{print $3}' | grep -E "$pattern" | sed 's/^/ /' | sort;
}

dev_dispatch() {
    local func_to_call="$1";
    if [[ -z "$func_to_call" ]]; then stderr "Dev Dispatcher: No function specified."; exit 1; fi;
    shift;
    if [[ "$func_to_call" == "func" ]]; then stderr "Available functions:"; __low_inspect _ __ do_; exit 0; fi;
    if [[ $(type -t "$func_to_call") == "function" ]]; then
        stderr "--- DEV CALL: $func_to_call $* ---"; "$func_to_call" "$@"; local ret=$?;
        stderr "--- END DEV CALL (Exit: $ret) ---"; exit "$ret";
    else
        stderr "Error: Function '$func_to_call' not found."; exit 1;
    fi;
}


# --- MID-LEVEL HELPERS ---

_build_manifest_row() { local fields=("$@"); local row=""; printf -v row '%s\t' "${fields[@]}"; printf "%s" "${row%?}\t::"; return 0; }

_check_git_status() {
    local path="$1";
    if ! command -v git &> /dev/null; then stderr "Warning: 'git' command not found."; return 0; fi;
    if ! git -C "$(dirname "$path")" rev-parse --is-inside-work-tree &> /dev/null; then return 0; fi;
    local status; status=$(git -C "$(dirname "$path")" status --porcelain -- "$path");
    if [[ -n "$status" ]]; then
        stderr "Error: Git status for '$path' is not clean. Please commit changes.";
        return 1;
    fi;
    return 0;
}

_confirm_action() {
    if [[ "$opt_yes" -eq 1 ]]; then return 0; fi;
    local prompt_string="$1"; local answer; read -r -p "$prompt_string [y/N] " answer;
    case "$answer" in (y|Y) return 0;; (*) return 1;; esac;
}

_gather_package_meta() {
    local pkg_name="$1";
    # Gathers data from the WORKING copy, not the true source.
    local working_path; working_path=$(_get_working_path "$pkg_name");
    local true_path; true_path=$(_get_true_source_path "$pkg_name");
    if [[ ! -r "$working_path" ]]; then stderr "Error: Working path for '$pkg_name' not found."; return 1; fi;
    local ver; ver=$(__get_header_meta "$working_path" "version"); [[ -z "$ver" ]] && ver="v0.1.0";
    local alias; alias=$(__get_header_meta "$working_path" "alias"); [[ -z "$alias" ]] && alias=${pkg_name#*.};
    local deps; deps=$(__get_header_meta "$working_path" "deps"); [[ -z "$deps" ]] && deps="none";
    local checksum; checksum=$(__get_file_checksum "$working_path");
    local status="KNOWN";
    if [[ "$ver" == "v0.1.0" || "$alias" == "${pkg_name#*.}" ]]; then status="INCOMPLETE"; fi;
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s" \
        "$pkg_name" "$status" "$ver" "$BUILD_START_NUMBER" "$alias" "$true_path" "$checksum" "$deps";
    return 0;
}

_get_all_header_meta() {
    local path="$1"; local -n map_ref="$2"; map_ref=();
    if [[ ! -r "$path" ]]; then return 1; fi;
    while read -r line; do
        if [[ "$line" =~ ^#\s*([a-zA-Z0-9_]+):[[:space:]]*(.*)$ ]]; then
            map_ref["${BASH_REMATCH[1]}"]="${BASH_REMATCH[2]}";
        fi;
    done < <(grep -E "^#\s*[a-zA-Z0-9_]+:" "$path");
    return 0;
}

_get_field_index() {
    local field_name="$1"; local header; header=$(__get_manifest_header);
    if [[ -z "$header" ]]; then stderr "Error: Could not read manifest header."; return 1; fi;
    local res; res=$(printf "%s" "$header" | awk -v field="$field_name" 'BEGIN { RS="\t" } { if ($0 == field) { print NR; exit } }');
    if [[ -z "$res" ]]; then return 1; fi;
    printf "%s" "$res"; return 0;
}

_get_manifest_field() {
    local pkg_name="$1"; local field_name="$2"; local row; row=$(_get_manifest_row "$pkg_name");
    if [[ -z "$row" ]]; then return 1; fi;
    local index; index=$(_get_field_index "$field_name");
    if [[ -z "$index" ]]; then stderr "Error: Field '$field_name' not found in manifest header."; return 1; fi;
    local res; res=$(printf "%s" "$row" | awk -v idx="$index" -F'\t' '{print $idx}');
    printf "%s" "$res"; return 0;
}

_get_manifest_row() {
    local pkg_name="$1"; __read_manifest_file; local res;
    res=$(printf "%s\n" "${MANIFEST_DATA[@]}" | grep -E "^${pkg_name}\t");
    if [[ -z "$res" ]]; then return 1; fi;
    printf "%s" "$res"; return 0;
}

_get_true_source_path() {
    local pkg_name="$1"; local prefix=${pkg_name%%.*}; local script_name=${pkg_name#*.};
    if [[ "$pkg_name" == "$prefix" || -z "$script_name" ]]; then
        stderr "Error: Invalid package name format: '$pkg_name'."; return 1;
    fi;
    if [[ "$prefix" == "util" ]]; then prefix="utils"; fi;
    printf "%s" "${SRC_TREE}/pkgs/${prefix}/${script_name}/${script_name}.sh";
}

_get_working_path() {
    local pkg_name="$1";
    local working_path="${WORK_DIR}/${pkg_name}.pkg.sh";
    if [[ ! -f "$working_path" ]]; then
        stderr "Workspace for '$pkg_name' not found. Preparing...";
        if ! _prepare_workspace_for_pkg "$pkg_name"; then
            stderr "Error: Failed to prepare workspace for '$pkg_name'.";
            return 1;
        fi;
    fi;
    printf "%s" "$working_path";
    return 0;
}

_link_package() {
    local pkg_name="$1"; stderr "Linking package executable...";
    local working_path; working_path=$(_get_working_path "$pkg_name");
    local alias; alias=$(_get_manifest_field "$pkg_name" "alias");
    # The symlink source is now the ENRICHED working copy, not the true source.
    local lib_path="${TARGET_LIB_DIR}/${TARGET_NAMESPACE}/${pkg_name}.sh";
    local link_path="${TARGET_BIN_DIR}/${TARGET_NAMESPACE}/${alias}";
    if ! __create_symlink "$lib_path" "$link_path"; then return 1; fi;
    if ! _update_manifest_field "$pkg_name" "status" "INSTALLED"; then return 1; fi;
    stderr "Package linked to: $link_path"; return 0;
}

_load_package() {
    local pkg_name="$1"; stderr "Loading package artifacts...";
    local working_path; working_path=$(_get_working_path "$pkg_name");
    # The destination name in lib is now the canonical pkg_name, not the original filename.
    local dest_path="${TARGET_LIB_DIR}/${TARGET_NAMESPACE}/${pkg_name}.sh";
    if ! __copy_file "$working_path" "$dest_path"; then return 1; fi;
    if ! _update_manifest_field "$pkg_name" "status" "LOADED"; then return 1; fi;
    stderr "Package loaded to: $dest_path"; return 0;
}

_prepare_workspace_for_pkg() {
    local pkg_name="$1";
    if [[ ! -d "$WORK_DIR" ]]; then
        mkdir -p "$WORK_DIR" || { stderr "Error: Could not create WORK_DIR."; return 1; };
    fi;
    local true_source_path; true_source_path=$(_get_true_source_path "$pkg_name");
    if [[ ! -r "$true_source_path" ]]; then
        stderr "Error: True source file not found at '$true_source_path'."; return 1;
    fi;
    # Copy to both working and orig files
    __copy_file "$true_source_path" "${WORK_DIR}/${pkg_name}.pkg.sh";
    __copy_file "$true_source_path" "${WORK_DIR}/${pkg_name}.orig.sh";
    return $?;
}

_uninstall_package() {
    local pkg_name="$1";
    local alias; alias=$(_get_manifest_field "$pkg_name" "alias");
    local lib_path="${TARGET_LIB_DIR}/${TARGET_NAMESPACE}/${pkg_name}.sh";
    local link_path="${TARGET_BIN_DIR}/${TARGET_NAMESPACE}/${alias}";
    stderr "Removing symlink..."; if ! __remove_symlink "$link_path"; then return 1; fi;
    stderr "Removing library file..."; if ! __remove_file "$lib_path"; then return 1; fi;
    _update_manifest_field "$pkg_name" "status" "REMOVED"; return 0;
}

_update_manifest_field() {
    local pkg_name="$1"; local field_name="$2"; local new_value="$3";
    local field_index; field_index=$(_get_field_index "$field_name");
    if [[ -z "$field_index" ]]; then stderr "Error: Field '$field_name' not found."; return 1; fi;
    awk -i inplace -v pkg="$pkg_name" -v idx="$field_index" -v val="$new_value" \
        'BEGIN { FS=OFS="\t" } { if ($1 == pkg) $idx = val; print }' "$MANIFEST_PATH";
    return $?;
}


# --- LOW-LEVEL HELPERS ---

__add_row_to_manifest() {
    local row_string="$1";
    local header="pkg_name\tstatus\tversion\tbuild\talias\tpath\tchecksum\tdeps\t::";
    if [[ ! -f "$MANIFEST_PATH" ]]; then
        printf "%s\n" "$header" > "$MANIFEST_PATH" || { stderr "Error: Could not create manifest."; return 1; };
    fi;
    printf "%s\n" "$row_string" >> "$MANIFEST_PATH"; return $?;
}

__copy_file() {
    local src_path="$1"; local dest_path="$2"; local dest_dir;
    dest_dir=$(dirname "$dest_path");
    if [[ ! -d "$dest_dir" ]]; then
        mkdir -p "$dest_dir" || { stderr "Error: Could not create directory: $dest_dir"; return 1; };
    fi;
    cp -p "$src_path" "$dest_path"; return $?;
}

__create_symlink() {
    local src_path="$1"; local link_path="$2"; local link_dir;
    link_dir=$(dirname "$link_path");
     if [[ ! -d "$link_dir" ]]; then
        mkdir -p "$link_dir" || { stderr "Error: Could not create directory: $link_dir"; return 1; };
    fi;
    ln -sf "$src_path" "$link_path"; return $?;
}

__get_file_checksum() {
    local path="$1"; if [[ ! -r "$path" ]]; then return 1; fi;
    local res; res=$(sha256sum "$path" 2>/dev/null | awk '{print $1}');
    if [[ -z "$res" ]]; then return 1; fi;
    printf "%s" "$res"; return 0;
}

__get_header_meta() {
    local path="$1"; local key="$2"; if [[ ! -r "$path" ]]; then return 1; fi;
    local res; res=$(grep -E "^#\s*${key}:" "$path" | head -n 1 | awk -F': ' '{print $2}');
    if [[ -z "$res" ]]; then return 1; fi;
    printf "%s" "$res"; return 0;
}

__get_manifest_header() {
    if [[ -n "$MANIFEST_HEADER" ]]; then printf "%s" "$MANIFEST_HEADER"; return 0; fi;
    if [[ ! -r "$MANIFEST_PATH" ]]; then return 1; fi;
    read -r MANIFEST_HEADER < "$MANIFEST_PATH";
    printf "%s" "$MANIFEST_HEADER"; return 0;
}

__read_manifest_file() {
    if [[ ${#MANIFEST_DATA[@]} -gt 0 ]]; then return 0; fi;
    if [[ ! -r "$MANIFEST_PATH" ]]; then return 1; fi;
    mapfile -t MANIFEST_DATA < "$MANIFEST_PATH"; return 0;
}

__remove_file() {
    local path="$1"; if [[ -f "$path" ]]; then
        rm "$path" || { stderr "Error: Failed to remove file: $path"; return 1; };
    else stderr "Notice: File not found at $path."; fi; return 0;
}

__remove_row_from_manifest() { local pkg_name="$1"; sed -i "/^${pkg_name}\t/d" "$MANIFEST_PATH"; return $?; }

__remove_symlink() {
    local link_path="$1"; if [[ -L "$link_path" ]]; then
        rm "$link_path" || { stderr "Error: Failed to remove symlink: $link_path"; return 1; };
    else stderr "Notice: Symlink not found at $link_path."; fi; return 0;
}

__rewrite_header() {
    local path="$1"; local -n data_map_ref="$2"; local header_content;
    header_content+="\n#\n# --- META ---\n#\n# meta:\n";
    for key in $(printf "%s\n" "${!data_map_ref[@]}" | sort); do
        header_content+=$(printf "#   %s: %s\n" "$key" "${data_map_ref[$key]}");
    done
    header_content+="#\n";
    sed -i "/^# --- META ---$/,/^#\s*$/c\\${header_content}" "$path"; return $?;
}


# --- API FUNCTIONS ---

do_cache() {
    local pkg_name="$1"; if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    local working_path; working_path=$(_get_working_path "$pkg_name");
    stderr "Caching header metadata for '$pkg_name'...";
    declare -A header_map; _get_all_header_meta "$working_path" header_map;
    if [[ ${#header_map[@]} -eq 0 ]]; then
        stderr "Warning: No metadata found in header. Caching empty record.";
    fi;
    local partial_data=("${pkg_name}" "INCOMPLETE" "${header_map[version]:-n/a}" "n/a" "${header_map[alias]:-n/a}" "n/a" "n/a" "${header_map[deps]:-n/a}");
    local new_row; new_row=$(_build_manifest_row "${partial_data[@]}");
    local existing_row; existing_row=$(_get_manifest_row "$pkg_name");
    if [[ -n "$existing_row" ]]; then sed -i "s|^${pkg_name}\t.*|${new_row//&/\\&}|" "$MANIFEST_PATH";
    else __add_row_to_manifest "$new_row"; fi;
    stderr "Caching complete."; do_status "$pkg_name"; return 0;
}

do_checksum() { noop; }

do_clean() {
    local pkg_name="$1"; if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    local status; status=$(_get_manifest_field "$pkg_name" "status");
    if [[ "$status" != "REMOVED" ]]; then
        stderr "Error: Package '$pkg_name' is not in REMOVED state."; return 1;
    fi;
    local prompt="Permanently remove '$pkg_name}' from the manifest?";
    if ! _confirm_action "$prompt"; then stderr "Clean aborted."; return 1; fi;
    if ! __remove_row_from_manifest "$pkg_name"; then
        stderr "Error: Failed to remove row from manifest."; return 1;
    fi;
    stderr "Package '$pkg_name' cleaned from manifest."; return 0;
}

do_disable() {
    local pkg_name="$1"; if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    local status; status=$(_get_manifest_field "$pkg_name" "status");
    if [[ "$status" != "INSTALLED" ]]; then
        stderr "Error: Package '$pkg_name' is not INSTALLED."; return 1;
    fi;
    local alias; alias=$(_get_manifest_field "$pkg_name" "alias");
    local link_path="${TARGET_BIN_DIR}/${TARGET_NAMESPACE}/${alias}";
    if ! __remove_symlink "$link_path"; then return 1; fi;
    _update_manifest_field "$pkg_name" "status" "DISABLED";
    stderr "Package '$pkg_name' disabled."; do_status "$pkg_name"; return 0;
}

do_enable() {
    local pkg_name="$1"; if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    local status; status=$(_get_manifest_field "$pkg_name" "status");
    if [[ "$status" != "DISABLED" ]]; then
        stderr "Error: Package '$pkg_name' is not DISABLED."; return 1;
    fi;
    if ! _link_package "$pkg_name"; then stderr "Error: Failed to re-link."; return 1; fi;
    stderr "Package '$pkg_name' enabled."; do_status "$pkg_name"; return 0;
}

do_install() {
    local pkg_name="$1"; if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    local status; status=$(_get_manifest_field "$pkg_name" "status");
    if [[ -z "$status" ]]; then
        stderr "Package not in manifest. Registering first...";
        if ! do_register "$pkg_name"; then return 1; fi;
        status=$(_get_manifest_field "$pkg_name" "status");
    fi;
    case "$status" in
        (INSTALLED) if [[ "$opt_force" -eq 0 ]]; then
            stderr "Package '$pkg_name' is already installed. Use -f to force."; return 0;
            fi; ;&
        (KNOWN|INCOMPLETE|DISABLED|LOADED)
            if ! _load_package "$pkg_name"; then return 1; fi;
            if ! _link_package "$pkg_name"; then return 1; fi; ;;
        (REMOVED) stderr "Package previously uninstalled. Use 'restore'."; return 1; ;;
        (*) stderr "Error: Unhandled status '$status'."; return 1; ;;
    esac
    stderr "Installation of '$pkg_name' complete."; do_status "$pkg_name"; return 0;
}

do_meta() {
    local pkg_name="$1"; if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    local working_path; working_path=$(_get_working_path "$pkg_name");
    if [[ ! -r "$working_path" ]]; then
        stderr "Error: Working file for '$pkg_name' not found."; return 1;
    fi;
    grep -E "^#\s*[a-zA-Z0-9_]+:" "$working_path" | sed -e 's/^#\s*//' -e 's/:\s*/: /';
    return 0;
}

do_normalize() {
    local pkg_name="$1"; if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    local working_path; working_path=$(_get_working_path "$pkg_name");
    if [[ ! -w "$working_path" ]]; then stderr "Error: Working file not writable."; return 1; fi;
    stderr "Injecting standard metadata header...";
    local ver="v0.1.0"; local alias=${pkg_name#*.};
    if ! __rewrite_header "$working_path" "version:$ver" "alias:$alias"; then
        stderr "Error: Failed to inject header."; return 1;
    fi;
    stderr "Normalization complete for '$pkg_name'."; return 0;
}

do_register() {
    local pkg_name="$1"; if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    local working_path; working_path=$(_get_working_path "$pkg_name");
    declare -A meta_map; _get_all_header_meta "$working_path" meta_map;
    stderr "Gathering package data...";
    local PkgxDataStr; PkgxDataStr=$(_gather_package_meta "$pkg_name");
    if [[ -z "$PkgxDataStr" ]]; then return 1; fi;
    local PkgxFields=("pkg_name" "status" "version" "build" "alias" "path" "checksum" "deps");
    local PkgxDataArr=($PkgxDataStr);
    for i in "${!PkgxFields[@]}"; do
        meta_map[${PkgxFields[$i]}]="${PkgxDataArr[$i]}";
    done
    local new_row; new_row=$(_build_manifest_row "${PkgxDataArr[@]}");
    local existing_row; existing_row=$(_get_manifest_row "$pkg_name");
    if [[ -n "$existing_row" ]]; then sed -i "s|^${pkg_name}\t.*|${new_row//&/\\&}|" "$MANIFEST_PATH";
    else __add_row_to_manifest "$new_row"; fi;
    if [[ $? -ne 0 ]]; then stderr "Error: Failed to write to manifest."; return 1; fi;
    stderr "Enriching source file header...";
    if ! __rewrite_header "$working_path" meta_map; then
        stderr "Warning: Failed to enrich source file header.";
    fi;
    stderr "Registration complete."; do_status "$pkg_name"; return 0;
}

do_restore() {
    local pkg_name="$1"; if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    local status; status=$(_get_manifest_field "$pkg_name" "status");
    if [[ "$status" != "REMOVED" ]]; then
        stderr "Error: Package is not in REMOVED state."; return 1;
    fi;
    stderr "Restoring package...";
    if ! _load_package "$pkg_name"; then return 1; fi;
    if ! _link_package "$pkg_name"; then return 1; fi;
    stderr "Package '$pkg_name' restored."; do_status "$pkg_name"; return 0;
}

do_uninstall() {
    local pkg_name="$1"; if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    local status; status=$(_get_manifest_field "$pkg_name" "status");
    if [[ "$status" != "INSTALLED" && "$status" != "DISABLED" ]]; then
        stderr "Error: Package cannot be uninstalled. State: $status"; return 1;
    fi;
    if ! _uninstall_package "$pkg_name"; then stderr "Uninstall failed."; return 1; fi;
    stderr "Package '$pkg_name' uninstalled."; do_status "$pkg_name"; return 0;
}

do_update() {
    local pkg_name="$1"; if [[ -z "$pkg_name" ]]; then usage; return 1; fi;
    stderr "Checking for updates for '$pkg_name'...";
    local true_source_path; true_source_path=$(_get_true_source_path "$pkg_name");
    local orig_path="${WORK_DIR}/${pkg_name}.orig.sh";
    if [[ ! -f "$orig_path" ]]; then
        stderr "No baseline found for '$pkg_name'. Please register it first."; return 1;
    fi;
    local true_sum; true_sum=$(__get_file_checksum "$true_source_path");
    local orig_sum; orig_sum=$(__get_file_checksum "$orig_path");
    if [[ "$true_sum" == "$orig_sum" ]]; then
        stderr "No changes detected. Workspace is up-to-date."; return 0;
    fi;
    stderr "Update detected. Re-caching workspace files...";
    if ! _prepare_workspace_for_pkg "$pkg_name"; then return 1; fi;
    stderr "Re-registering to enrich new workspace file...";
    if ! do_register "$pkg_name"; then return 1; fi;
    stderr "Update complete. Re-run 'install' to deploy the new version."; return 0;
}


# --- CORE FUNCTIONS ---

dispatch() {
    local cmd="$1"; if [[ -z "$cmd" ]]; then usage; return 1; fi; shift;
    case "$cmd" in
        (\#) dev_dispatch "$@"; exit $?;;
        (install|uninstall|enable|disable|status|meta|normalize|register|restore|clean|update|checksum|cache)
            "do_${cmd}" "$@";;
        (driver) do_driver "$@";;
        (*) stderr "Error: Unknown command '$cmd'"; usage; return 1;;
    esac;
}

main() {
    options "$@"; local shifted_args=("${@:$OPTIND}");
    if [[ "${shifted_args[0]}" == '$' ]]; then
        dev_dispatch "${shifted_args[@]:1}"; exit $?;
    fi;
    dispatch "${shifted_args[@]}";
}

options() {
    while getopts ":dtqfyD" opt; do
        case $opt in
            (d) opt_debug=1;; (t) opt_trace=1; opt_debug=1;;
            (q) QUIET_MODE=1; opt_quiet=1;; (f) opt_force=1;;
            (y) opt_yes=1;; (D) DEV_MODE=1; opt_dev=1;;
            \?) stderr "Error: Invalid option: -$OPTARG" >&2; usage; return 1;;
        esac
    done;
    return 0;
}

usage() {
    printf "Usage: %s <command> [options] [arguments]\n" "$APP_NAME";
    printf "  A utility to manage a workspace of local bash scripts.\n\n";
    printf "Commands:\n";
    printf "  install <pkg>     Install a package from the workspace.\n";
    printf "  update <pkg>      Refresh workspace from the true source file.\n";
    printf "  register <pkg>    Prepare and enrich a package in the workspace.\n";
    printf "  normalize <pkg>   (DEPRECATED) Use 'register' instead.\n";
    printf "  cache <pkg>       Cache header metadata to the manifest.\n";
    printf "  meta <pkg>        Read a package's enriched header from workspace.\n";
    printf "  status <pkg|all>  Check the status of package(s) in the manifest.\n";
    printf "  ... and more lifecycle commands (uninstall, enable, etc.)\n";
}


# --- MAIN INVOCATION ---

main "$@";
