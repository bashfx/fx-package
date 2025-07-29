<--- START OF FILE PRD_PACKAGEX.md --->
> PRD: packagex, Version: 0.1, Status: DRAFT

# ----- PRD_PACKAGEX_MAIN_SENTINEL | lines: 271 | words: 1210 | sections: 6 | headers: 9 | tables: 7 ----- #

<br>
<br>

# 📦 PRD: packagex

<br>
<br>

# ----- OVERVIEW_AND_GOALS_SECTION_1 SENTINEL ----- #

<br>
<br>

## 1. Overview & Goals

`packagex` is a command-line utility for managing a personal library of Bash scripts, adhering to the BASHFX architecture. It automates the installation, state tracking, and lifecycle management of scripts from a development source tree into a dedicated, user-owned directory structure (`~/.my/`).

The primary goals of this project are:

| Goal                 | Description                                                                                                                                                    |
| :------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Stateful Management**  | Track the status of every script (`KNOWN`, `LOADED`, `INSTALLED`, `DISABLED`, etc.) in a persistent, machine-readable manifest file.                           |
| **Symmetrical Lifecycle** | Ensure every action has a corresponding, "rewindable" counter-action (`install`/`uninstall`, `enable`/`disable`).                                           |
| **Architectural Purity** | Strictly implement the principles of the `BASHFX Architecture.md`, especially Function Ordinality, XDG+ pathing, and standard interface conventions.          |
| **Developer Ergonomics** | Provide developers with tools to `normalize` script headers, inspect file `meta`data, and validate file integrity via `checksum`s.                           |
| **Self-Containment**     | Confine all installation artifacts (scripts, links, configuration) to a predictable, non-polluting root directory (`~/.my/`) as defined in the project brief. |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- CORE_CONCEPTS_SECTION_2 SENTINEL ----- #

<br>
<br>

## 2. Core Concepts & Definitions

The following concepts define the core functionality and assumptions of the `packagex` utility.

| Concept                 | Definition                                                                                                                                                                |
| :---------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Package**             | A source script file (e.g., `knife.sh`) located within a designated source directory (e.g., `$SRC_TREE/pkgs/fx/`). Its canonical name is prefixed (e.g., `fx.knife`).           |
| **Manifest**            | The single source of truth for package *state*. A tab-delimited file located at `$MANIFEST_PATH` (`~/.pkg_manifest`) that tracks all known packages and their metadata.           |
| **Package Lifecycle**   | The series of states a package can be in: `UNKNOWN` -> `INCOMPLETE` -> `KNOWN` -> `LOADED` -> `INSTALLED`. The "down" cycle includes `DISABLED` -> `REMOVED` -> `CLEANED`. |
| **Installation Pattern**  | A two-step process: (1) Copy the source file to `${TARGET_LIB_DIR}/<namespace>/`. (2) Create a symlink from the library file to `${TARGET_BIN_DIR}/<alias>`.                   |
| **Function Ordinality** | A strict hierarchy (`do_*` > `_*` > `__*`) that separates user-facing logic from "close-to-the-metal" system tasks, as defined in the architecture.                             |
| **Normalization**       | The process of injecting a standardized header block and `APP_*` variables into a source script file to ensure it is compliant and can be fully registered.                   |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- MILESTONE_1_SECTION_3 SENTINEL | lines: 27 | words: 183 | tasks: 4 | tables: 1 ----- #

<br>
<br>

## 3. Milestone 1: Foundation & Core Logic

The goal of this milestone is to establish the script skeleton, argument parsing, and core helper functions for reading state from files and the manifest.

| Task         | Description                                                                                                                                                   | Execution Hints                                                                    |
| :----------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------ | :--------------------------------------------------------------------------------- |
| **Task 1.1** | **Create Script Skeleton:** Generate the `packagex` file following the "Major Script" template, including stubs for `main`, `dispatch`, `options`, and `usage`.  | Use standard function comment bars (Sec 5.0.14).                                   |
| **Task 1.2** | **Implement `options()` Parser:** Implement the `options()` function to parse standard flags (`-d`, `-t`, `-q`, `-f`, `-y`, `-D`) and set `opt_*` variables.      | Use a `while/case` loop. Adhere to standard flag behavior (Sec 3.1).               |
| **Task 1.3** | **Implement Manifest Read Helpers:** Create mid (`_`) and low-level (`__`) functions to read and parse the manifest (`_get_manifest_row`, `_get_manifest_field`). | Handle the tab delimiter and `::` EOL marker. The header defines the column order. |
| **Task 1.4** | **Implement Package Read Helpers:** Create helpers to get info from source files (`_get_source_path`, `__get_file_checksum`, `__get_header_meta`).              | Implement the `utils` -> `util` prefix logic within `_get_source_path`.            |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- MILESTONE_2_SECTION_4 SENTINEL | lines: 30 | words: 191 | tasks: 4 | tables: 1 ----- #

<br>
<br>

## 4. Milestone 2: Primary Lifecycle (The "Up" Cycle)

The goal of this milestone is to implement the core commands that move a package from an `UNKNOWN` state to a fully `INSTALLED` state.

| Task         | Description                                                                                                                                                                                                                                                          | Execution Hints                                                                                                                            |
| :----------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------- |
| **Task 2.1** | **Implement `do_normalize`:** Inject the standard header and `APP_*` variables into a source script.                                                                                                                                                                   | This is a destructive operation. Must check git status and create a backup in `.orig/`.                                                    |
| **Task 2.2** | **Implement `do_register`:** Read metadata from a source script, create a manifest row, and set status to `INCOMPLETE` or `KNOWN` based on the completeness of the metadata.                                                                                              | Use low-level `__write_row_to_manifest` helper.                                                                                            |
| **Task 2.3** | **Implement `do_install`:** Orchestrate the full "up" lifecycle. It must call register/load logic if prerequisites are not met, copy the file to the library, and create the symlink in the bin directory.                                                              | This function exemplifies Function Ordinality, calling mid-level helpers which in turn call low-level `__copy_file`, `__create_symlink`, etc. |
| **Task 2.4** | **Implement `do_status` & `do_meta`:** Create the read-only commands to display the formatted manifest entry (`status`) and the parsed header metadata from a source file (`meta`).                                                                                     | These are ideal for testing the foundational helpers from Milestone 1.                                                                     |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- MILESTONE_3_SECTION_5 SENTINEL | lines: 31 | words: 189 | tasks: 4 | tables: 1 ----- #

<br>
<br>

## 5. Milestone 3: Symmetrical Lifecycle & Maintenance

The goal of this milestone is to implement the "down" lifecycle and maintenance utilities, ensuring the system is fully rewindable and adheres to the architectural principle of a Symmetrical Lifecycle.

| Task         | Description                                                                                                                                 | Execution Hints                                                                      |
| :----------- | :------------------------------------------------------------------------------------------------------------------------------------------ | :----------------------------------------------------------------------------------- |
| **Task 3.1** | **Implement `do_disable` & `do_enable`:** Remove or recreate the symlink in the bin directory and toggle the manifest status accordingly.       | These commands only manipulate the symlink and the manifest status field.            |
| **Task 3.2** | **Implement `do_uninstall`:** Remove the symlink and the library file, then update the manifest status to `REMOVED`.                            | Actions must be performed in the reverse order of `install`.                         |
| **Task 3.3** | **Implement `do_restore`:** For a package marked as `REMOVED`, use existing manifest data to re-run the `install` logic.                        | This command trusts the manifest data and avoids re-scanning the source file.        |
| **Task 3.4** | **Implement `do_clean`:** Find all packages with the status `REMOVED` and permanently delete their corresponding rows from the manifest file. | This is a destructive data operation and must prompt the user unless `-y` is passed. |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- CONFIG_AND_SCOPE_SECTION_6 SENTINEL | lines: 44 | words: 229 | headers: 2 | tables: 2 ----- #

<br>
<br>

## 6. Configuration & Scope

### 6.1 Configuration Variables

These variables define the core paths and settings for the `packagex` script. They should be defined as `readonly` globals near the top of the script.

| Variable              | Default / Example Value       | Description                                                |
| :-------------------- | :---------------------------- | :--------------------------------------------------------- |
| `APP_NAME`            | `packagex`                    | The primary name of the script.                            |
| `ALIAS_NAME`          | `pkgx`                        | The short alias for the script.                            |
| `SRC_TREE`            | *User Defined*                | Path to the source project root.                           |
| `TARGET_BASE_DIR`     | `$HOME/.my`                   | The root directory for all installed artifacts.            |
| `TARGET_NAMESPACE`    | `tmp`                         | The installation subdirectory within lib and bin.          |
| `TARGET_LIB_DIR`      | `$TARGET_BASE_DIR/lib`        | Base directory for where library scripts are copied.       |
| `TARGET_BIN_DIR`      | `$TARGET_BASE_DIR/bin`        | Base directory for where executables are linked.           |
| `MANIFEST_PATH`       | `$HOME/.pkg_manifest`         | Full path to the package state manifest file.              |
| `BACKUP_DIR`          | `$SRC_TREE/.orig`             | Directory for storing backups before `normalize` operations. |
| `BUILD_START_NUMBER`  | `1000`                        | The initial build number for new packages.                 |

### 6.2 Out of Scope (MVP)

The following features are explicitly not part of the Minimum Viable Product.

| Feature                       | Reason / Notes                                                                   |
| :---------------------------- | :------------------------------------------------------------------------------- |
| **Bulk Operations**           | Commands will operate on one package at a time (e.g., `pkgx install fx.knife`).    |
| **Library Installation**      | The scope is limited to installing executable scripts from `pkgs/fx` and `pkgs/utils`. |
| **Full Version Management**   | The script will only manage build numbers. Semantic versioning is a manual process. |
| **Complex Dependency Mgmt.** | The `deps` field is informational; the script will not install external dependencies. |

<br>
<br>

<--- END OF FILE PRD_PACKAGEX.md --->




<--- START OF FILE PRD_PACKAGEX.md --->
> PRD: packagex, Version: 0.1, Status: DRAFT

# ----- PRD_PACKAGEX_MAIN_SENTINEL | lines: 406 | words: 1916 | sections: 7 | headers: 10 | tables: 8 ----- #

<br>
<br>

# 📦 PRD: packagex

<br>
<br>

# ----- OVERVIEW_AND_GOALS_SECTION_1 SENTINEL ----- #

<br>
<br>

## 1. Overview & Goals

`packagex` is a command-line utility for managing a personal library of Bash scripts, adhering to the BASHFX architecture. It automates the installation, state tracking, and lifecycle management of scripts from a development source tree into a dedicated, user-owned directory structure (`~/.my/`).

The primary goals of this project are:

| Goal                 | Description                                                                                                                                                    |
| :------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Stateful Management**  | Track the status of every script (`KNOWN`, `LOADED`, `INSTALLED`, `DISABLED`, etc.) in a persistent, machine-readable manifest file.                           |
| **Symmetrical Lifecycle** | Ensure every action has a corresponding, "rewindable" counter-action (`install`/`uninstall`, `enable`/`disable`).                                           |
| **Architectural Purity** | Strictly implement the principles of the `BASHFX Architecture.md`, especially Function Ordinality, XDG+ pathing, and standard interface conventions.          |
| **Developer Ergonomics** | Provide developers with tools to `normalize` script headers, inspect file `meta`data, and validate file integrity via `checksum`s.                           |
| **Self-Containment**     | Confine all installation artifacts (scripts, links, configuration) to a predictable, non-polluting root directory (`~/.my/`) as defined in the project brief. |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- CORE_CONCEPTS_SECTION_2 SENTINEL ----- #

<br>
<br>

## 2. Core Concepts & Definitions

The following concepts define the core functionality and assumptions of the `packagex` utility.

| Concept                 | Definition                                                                                                                                                                |
| :---------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Package**             | A source script file (e.g., `knife.sh`) located within a designated source directory (e.g., `$SRC_TREE/pkgs/fx/`). Its canonical name is prefixed (e.g., `fx.knife`).           |
| **Manifest**            | The single source of truth for package *state*. A tab-delimited file located at `$MANIFEST_PATH` (`~/.pkg_manifest`) that tracks all known packages and their metadata.           |
| **Package Lifecycle**   | The series of states a package can be in: `UNKNOWN` -> `INCOMPLETE` -> `KNOWN` -> `LOADED` -> `INSTALLED`. The "down" cycle includes `DISABLED` -> `REMOVED` -> `CLEANED`. |
| **Installation Pattern**  | A two-step process: (1) Copy the source file to `${TARGET_LIB_DIR}/<namespace>/`. (2) Create a symlink from the library file to `${TARGET_BIN_DIR}/<alias>`.                   |
| **Function Ordinality** | A strict hierarchy (`do_*` > `_*` > `__*`) that separates user-facing logic from "close-to-the-metal" system tasks, as defined in the architecture.                             |
| **Normalization**       | The process of injecting a standardized header block and `APP_*` variables into a source script file to ensure it is compliant and can be fully registered.                   |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- MILESTONE_1_SECTION_3 SENTINEL | lines: 27 | words: 183 | tasks: 4 | tables: 1 ----- #

<br>
<br>

## 3. Milestone 1: Foundation & Core Logic

The goal of this milestone is to establish the script skeleton, argument parsing, and core helper functions for reading state from files and the manifest.

| Task         | Description                                                                                                                                                   | Execution Hints                                                                    |
| :----------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------ | :--------------------------------------------------------------------------------- |
| **Task 1.1** | **Create Script Skeleton:** Generate the `packagex` file following the "Major Script" template, including stubs for `main`, `dispatch`, `options`, and `usage`.  | Use standard function comment bars (Sec 5.0.14).                                   |
| **Task 1.2** | **Implement `options()` Parser:** Implement the `options()` function to parse standard flags (`-d`, `-t`, `-q`, `-f`, `-y`, `-D`) and set `opt_*` variables.      | Use a `while/case` loop. Adhere to standard flag behavior (Sec 3.1).               |
| **Task 1.3** | **Implement Manifest Read Helpers:** Create mid (`_`) and low-level (`__`) functions to read and parse the manifest (`_get_manifest_row`, `_get_manifest_field`). | Handle the tab delimiter and `::` EOL marker. The header defines the column order. |
| **Task 1.4** | **Implement Package Read Helpers:** Create helpers to get info from source files (`_get_source_path`, `__get_file_checksum`, `__get_header_meta`).              | Implement the `utils` -> `util` prefix logic within `_get_source_path`.            |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- MILESTONE_2_SECTION_4 SENTINEL | lines: 30 | words: 191 | tasks: 4 | tables: 1 ----- #

<br>
<br>

## 4. Milestone 2: Primary Lifecycle (The "Up" Cycle)

The goal of this milestone is to implement the core commands that move a package from an `UNKNOWN` state to a fully `INSTALLED` state.

| Task         | Description                                                                                                                                                                                                                                                          | Execution Hints                                                                                                                            |
| :----------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------- |
| **Task 2.1** | **Implement `do_normalize`:** Inject the standard header and `APP_*` variables into a source script.                                                                                                                                                                   | This is a destructive operation. Must check git status and create a backup in `.orig/`.                                                    |
| **Task 2.2** | **Implement `do_register`:** Read metadata from a source script, create a manifest row, and set status to `INCOMPLETE` or `KNOWN` based on the completeness of the metadata.                                                                                              | Use low-level `__write_row_to_manifest` helper.                                                                                            |
| **Task 2.3** | **Implement `do_install`:** Orchestrate the full "up" lifecycle. It must call register/load logic if prerequisites are not met, copy the file to the library, and create the symlink in the bin directory.                                                              | This function exemplifies Function Ordinality, calling mid-level helpers which in turn call low-level `__copy_file`, `__create_symlink`, etc. |
| **Task 2.4** | **Implement `do_status` & `do_meta`:** Create the read-only commands to display the formatted manifest entry (`status`) and the parsed header metadata from a source file (`meta`).                                                                                     | These are ideal for testing the foundational helpers from Milestone 1.                                                                     |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- MILESTONE_3_SECTION_5 SENTINEL | lines: 31 | words: 189 | tasks: 4 | tables: 1 ----- #

<br>
<br>

## 5. Milestone 3: Symmetrical Lifecycle & Maintenance

The goal of this milestone is to implement the "down" lifecycle and maintenance utilities, ensuring the system is fully rewindable and adheres to the architectural principle of a Symmetrical Lifecycle.

| Task         | Description                                                                                                                                 | Execution Hints                                                                      |
| :----------- | :------------------------------------------------------------------------------------------------------------------------------------------ | :----------------------------------------------------------------------------------- |
| **Task 3.1** | **Implement `do_disable` & `do_enable`:** Remove or recreate the symlink in the bin directory and toggle the manifest status accordingly.       | These commands only manipulate the symlink and the manifest status field.            |
| **Task 3.2** | **Implement `do_uninstall`:** Remove the symlink and the library file, then update the manifest status to `REMOVED`.                            | Actions must be performed in the reverse order of `install`.                         |
| **Task 3.3** | **Implement `do_restore`:** For a package marked as `REMOVED`, use existing manifest data to re-run the `install` logic.                        | This command trusts the manifest data and avoids re-scanning the source file.        |
| **Task 3.4** | **Implement `do_clean`:** Find all packages with the status `REMOVED` and permanently delete their corresponding rows from the manifest file. | This is a destructive data operation and must prompt the user unless `-y` is passed. |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- CONFIG_AND_SCOPE_SECTION_6 SENTINEL | lines: 44 | words: 229 | headers: 2 | tables: 2 ----- #

<br>
<br>

## 6. Configuration & Scope

### 6.1 Configuration Variables

These variables define the core paths and settings for the `packagex` script. They should be defined as `readonly` globals near the top of the script.

| Variable              | Default / Example Value       | Description                                                |
| :-------------------- | :---------------------------- | :--------------------------------------------------------- |
| `APP_NAME`            | `packagex`                    | The primary name of the script.                            |
| `ALIAS_NAME`          | `pkgx`                        | The short alias for the script.                            |
| `SRC_TREE`            | *User Defined*                | Path to the source project root.                           |
| `TARGET_BASE_DIR`     | `$HOME/.my`                   | The root directory for all installed artifacts.            |
| `TARGET_NAMESPACE`    | `tmp`                         | The installation subdirectory within lib and bin.          |
| `TARGET_LIB_DIR`      | `$TARGET_BASE_DIR/lib`        | Base directory for where library scripts are copied.       |
| `TARGET_BIN_DIR`      | `$TARGET_BASE_DIR/bin`        | Base directory for where executables are linked.           |
| `MANIFEST_PATH`       | `$HOME/.pkg_manifest`         | Full path to the package state manifest file.              |
| `BACKUP_DIR`          | `$SRC_TREE/.orig`             | Directory for storing backups before `normalize` operations. |
| `BUILD_START_NUMBER`  | `1000`                        | The initial build number for new packages.                 |

### 6.2 Out of Scope (MVP)

The following features are explicitly not part of the Minimum Viable Product.

| Feature                       | Reason / Notes                                                                   |
| :---------------------------- | :------------------------------------------------------------------------------- |
| **Bulk Operations**           | Commands will operate on one package at a time (e.g., `pkgx install fx.knife`).    |
| **Library Installation**      | The scope is limited to installing executable scripts from `pkgs/fx` and `pkgs/utils`. |
| **Full Version Management**   | The script will only manage build numbers. Semantic versioning is a manual process. |
| **Complex Dependency Mgmt.** | The `deps` field is informational; the script will not install external dependencies. |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- TECHNICAL_BREAKDOWN_M1_SECTION_7 SENTINEL | lines: 123 | words: 706 | headers: 1 | tables: 1 ----- #

<br>
<br>

## 7. Technical Breakdown: Milestone 1

This section provides the specific, function-level implementation plan for the tasks defined in Milestone 1.

| PRD Task     | Component / Function              | Ordinality | Description                                                                                                                                       |
| :----------- | :-------------------------------- | :--------- | :------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Task 1.1** | *Script Structure*                | -          | Create the `packagex` file with sections as comments per Arch. Sec 5.2.1: shebang, meta, portable, readonly, config, helpers, dispatch, main, etc.   |
| "           | `readonly` variables            | Global     | Define all configuration variables from Sec 6.1 as `readonly` globals.                                                                            |
| "           | `main()`                          | Super      | Create stub. Will orchestrate `options` and `dispatch` calls.                                                                                     |
| "           | `dispatch()`                      | Super      | Create stub. Will contain the main `case` statement for routing commands to `do_*` functions.                                                       |
| "           | `usage()`                         | High-Order | Create stub. Will contain the help text for the script.                                                                                           |
| **Task 1.2** | `options()`                       | High-Order | Create function body with `while getopts` loop to parse flags: `-d, -t, -q, -f, -y, -D`.                                                           |
| "           | `opt_*` variables                 | Global     | Declare all `opt_*` variables (e.g., `opt_debug=0`, `opt_force=0`) before the `options()` function.                                                   |
| **Task 1.3** | `__read_manifest_file()`          | Low        | **Input:** (none). **Output:** Writes manifest content to a global array (e.g., `MANIFEST_DATA`). Handles file-not-found error.                      |
| "           | `__get_manifest_header()`         | Low        | **Input:** (none). **Output:** The first line of the manifest. Caches result.                                                                      |
| "           | `_resolve_pkg_prefix()`           | Mid        | **Input:** `pkg_dir_name`. **Output:** The correct prefix (`fx`, `util`). Contains the `utils` -> `util` logic.                                      |
| "           | `_get_manifest_row()`             | Mid        | **Input:** `pkg_name`. **Output:** The full manifest line for the package. Uses `__read_manifest_file`.                                              |
| "           | `_get_field_index()`              | Mid        | **Input:** `field_name`. **Output:** The numerical index (column number) of a field. Uses `__get_manifest_header`.                                  |
| "           | `_get_manifest_field()`           | Mid        | **Input:** `pkg_name`, `field_name`. **Output:** The value of a specific field for a package. Orchestrates `_get_manifest_row` and `_get_field_index`. |
| **Task 1.4** | `__get_file_checksum()`           | Low        | **Input:** `file_path`. **Output:** The SHA256 checksum of the file.                                                                               |
| "           | `__get_header_meta()`             | Low        | **Input:** `file_path`, `meta_key`. **Output:** The value of a `# key: value` pair from the file's comment header. Uses `grep` and `sed`/`awk`.       |
| "           | `_get_source_path()`              | Mid        | **Input:** `pkg_name` (e.g., `fx.knife`). **Output:** The absolute path to the source script. Uses `_resolve_pkg_prefix` to find the correct subdir. |

<br>
<br>

<--- START OF FILE PRD_PACKAGEX.md --->
> PRD: packagex, Version: 0.1, Status: DRAFT

# ----- PRD_PACKAGEX_MAIN_SENTINEL | lines: 554 | words: 2715 | sections: 8 | headers: 11 | tables: 9 ----- #

<br>
<br>

# 📦 PRD: packagex

<br>
<br>

# ----- OVERVIEW_AND_GOALS_SECTION_1 SENTINEL ----- #

<br>
<br>

## 1. Overview & Goals

`packagex` is a command-line utility for managing a personal library of Bash scripts, adhering to the BASHFX architecture. It automates the installation, state tracking, and lifecycle management of scripts from a development source tree into a dedicated, user-owned directory structure (`~/.my/`).

The primary goals of this project are:

| Goal                 | Description                                                                                                                                                    |
| :------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Stateful Management**  | Track the status of every script (`KNOWN`, `LOADED`, `INSTALLED`, `DISABLED`, etc.) in a persistent, machine-readable manifest file.                           |
| **Symmetrical Lifecycle** | Ensure every action has a corresponding, "rewindable" counter-action (`install`/`uninstall`, `enable`/`disable`).                                           |
| **Architectural Purity** | Strictly implement the principles of the `BASHFX Architecture.md`, especially Function Ordinality, XDG+ pathing, and standard interface conventions.          |
| **Developer Ergonomics** | Provide developers with tools to `normalize` script headers, inspect file `meta`data, and validate file integrity via `checksum`s.                           |
| **Self-Containment**     | Confine all installation artifacts (scripts, links, configuration) to a predictable, non-polluting root directory (`~/.my/`) as defined in the project brief. |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- CORE_CONCEPTS_SECTION_2 SENTINEL ----- #

<br>
<br>

## 2. Core Concepts & Definitions

The following concepts define the core functionality and assumptions of the `packagex` utility.

| Concept                 | Definition                                                                                                                                                                |
| :---------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Package**             | A source script file (e.g., `knife.sh`) located within a designated source directory (e.g., `$SRC_TREE/pkgs/fx/`). Its canonical name is prefixed (e.g., `fx.knife`).           |
| **Manifest**            | The single source of truth for package *state*. A tab-delimited file located at `$MANIFEST_PATH` (`~/.pkg_manifest`) that tracks all known packages and their metadata.           |
| **Package Lifecycle**   | The series of states a package can be in: `UNKNOWN` -> `INCOMPLETE` -> `KNOWN` -> `LOADED` -> `INSTALLED`. The "down" cycle includes `DISABLED` -> `REMOVED` -> `CLEANED`. |
| **Installation Pattern**  | A two-step process: (1) Copy the source file to `${TARGET_LIB_DIR}/<namespace>/`. (2) Create a symlink from the library file to `${TARGET_BIN_DIR}/<alias>`.                   |
| **Function Ordinality** | A strict hierarchy (`do_*` > `_*` > `__*`) that separates user-facing logic from "close-to-the-metal" system tasks, as defined in the architecture.                             |
| **Normalization**       | The process of injecting a standardized header block and `APP_*` variables into a source script file to ensure it is compliant and can be fully registered.                   |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- MILESTONE_1_SECTION_3 SENTINEL | lines: 27 | words: 183 | tasks: 4 | tables: 1 ----- #

<br>
<br>

## 3. Milestone 1: Foundation & Core Logic

The goal of this milestone is to establish the script skeleton, argument parsing, and core helper functions for reading state from files and the manifest.

| Task         | Description                                                                                                                                                   | Execution Hints                                                                    |
| :----------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------ | :--------------------------------------------------------------------------------- |
| **Task 1.1** | **Create Script Skeleton:** Generate the `packagex` file following the "Major Script" template, including stubs for `main`, `dispatch`, `options`, and `usage`.  | Use standard function comment bars (Sec 5.0.14).                                   |
| **Task 1.2** | **Implement `options()` Parser:** Implement the `options()` function to parse standard flags (`-d`, `-t`, `-q`, `-f`, `-y`, `-D`) and set `opt_*` variables.      | Use a `while/case` loop. Adhere to standard flag behavior (Sec 3.1).               |
| **Task 1.3** | **Implement Manifest Read Helpers:** Create mid (`_`) and low-level (`__`) functions to read and parse the manifest (`_get_manifest_row`, `_get_manifest_field`). | Handle the tab delimiter and `::` EOL marker. The header defines the column order. |
| **Task 1.4** | **Implement Package Read Helpers:** Create helpers to get info from source files (`_get_source_path`, `__get_file_checksum`, `__get_header_meta`).              | Implement the `utils` -> `util` prefix logic within `_get_source_path`.            |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- MILESTONE_2_SECTION_4 SENTINEL | lines: 30 | words: 191 | tasks: 4 | tables: 1 ----- #

<br>
<br>

## 4. Milestone 2: Primary Lifecycle (The "Up" Cycle)

The goal of this milestone is to implement the core commands that move a package from an `UNKNOWN` state to a fully `INSTALLED` state.

| Task         | Description                                                                                                                                                                                                                                                          | Execution Hints                                                                                                                            |
| :----------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------- |
| **Task 2.1** | **Implement `do_normalize`:** Inject the standard header and `APP_*` variables into a source script.                                                                                                                                                                   | This is a destructive operation. Must check git status and create a backup in `.orig/`.                                                    |
| **Task 2.2** | **Implement `do_register`:** Read metadata from a source script, create a manifest row, and set status to `INCOMPLETE` or `KNOWN` based on the completeness of the metadata.                                                                                              | Use low-level `__write_row_to_manifest` helper.                                                                                            |
| **Task 2.3** | **Implement `do_install`:** Orchestrate the full "up" lifecycle. It must call register/load logic if prerequisites are not met, copy the file to the library, and create the symlink in the bin directory.                                                              | This function exemplifies Function Ordinality, calling mid-level helpers which in turn call low-level `__copy_file`, `__create_symlink`, etc. |
| **Task 2.4** | **Implement `do_status` & `do_meta`:** Create the read-only commands to display the formatted manifest entry (`status`) and the parsed header metadata from a source file (`meta`).                                                                                     | These are ideal for testing the foundational helpers from Milestone 1.                                                                     |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- MILESTONE_3_SECTION_5 SENTINEL | lines: 31 | words: 189 | tasks: 4 | tables: 1 ----- #

<br>
<br>

## 5. Milestone 3: Symmetrical Lifecycle & Maintenance

The goal of this milestone is to implement the "down" lifecycle and maintenance utilities, ensuring the system is fully rewindable and adheres to the architectural principle of a Symmetrical Lifecycle.

| Task         | Description                                                                                                                                 | Execution Hints                                                                      |
| :----------- | :------------------------------------------------------------------------------------------------------------------------------------------ | :----------------------------------------------------------------------------------- |
| **Task 3.1** | **Implement `do_disable` & `do_enable`:** Remove or recreate the symlink in the bin directory and toggle the manifest status accordingly.       | These commands only manipulate the symlink and the manifest status field.            |
| **Task 3.2** | **Implement `do_uninstall`:** Remove the symlink and the library file, then update the manifest status to `REMOVED`.                            | Actions must be performed in the reverse order of `install`.                         |
| **Task 3.3** | **Implement `do_restore`:** For a package marked as `REMOVED`, use existing manifest data to re-run the `install` logic.                        | This command trusts the manifest data and avoids re-scanning the source file.        |
| **Task 3.4** | **Implement `do_clean`:** Find all packages with the status `REMOVED` and permanently delete their corresponding rows from the manifest file. | This is a destructive data operation and must prompt the user unless `-y` is passed. |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- CONFIG_AND_SCOPE_SECTION_6 SENTINEL | lines: 44 | words: 229 | headers: 2 | tables: 2 ----- #

<br>
<br>

## 6. Configuration & Scope

### 6.1 Configuration Variables

These variables define the core paths and settings for the `packagex` script. They should be defined as `readonly` globals near the top of the script.

| Variable              | Default / Example Value       | Description                                                |
| :-------------------- | :---------------------------- | :--------------------------------------------------------- |
| `APP_NAME`            | `packagex`                    | The primary name of the script.                            |
| `ALIAS_NAME`          | `pkgx`                        | The short alias for the script.                            |
| `SRC_TREE`            | *User Defined*                | Path to the source project root.                           |
| `TARGET_BASE_DIR`     | `$HOME/.my`                   | The root directory for all installed artifacts.            |
| `TARGET_NAMESPACE`    | `tmp`                         | The installation subdirectory within lib and bin.          |
| `TARGET_LIB_DIR`      | `$TARGET_BASE_DIR/lib`        | Base directory for where library scripts are copied.       |
| `TARGET_BIN_DIR`      | `$TARGET_BASE_DIR/bin`        | Base directory for where executables are linked.           |
| `MANIFEST_PATH`       | `$HOME/.pkg_manifest`         | Full path to the package state manifest file.              |
| `BACKUP_DIR`          | `$SRC_TREE/.orig`             | Directory for storing backups before `normalize` operations. |
| `BUILD_START_NUMBER`  | `1000`                        | The initial build number for new packages.                 |

### 6.2 Out of Scope (MVP)

The following features are explicitly not part of the Minimum Viable Product.

| Feature                       | Reason / Notes                                                                   |
| :---------------------------- | :------------------------------------------------------------------------------- |
| **Bulk Operations**           | Commands will operate on one package at a time (e.g., `pkgx install fx.knife`).    |
| **Library Installation**      | The scope is limited to installing executable scripts from `pkgs/fx` and `pkgs/utils`. |
| **Full Version Management**   | The script will only manage build numbers. Semantic versioning is a manual process. |
| **Complex Dependency Mgmt.** | The `deps` field is informational; the script will not install external dependencies. |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- TECHNICAL_BREAKDOWN_M1_SECTION_7 SENTINEL | lines: 123 | words: 706 | headers: 1 | tables: 1 ----- #

<br>
<br>

## 7. Technical Breakdown: Milestone 1

This section provides the specific, function-level implementation plan for the tasks defined in Milestone 1.

| PRD Task     | Component / Function              | Ordinality | Description                                                                                                                                       |
| :----------- | :-------------------------------- | :--------- | :------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Task 1.1** | *Script Structure*                | -          | Create the `packagex` file with sections as comments per Arch. Sec 5.2.1: shebang, meta, portable, readonly, config, helpers, dispatch, main, etc.   |
| "           | `readonly` variables            | Global     | Define all configuration variables from Sec 6.1 as `readonly` globals.                                                                            |
| "           | `main()`                          | Super      | Create stub. Will orchestrate `options` and `dispatch` calls.                                                                                     |
| "           | `dispatch()`                      | Super      | Create stub. Will contain the main `case` statement for routing commands to `do_*` functions.                                                       |
| "           | `usage()`                         | High-Order | Create stub. Will contain the help text for the script.                                                                                           |
| **Task 1.2** | `options()`                       | High-Order | Create function body with `while getopts` loop to parse flags: `-d, -t, -q, -f, -y, -D`.                                                           |
| "           | `opt_*` variables                 | Global     | Declare all `opt_*` variables (e.g., `opt_debug=0`, `opt_force=0`) before the `options()` function.                                                   |
| **Task 1.3** | `__read_manifest_file()`          | Low        | **Input:** (none). **Output:** Writes manifest content to a global array (e.g., `MANIFEST_DATA`). Handles file-not-found error.                      |
| "           | `__get_manifest_header()`         | Low        | **Input:** (none). **Output:** The first line of the manifest. Caches result.                                                                      |
| "           | `_resolve_pkg_prefix()`           | Mid        | **Input:** `pkg_dir_name`. **Output:** The correct prefix (`fx`, `util`). Contains the `utils` -> `util` logic.                                      |
| "           | `_get_manifest_row()`             | Mid        | **Input:** `pkg_name`. **Output:** The full manifest line for the package. Uses `__read_manifest_file`.                                              |
| "           | `_get_field_index()`              | Mid        | **Input:** `field_name`. **Output:** The numerical index (column number) of a field. Uses `__get_manifest_header`.                                  |
| "           | `_get_manifest_field()`           | Mid        | **Input:** `pkg_name`, `field_name`. **Output:** The value of a specific field for a package. Orchestrates `_get_manifest_row` and `_get_field_index`. |
| **Task 1.4** | `__get_file_checksum()`           | Low        | **Input:** `file_path`. **Output:** The SHA256 checksum of the file.                                                                               |
| "           | `__get_header_meta()`             | Low        | **Input:** `file_path`, `meta_key`. **Output:** The value of a `# key: value` pair from the file's comment header. Uses `grep` and `sed`/`awk`.       |
| "           | `_get_source_path()`              | Mid        | **Input:** `pkg_name` (e.g., `fx.knife`). **Output:** The absolute path to the source script. Uses `_resolve_pkg_prefix` to find the correct subdir. |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- TECHNICAL_BREAKDOWN_M2_SECTION_8 SENTINEL | lines: 136 | words: 799 | headers: 1 | tables: 1 ----- #

<br>
<br>

## 8. Technical Breakdown: Milestone 2

This section provides the specific, function-level implementation plan for the tasks defined in Milestone 2.

| PRD Task     | Component / Function               | Ordinality | Description                                                                                                                                                    |
| :----------- | :--------------------------------- | :--------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Task 2.1** | `do_normalize()`                   | High-Order | **Input:** `pkg_name`. Orchestrates the normalization process.                                                                                                   |
| "           | `_check_git_status()`              | Mid        | **Input:** `file_path`. Checks if the file is tracked and has uncommitted changes. Halts execution if changes are found.                                         |
| "           | `__backup_file()`                  | Low        | **Input:** `file_path`. Copies the file to `$BACKUP_DIR` with an `.orig` extension. Ensures `BACKUP_DIR` exists.                                                   |
| "           | `__inject_header()`                | Low        | **Input:** `file_path`. Uses `sed` to insert the normalized header and `APP_*` variable block after the shebang line.                                             |
| **Task 2.2** | `do_register()`                    | High-Order | **Input:** `pkg_name`. Orchestrates gathering metadata and adding a new row to the manifest.                                                                     |
| "           | `_gather_package_meta()`           | Mid        | **Input:** `pkg_name`. Calls all necessary M1 helpers (`_get_source_path`, `__get_header_meta`, `__get_file_checksum`, etc.) to collect data for a new manifest row. |
| "           | `_build_manifest_row()`            | Mid        | **Input:** (all metadata fields). **Output:** A single, correctly formatted (tab-delimited, `::` EOL) manifest row string.                                         |
| "           | `__add_row_to_manifest()`          | Low        | **Input:** `row_string`. Appends the formatted string to the `$MANIFEST_PATH`. Creates manifest with header if it doesn't exist.                                  |
| **Task 2.3** | `do_install()`                     | High-Order | **Input:** `pkg_name`. The main orchestrator for the "up" lifecycle. Checks status and calls helpers sequentially.                                               |
| "           | `_update_manifest_field()`         | Mid        | **Input:** `pkg_name`, `field_name`, `new_value`. **Action:** Uses `sed -i` to find the correct row and column and replace the value in the manifest file.           |
| "           | `_load_package()`                  | Mid        | **Input:** `pkg_name`. Orchestrates copying the file to the lib dir and updating status. Calls `__copy_file` and `_update_manifest_field`.                         |
| "           | `_link_package()`                  | Mid        | **Input:** `pkg_name`. Orchestrates creating the symlink and updating status. Calls `__create_symlink` and `_update_manifest_field`.                               |
| "           | `__copy_file()`                    | Low        | **Input:** `src_path`, `dest_path`. Copies the file. Ensures destination directory exists.                                                                      |
| "           | `__create_symlink()`               | Low        | **Input:** `src_path`, `link_path`. Creates the symlink. Handles existing link removal if needed.                                                                |
| **Task 2.4** | `do_status()`                      | High-Order | **Input:** `pkg_name` or `all`. Fetches and displays formatted manifest data for the specified package(s).                                                       |
| "           | `do_meta()`                        | High-Order | **Input:** `pkg_name`. Fetches and displays the known key-value metadata from the source script's header.                                                        |

<br>
<br>

<--- START OF FILE PRD_PACKAGEX.md --->
> PRD: packagex, Version: 0.1, Status: DRAFT

# ----- PRD_PACKAGEX_MAIN_SENTINEL | lines: 687 | words: 3418 | sections: 9 | headers: 12 | tables: 10 ----- #

<br>
<br>

# 📦 PRD: packagex

<br>
<br>

# ----- OVERVIEW_AND_GOALS_SECTION_1 SENTINEL ----- #

<br>
<br>

## 1. Overview & Goals

`packagex` is a command-line utility for managing a personal library of Bash scripts, adhering to the BASHFX architecture. It automates the installation, state tracking, and lifecycle management of scripts from a development source tree into a dedicated, user-owned directory structure (`~/.my/`).

The primary goals of this project are:

| Goal                 | Description                                                                                                                                                    |
| :------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Stateful Management**  | Track the status of every script (`KNOWN`, `LOADED`, `INSTALLED`, `DISABLED`, etc.) in a persistent, machine-readable manifest file.                           |
| **Symmetrical Lifecycle** | Ensure every action has a corresponding, "rewindable" counter-action (`install`/`uninstall`, `enable`/`disable`).                                           |
| **Architectural Purity** | Strictly implement the principles of the `BASHFX Architecture.md`, especially Function Ordinality, XDG+ pathing, and standard interface conventions.          |
| **Developer Ergonomics** | Provide developers with tools to `normalize` script headers, inspect file `meta`data, and validate file integrity via `checksum`s.                           |
| **Self-Containment**     | Confine all installation artifacts (scripts, links, configuration) to a predictable, non-polluting root directory (`~/.my/`) as defined in the project brief. |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- CORE_CONCEPTS_SECTION_2 SENTINEL ----- #

<br>
<br>

## 2. Core Concepts & Definitions

The following concepts define the core functionality and assumptions of the `packagex` utility.

| Concept                 | Definition                                                                                                                                                                |
| :---------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Package**             | A source script file (e.g., `knife.sh`) located within a designated source directory (e.g., `$SRC_TREE/pkgs/fx/`). Its canonical name is prefixed (e.g., `fx.knife`).           |
| **Manifest**            | The single source of truth for package *state*. A tab-delimited file located at `$MANIFEST_PATH` (`~/.pkg_manifest`) that tracks all known packages and their metadata.           |
| **Package Lifecycle**   | The series of states a package can be in: `UNKNOWN` -> `INCOMPLETE` -> `KNOWN` -> `LOADED` -> `INSTALLED`. The "down" cycle includes `DISABLED` -> `REMOVED` -> `CLEANED`. |
| **Installation Pattern**  | A two-step process: (1) Copy the source file to `${TARGET_LIB_DIR}/<namespace>/`. (2) Create a symlink from the library file to `${TARGET_BIN_DIR}/<alias>`.                   |
| **Function Ordinality** | A strict hierarchy (`do_*` > `_*` > `__*`) that separates user-facing logic from "close-to-the-metal" system tasks, as defined in the architecture.                             |
| **Normalization**       | The process of injecting a standardized header block and `APP_*` variables into a source script file to ensure it is compliant and can be fully registered.                   |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- MILESTONE_1_SECTION_3 SENTINEL | lines: 27 | words: 183 | tasks: 4 | tables: 1 ----- #

<br>
<br>

## 3. Milestone 1: Foundation & Core Logic

The goal of this milestone is to establish the script skeleton, argument parsing, and core helper functions for reading state from files and the manifest.

| Task         | Description                                                                                                                                                   | Execution Hints                                                                    |
| :----------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------ | :--------------------------------------------------------------------------------- |
| **Task 1.1** | **Create Script Skeleton:** Generate the `packagex` file following the "Major Script" template, including stubs for `main`, `dispatch`, `options`, and `usage`.  | Use standard function comment bars (Sec 5.0.14).                                   |
| **Task 1.2** | **Implement `options()` Parser:** Implement the `options()` function to parse standard flags (`-d`, `-t`, `-q`, `-f`, `-y`, `-D`) and set `opt_*` variables.      | Use a `while/case` loop. Adhere to standard flag behavior (Sec 3.1).               |
| **Task 1.3** | **Implement Manifest Read Helpers:** Create mid (`_`) and low-level (`__`) functions to read and parse the manifest (`_get_manifest_row`, `_get_manifest_field`). | Handle the tab delimiter and `::` EOL marker. The header defines the column order. |
| **Task 1.4** | **Implement Package Read Helpers:** Create helpers to get info from source files (`_get_source_path`, `__get_file_checksum`, `__get_header_meta`).              | Implement the `utils` -> `util` prefix logic within `_get_source_path`.            |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- MILESTONE_2_SECTION_4 SENTINEL | lines: 30 | words: 191 | tasks: 4 | tables: 1 ----- #

<br>
<br>

## 4. Milestone 2: Primary Lifecycle (The "Up" Cycle)

The goal of this milestone is to implement the core commands that move a package from an `UNKNOWN` state to a fully `INSTALLED` state.

| Task         | Description                                                                                                                                                                                                                                                          | Execution Hints                                                                                                                            |
| :----------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------- |
| **Task 2.1** | **Implement `do_normalize`:** Inject the standard header and `APP_*` variables into a source script.                                                                                                                                                                   | This is a destructive operation. Must check git status and create a backup in `.orig/`.                                                    |
| **Task 2.2** | **Implement `do_register`:** Read metadata from a source script, create a manifest row, and set status to `INCOMPLETE` or `KNOWN` based on the completeness of the metadata.                                                                                              | Use low-level `__write_row_to_manifest` helper.                                                                                            |
| **Task 2.3** | **Implement `do_install`:** Orchestrate the full "up" lifecycle. It must call register/load logic if prerequisites are not met, copy the file to the library, and create the symlink in the bin directory.                                                              | This function exemplifies Function Ordinality, calling mid-level helpers which in turn call low-level `__copy_file`, `__create_symlink`, etc. |
| **Task 2.4** | **Implement `do_status` & `do_meta`:** Create the read-only commands to display the formatted manifest entry (`status`) and the parsed header metadata from a source file (`meta`).                                                                                     | These are ideal for testing the foundational helpers from Milestone 1.                                                                     |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- MILESTONE_3_SECTION_5 SENTINEL | lines: 31 | words: 189 | tasks: 4 | tables: 1 ----- #

<br>
<br>

## 5. Milestone 3: Symmetrical Lifecycle & Maintenance

The goal of this milestone is to implement the "down" lifecycle and maintenance utilities, ensuring the system is fully rewindable and adheres to the architectural principle of a Symmetrical Lifecycle.

| Task         | Description                                                                                                                                 | Execution Hints                                                                      |
| :----------- | :------------------------------------------------------------------------------------------------------------------------------------------ | :----------------------------------------------------------------------------------- |
| **Task 3.1** | **Implement `do_disable` & `do_enable`:** Remove or recreate the symlink in the bin directory and toggle the manifest status accordingly.       | These commands only manipulate the symlink and the manifest status field.            |
| **Task 3.2** | **Implement `do_uninstall`:** Remove the symlink and the library file, then update the manifest status to `REMOVED`.                            | Actions must be performed in the reverse order of `install`.                         |
| **Task 3.3** | **Implement `do_restore`:** For a package marked as `REMOVED`, use existing manifest data to re-run the `install` logic.                        | This command trusts the manifest data and avoids re-scanning the source file.        |
| **Task 3.4** | **Implement `do_clean`:** Find all packages with the status `REMOVED` and permanently delete their corresponding rows from the manifest file. | This is a destructive data operation and must prompt the user unless `-y` is passed. |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- CONFIG_AND_SCOPE_SECTION_6 SENTINEL | lines: 44 | words: 229 | headers: 2 | tables: 2 ----- #

<br>
<br>

## 6. Configuration & Scope

### 6.1 Configuration Variables

These variables define the core paths and settings for the `packagex` script. They should be defined as `readonly` globals near the top of the script.

| Variable              | Default / Example Value       | Description                                                |
| :-------------------- | :---------------------------- | :--------------------------------------------------------- |
| `APP_NAME`            | `packagex`                    | The primary name of the script.                            |
| `ALIAS_NAME`          | `pkgx`                        | The short alias for the script.                            |
| `SRC_TREE`            | *User Defined*                | Path to the source project root.                           |
| `TARGET_BASE_DIR`     | `$HOME/.my`                   | The root directory for all installed artifacts.            |
| `TARGET_NAMESPACE`    | `tmp`                         | The installation subdirectory within lib and bin.          |
| `TARGET_LIB_DIR`      | `$TARGET_BASE_DIR/lib`        | Base directory for where library scripts are copied.       |
| `TARGET_BIN_DIR`      | `$TARGET_BASE_DIR/bin`        | Base directory for where executables are linked.           |
| `MANIFEST_PATH`       | `$HOME/.pkg_manifest`         | Full path to the package state manifest file.              |
| `BACKUP_DIR`          | `$SRC_TREE/.orig`             | Directory for storing backups before `normalize` operations. |
| `BUILD_START_NUMBER`  | `1000`                        | The initial build number for new packages.                 |

### 6.2 Out of Scope (MVP)

The following features are explicitly not part of the Minimum Viable Product.

| Feature                       | Reason / Notes                                                                   |
| :---------------------------- | :------------------------------------------------------------------------------- |
| **Bulk Operations**           | Commands will operate on one package at a time (e.g., `pkgx install fx.knife`).    |
| **Library Installation**      | The scope is limited to installing executable scripts from `pkgs/fx` and `pkgs/utils`. |
| **Full Version Management**   | The script will only manage build numbers. Semantic versioning is a manual process. |
| **Complex Dependency Mgmt.** | The `deps` field is informational; the script will not install external dependencies. |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- TECHNICAL_BREAKDOWN_M1_SECTION_7 SENTINEL | lines: 123 | words: 706 | headers: 1 | tables: 1 ----- #

<br>
<br>

## 7. Technical Breakdown: Milestone 1

This section provides the specific, function-level implementation plan for the tasks defined in Milestone 1.

| PRD Task     | Component / Function              | Ordinality | Description                                                                                                                                       |
| :----------- | :-------------------------------- | :--------- | :------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Task 1.1** | *Script Structure*                | -          | Create the `packagex` file with sections as comments per Arch. Sec 5.2.1: shebang, meta, portable, readonly, config, helpers, dispatch, main, etc.   |
| "           | `readonly` variables            | Global     | Define all configuration variables from Sec 6.1 as `readonly` globals.                                                                            |
| "           | `main()`                          | Super      | Create stub. Will orchestrate `options` and `dispatch` calls.                                                                                     |
| "           | `dispatch()`                      | Super      | Create stub. Will contain the main `case` statement for routing commands to `do_*` functions.                                                       |
| "           | `usage()`                         | High-Order | Create stub. Will contain the help text for the script.                                                                                           |
| **Task 1.2** | `options()`                       | High-Order | Create function body with `while getopts` loop to parse flags: `-d, -t, -q, -f, -y, -D`.                                                           |
| "           | `opt_*` variables                 | Global     | Declare all `opt_*` variables (e.g., `opt_debug=0`, `opt_force=0`) before the `options()` function.                                                   |
| **Task 1.3** | `__read_manifest_file()`          | Low        | **Input:** (none). **Output:** Writes manifest content to a global array (e.g., `MANIFEST_DATA`). Handles file-not-found error.                      |
| "           | `__get_manifest_header()`         | Low        | **Input:** (none). **Output:** The first line of the manifest. Caches result.                                                                      |
| "           | `_resolve_pkg_prefix()`           | Mid        | **Input:** `pkg_dir_name`. **Output:** The correct prefix (`fx`, `util`). Contains the `utils` -> `util` logic.                                      |
| "           | `_get_manifest_row()`             | Mid        | **Input:** `pkg_name`. **Output:** The full manifest line for the package. Uses `__read_manifest_file`.                                              |
| "           | `_get_field_index()`              | Mid        | **Input:** `field_name`. **Output:** The numerical index (column number) of a field. Uses `__get_manifest_header`.                                  |
| "           | `_get_manifest_field()`           | Mid        | **Input:** `pkg_name`, `field_name`. **Output:** The value of a specific field for a package. Orchestrates `_get_manifest_row` and `_get_field_index`. |
| **Task 1.4** | `__get_file_checksum()`           | Low        | **Input:** `file_path`. **Output:** The SHA256 checksum of the file.                                                                               |
| "           | `__get_header_meta()`             | Low        | **Input:** `file_path`, `meta_key`. **Output:** The value of a `# key: value` pair from the file's comment header. Uses `grep` and `sed`/`awk`.       |
| "           | `_get_source_path()`              | Mid        | **Input:** `pkg_name` (e.g., `fx.knife`). **Output:** The absolute path to the source script. Uses `_resolve_pkg_prefix` to find the correct subdir. |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- TECHNICAL_BREAKDOWN_M2_SECTION_8 SENTINEL | lines: 136 | words: 799 | headers: 1 | tables: 1 ----- #

<br>
<br>

## 8. Technical Breakdown: Milestone 2

This section provides the specific, function-level implementation plan for the tasks defined in Milestone 2.

| PRD Task     | Component / Function               | Ordinality | Description                                                                                                                                                    |
| :----------- | :--------------------------------- | :--------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Task 2.1** | `do_normalize()`                   | High-Order | **Input:** `pkg_name`. Orchestrates the normalization process.                                                                                                   |
| "           | `_check_git_status()`              | Mid        | **Input:** `file_path`. Checks if the file is tracked and has uncommitted changes. Halts execution if changes are found.                                         |
| "           | `__backup_file()`                  | Low        | **Input:** `file_path`. Copies the file to `$BACKUP_DIR` with an `.orig` extension. Ensures `BACKUP_DIR` exists.                                                   |
| "           | `__inject_header()`                | Low        | **Input:** `file_path`. Uses `sed` to insert the normalized header and `APP_*` variable block after the shebang line.                                             |
| **Task 2.2** | `do_register()`                    | High-Order | **Input:** `pkg_name`. Orchestrates gathering metadata and adding a new row to the manifest.                                                                     |
| "           | `_gather_package_meta()`           | Mid        | **Input:** `pkg_name`. Calls all necessary M1 helpers (`_get_source_path`, `__get_header_meta`, `__get_file_checksum`, etc.) to collect data for a new manifest row. |
| "           | `_build_manifest_row()`            | Mid        | **Input:** (all metadata fields). **Output:** A single, correctly formatted (tab-delimited, `::` EOL) manifest row string.                                         |
| "           | `__add_row_to_manifest()`          | Low        | **Input:** `row_string`. Appends the formatted string to the `$MANIFEST_PATH`. Creates manifest with header if it doesn't exist.                                  |
| **Task 2.3** | `do_install()`                     | High-Order | **Input:** `pkg_name`. The main orchestrator for the "up" lifecycle. Checks status and calls helpers sequentially.                                               |
| "           | `_update_manifest_field()`         | Mid        | **Input:** `pkg_name`, `field_name`, `new_value`. **Action:** Uses `sed -i` to find the correct row and column and replace the value in the manifest file.           |
| "           | `_load_package()`                  | Mid        | **Input:** `pkg_name`. Orchestrates copying the file to the lib dir and updating status. Calls `__copy_file` and `_update_manifest_field`.                         |
| "           | `_link_package()`                  | Mid        | **Input:** `pkg_name`. Orchestrates creating the symlink and updating status. Calls `__create_symlink` and `_update_manifest_field`.                               |
| "           | `__copy_file()`                    | Low        | **Input:** `src_path`, `dest_path`. Copies the file. Ensures destination directory exists.                                                                      |
| "           | `__create_symlink()`               | Low        | **Input:** `src_path`, `link_path`. Creates the symlink. Handles existing link removal if needed.                                                                |
| **Task 2.4** | `do_status()`                      | High-Order | **Input:** `pkg_name` or `all`. Fetches and displays formatted manifest data for the specified package(s).                                                       |
| "           | `do_meta()`                        | High-Order | **Input:** `pkg_name`. Fetches and displays the known key-value metadata from the source script's header.                                                        |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- TECHNICAL_BREAKDOWN_M3_SECTION_9 SENTINEL | lines: 121 | words: 703 | headers: 1 | tables: 1 ----- #

<br>
<br>

## 9. Technical Breakdown: Milestone 3

This section provides the specific, function-level implementation plan for the tasks defined in Milestone 3.

| PRD Task     | Component / Function               | Ordinality | Description                                                                                                                                              |
| :----------- | :--------------------------------- | :--------- | :------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Task 3.1** | `do_disable()`                     | High-Order | **Input:** `pkg_name`. Checks if status is `INSTALLED`. Calls `__remove_symlink` and updates status to `DISABLED`.                                         |
| "           | `do_enable()`                      | High-Order | **Input:** `pkg_name`. Checks if status is `DISABLED`. Calls the existing `_link_package` helper (from M2) to relink and update status to `INSTALLED`.       |
| "           | `__remove_symlink()`               | Low        | **Input:** `link_path`. Atomically removes the specified symlink.                                                                                        |
| **Task 3.2** | `do_uninstall()`                   | High-Order | **Input:** `pkg_name`. Orchestrates the full uninstall process.                                                                                          |
| "           | `_uninstall_package()`             | Mid        | **Input:** `pkg_name`. Orchestrates artifact removal. Calls `__remove_symlink` and `__remove_file`, then updates manifest status to `REMOVED`.             |
| "           | `__remove_file()`                  | Low        | **Input:** `file_path`. Atomically removes the specified file from the library directory.                                                                |
| **Task 3.3** | `do_restore()`                     | High-Order | **Input:** `pkg_name`. Checks if status is `REMOVED`. Calls `_load_package` and `_link_package` directly, trusting existing manifest data.                   |
| **Task 3.4** | `do_clean()`                       | High-Order | **Input:** `pkg_name`. After user confirmation, calls `__remove_row_from_manifest` for a package with `REMOVED` status.                                    |
| "           | `_confirm_action()`                | Mid        | **Input:** `prompt_string`. A generic helper that prompts the user for [y/N] confirmation. Returns success/fail based on input. Respects `opt_yes` flag. |
| "           | `__remove_row_from_manifest()`     | Low        | **Input:** `pkg_name`. Uses `sed -i` to find and delete the entire line corresponding to the package name from the manifest.                               |

<br>
<br>
<--- START OF FILE PRD_PACKAGEX.md --->
> PRD: packagex, Version: 0.1, Status: DRAFT

# ----- PRD_PACKAGEX_MAIN_SENTINEL | lines: 742 | words: 3804 | sections: 10 | headers: 13 | tables: 11 ----- #

<br>
<br>

# 📦 PRD: packagex

<br>
<br>

# ----- OVERVIEW_AND_GOALS_SECTION_1 SENTINEL ----- #

<br>
<br>

## 1. Overview & Goals

`packagex` is a command-line utility for managing a personal library of Bash scripts, adhering to the BASHFX architecture. It automates the installation, state tracking, and lifecycle management of scripts from a development source tree into a dedicated, user-owned directory structure (`~/.my/`).

The primary goals of this project are:

| Goal                 | Description                                                                                                                                                    |
| :------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Stateful Management**  | Track the status of every script (`KNOWN`, `LOADED`, `INSTALLED`, `DISABLED`, etc.) in a persistent, machine-readable manifest file.                           |
| **Symmetrical Lifecycle** | Ensure every action has a corresponding, "rewindable" counter-action (`install`/`uninstall`, `enable`/`disable`).                                           |
| **Architectural Purity** | Strictly implement the principles of the `BASHFX Architecture.md`, especially Function Ordinality, XDG+ pathing, and standard interface conventions.          |
| **Developer Ergonomics** | Provide developers with tools to `normalize` script headers, inspect file `meta`data, and validate file integrity via `checksum`s.                           |
| **Self-Containment**     | Confine all installation artifacts (scripts, links, configuration) to a predictable, non-polluting root directory (`~/.my/`) as defined in the project brief. |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- CORE_CONCEPTS_SECTION_2 SENTINEL ----- #

<br>
<br>

## 2. Core Concepts & Definitions

The following concepts define the core functionality and assumptions of the `packagex` utility.

| Concept                 | Definition                                                                                                                                                                |
| :---------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Package**             | A source script file (e.g., `knife.sh`) located within a designated source directory (e.g., `$SRC_TREE/pkgs/fx/`). Its canonical name is prefixed (e.g., `fx.knife`).           |
| **Manifest**            | The single source of truth for package *state*. A tab-delimited file located at `$MANIFEST_PATH` (`~/.pkg_manifest`) that tracks all known packages and their metadata.           |
| **Package Lifecycle**   | The series of states a package can be in: `UNKNOWN` -> `INCOMPLETE` -> `KNOWN` -> `LOADED` -> `INSTALLED`. The "down" cycle includes `DISABLED` -> `REMOVED` -> `CLEANED`. |
| **Installation Pattern**  | A two-step process: (1) Copy the source file to `${TARGET_LIB_DIR}/<namespace>/`. (2) Create a symlink from the library file to `${TARGET_BIN_DIR}/<alias>`.                   |
| **Function Ordinality** | A strict hierarchy (`do_*` > `_*` > `__*`) that separates user-facing logic from "close-to-the-metal" system tasks, as defined in the architecture.                             |
| **Normalization**       | The process of injecting a standardized header block and `APP_*` variables into a source script file to ensure it is compliant and can be fully registered.                   |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- MILESTONE_1_SECTION_3 SENTINEL | lines: 27 | words: 183 | tasks: 4 | tables: 1 ----- #

<br>
<br>

## 3. Milestone 1: Foundation & Core Logic

The goal of this milestone is to establish the script skeleton, argument parsing, and core helper functions for reading state from files and the manifest.

| Task         | Description                                                                                                                                                   | Execution Hints                                                                    |
| :----------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------ | :--------------------------------------------------------------------------------- |
| **Task 1.1** | **Create Script Skeleton:** Generate the `packagex` file following the "Major Script" template, including stubs for `main`, `dispatch`, `options`, and `usage`.  | Use standard function comment bars (Sec 5.0.14).                                   |
| **Task 1.2** | **Implement `options()` Parser:** Implement the `options()` function to parse standard flags (`-d`, `-t`, `-q`, `-f`, `-y`, `-D`) and set `opt_*` variables.      | Use a `while/case` loop. Adhere to standard flag behavior (Sec 3.1).               |
| **Task 1.3** | **Implement Manifest Read Helpers:** Create mid (`_`) and low-level (`__`) functions to read and parse the manifest (`_get_manifest_row`, `_get_manifest_field`). | Handle the tab delimiter and `::` EOL marker. The header defines the column order. |
| **Task 1.4** | **Implement Package Read Helpers:** Create helpers to get info from source files (`_get_source_path`, `__get_file_checksum`, `__get_header_meta`).              | Implement the `utils` -> `util` prefix logic within `_get_source_path`.            |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- MILESTONE_2_SECTION_4 SENTINEL | lines: 30 | words: 191 | tasks: 4 | tables: 1 ----- #

<br>
<br>

## 4. Milestone 2: Primary Lifecycle (The "Up" Cycle)

The goal of this milestone is to implement the core commands that move a package from an `UNKNOWN` state to a fully `INSTALLED` state.

| Task         | Description                                                                                                                                                                                                                                                          | Execution Hints                                                                                                                            |
| :----------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------- |
| **Task 2.1** | **Implement `do_normalize`:** Inject the standard header and `APP_*` variables into a source script.                                                                                                                                                                   | This is a destructive operation. Must check git status and create a backup in `.orig/`.                                                    |
| **Task 2.2** | **Implement `do_register`:** Read metadata from a source script, create a manifest row, and set status to `INCOMPLETE` or `KNOWN` based on the completeness of the metadata.                                                                                              | Use low-level `__write_row_to_manifest` helper.                                                                                            |
| **Task 2.3** | **Implement `do_install`:** Orchestrate the full "up" lifecycle. It must call register/load logic if prerequisites are not met, copy the file to the library, and create the symlink in the bin directory.                                                              | This function exemplifies Function Ordinality, calling mid-level helpers which in turn call low-level `__copy_file`, `__create_symlink`, etc. |
| **Task 2.4** | **Implement `do_status` & `do_meta`:** Create the read-only commands to display the formatted manifest entry (`status`) and the parsed header metadata from a source file (`meta`).                                                                                     | These are ideal for testing the foundational helpers from Milestone 1.                                                                     |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- MILESTONE_3_SECTION_5 SENTINEL | lines: 31 | words: 189 | tasks: 4 | tables: 1 ----- #

<br>
<br>

## 5. Milestone 3: Symmetrical Lifecycle & Maintenance

The goal of this milestone is to implement the "down" lifecycle and maintenance utilities, ensuring the system is fully rewindable and adheres to the architectural principle of a Symmetrical Lifecycle.

| Task         | Description                                                                                                                                 | Execution Hints                                                                      |
| :----------- | :------------------------------------------------------------------------------------------------------------------------------------------ | :----------------------------------------------------------------------------------- |
| **Task 3.1** | **Implement `do_disable` & `do_enable`:** Remove or recreate the symlink in the bin directory and toggle the manifest status accordingly.       | These commands only manipulate the symlink and the manifest status field.            |
| **Task 3.2** | **Implement `do_uninstall`:** Remove the symlink and the library file, then update the manifest status to `REMOVED`.                            | Actions must be performed in the reverse order of `install`.                         |
| **Task 3.3** | **Implement `do_restore`:** For a package marked as `REMOVED`, use existing manifest data to re-run the `install` logic.                        | This command trusts the manifest data and avoids re-scanning the source file.        |
| **Task 3.4** | **Implement `do_clean`:** Find all packages with the status `REMOVED` and permanently delete their corresponding rows from the manifest file. | This is a destructive data operation and must prompt the user unless `-y` is passed. |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- CONFIG_AND_SCOPE_SECTION_6 SENTINEL | lines: 44 | words: 229 | headers: 2 | tables: 2 ----- #

<br>
<br>

## 6. Configuration & Scope

### 6.1 Configuration Variables

These variables define the core paths and settings for the `packagex` script. They should be defined as `readonly` globals near the top of the script.

| Variable              | Default / Example Value       | Description                                                |
| :-------------------- | :---------------------------- | :--------------------------------------------------------- |
| `APP_NAME`            | `packagex`                    | The primary name of the script.                            |
| `ALIAS_NAME`          | `pkgx`                        | The short alias for the script.                            |
| `SRC_TREE`            | *User Defined*                | Path to the source project root.                           |
| `TARGET_BASE_DIR`     | `$HOME/.my`                   | The root directory for all installed artifacts.            |
| `TARGET_NAMESPACE`    | `tmp`                         | The installation subdirectory within lib and bin.          |
| `TARGET_LIB_DIR`      | `$TARGET_BASE_DIR/lib`        | Base directory for where library scripts are copied.       |
| `TARGET_BIN_DIR`      | `$TARGET_BASE_DIR/bin`        | Base directory for where executables are linked.           |
| `MANIFEST_PATH`       | `$HOME/.pkg_manifest`         | Full path to the package state manifest file.              |
| `BACKUP_DIR`          | `$SRC_TREE/.orig`             | Directory for storing backups before `normalize` operations. |
| `BUILD_START_NUMBER`  | `1000`                        | The initial build number for new packages.                 |

### 6.2 Out of Scope (MVP)

The following features are explicitly not part of the Minimum Viable Product.

| Feature                       | Reason / Notes                                                                   |
| :---------------------------- | :------------------------------------------------------------------------------- |
| **Bulk Operations**           | Commands will operate on one package at a time (e.g., `pkgx install fx.knife`).    |
| **Library Installation**      | The scope is limited to installing executable scripts from `pkgs/fx` and `pkgs/utils`. |
| **Full Version Management**   | The script will only manage build numbers. Semantic versioning is a manual process. |
| **Complex Dependency Mgmt.** | The `deps` field is informational; the script will not install external dependencies. |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- TECHNICAL_BREAKDOWN_M1_SECTION_7 SENTINEL | lines: 123 | words: 706 | headers: 1 | tables: 1 ----- #

<br>
<br>

## 7. Technical Breakdown: Milestone 1

This section provides the specific, function-level implementation plan for the tasks defined in Milestone 1.

| PRD Task     | Component / Function              | Ordinality | Description                                                                                                                                       |
| :----------- | :-------------------------------- | :--------- | :------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Task 1.1** | *Script Structure*                | -          | Create the `packagex` file with sections as comments per Arch. Sec 5.2.1: shebang, meta, portable, readonly, config, helpers, dispatch, main, etc.   |
| "           | `readonly` variables            | Global     | Define all configuration variables from Sec 6.1 as `readonly` globals.                                                                            |
| "           | `main()`                          | Super      | Create stub. Will orchestrate `options` and `dispatch` calls.                                                                                     |
| "           | `dispatch()`                      | Super      | Create stub. Will contain the main `case` statement for routing commands to `do_*` functions.                                                       |
| "           | `usage()`                         | High-Order | Create stub. Will contain the help text for the script.                                                                                           |
| **Task 1.2** | `options()`                       | High-Order | Create function body with `while getopts` loop to parse flags: `-d, -t, -q, -f, -y, -D`.                                                           |
| "           | `opt_*` variables                 | Global     | Declare all `opt_*` variables (e.g., `opt_debug=0`, `opt_force=0`) before the `options()` function.                                                   |
| **Task 1.3** | `__read_manifest_file()`          | Low        | **Input:** (none). **Output:** Writes manifest content to a global array (e.g., `MANIFEST_DATA`). Handles file-not-found error.                      |
| "           | `__get_manifest_header()`         | Low        | **Input:** (none). **Output:** The first line of the manifest. Caches result.                                                                      |
| "           | `_resolve_pkg_prefix()`           | Mid        | **Input:** `pkg_dir_name`. **Output:** The correct prefix (`fx`, `util`). Contains the `utils` -> `util` logic.                                      |
| "           | `_get_manifest_row()`             | Mid        | **Input:** `pkg_name`. **Output:** The full manifest line for the package. Uses `__read_manifest_file`.                                              |
| "           | `_get_field_index()`              | Mid        | **Input:** `field_name`. **Output:** The numerical index (column number) of a field. Uses `__get_manifest_header`.                                  |
| "           | `_get_manifest_field()`           | Mid        | **Input:** `pkg_name`, `field_name`. **Output:** The value of a specific field for a package. Orchestrates `_get_manifest_row` and `_get_field_index`. |
| **Task 1.4** | `__get_file_checksum()`           | Low        | **Input:** `file_path`. **Output:** The SHA256 checksum of the file.                                                                               |
| "           | `__get_header_meta()`             | Low        | **Input:** `file_path`, `meta_key`. **Output:** The value of a `# key: value` pair from the file's comment header. Uses `grep` and `sed`/`awk`.       |
| "           | `_get_source_path()`              | Mid        | **Input:** `pkg_name` (e.g., `fx.knife`). **Output:** The absolute path to the source script. Uses `_resolve_pkg_prefix` to find the correct subdir. |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- TECHNICAL_BREAKDOWN_M2_SECTION_8 SENTINEL | lines: 136 | words: 799 | headers: 1 | tables: 1 ----- #

<br>
<br>

## 8. Technical Breakdown: Milestone 2

This section provides the specific, function-level implementation plan for the tasks defined in Milestone 2.

| PRD Task     | Component / Function               | Ordinality | Description                                                                                                                                                    |
| :----------- | :--------------------------------- | :--------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Task 2.1** | `do_normalize()`                   | High-Order | **Input:** `pkg_name`. Orchestrates the normalization process.                                                                                                   |
| "           | `_check_git_status()`              | Mid        | **Input:** `file_path`. Checks if the file is tracked and has uncommitted changes. Halts execution if changes are found.                                         |
| "           | `__backup_file()`                  | Low        | **Input:** `file_path`. Copies the file to `$BACKUP_DIR` with an `.orig` extension. Ensures `BACKUP_DIR` exists.                                                   |
| "           | `__inject_header()`                | Low        | **Input:** `file_path`. Uses `sed` to insert the normalized header and `APP_*` variable block after the shebang line.                                             |
| **Task 2.2** | `do_register()`                    | High-Order | **Input:** `pkg_name`. Orchestrates gathering metadata and adding a new row to the manifest.                                                                     |
| "           | `_gather_package_meta()`           | Mid        | **Input:** `pkg_name`. Calls all necessary M1 helpers (`_get_source_path`, `__get_header_meta`, `__get_file_checksum`, etc.) to collect data for a new manifest row. |
| "           | `_build_manifest_row()`            | Mid        | **Input:** (all metadata fields). **Output:** A single, correctly formatted (tab-delimited, `::` EOL) manifest row string.                                         |
| "           | `__add_row_to_manifest()`          | Low        | **Input:** `row_string`. Appends the formatted string to the `$MANIFEST_PATH`. Creates manifest with header if it doesn't exist.                                  |
| **Task 2.3** | `do_install()`                     | High-Order | **Input:** `pkg_name`. The main orchestrator for the "up" lifecycle. Checks status and calls helpers sequentially.                                               |
| "           | `_update_manifest_field()`         | Mid        | **Input:** `pkg_name`, `field_name`, `new_value`. **Action:** Uses `sed -i` to find the correct row and column and replace the value in the manifest file.           |
| "           | `_load_package()`                  | Mid        | **Input:** `pkg_name`. Orchestrates copying the file to the lib dir and updating status. Calls `__copy_file` and `_update_manifest_field`.                         |
| "           | `_link_package()`                  | Mid        | **Input:** `pkg_name`. Orchestrates creating the symlink and updating status. Calls `__create_symlink` and `_update_manifest_field`.                               |
| "           | `__copy_file()`                    | Low        | **Input:** `src_path`, `dest_path`. Copies the file. Ensures destination directory exists.                                                                      |
| "           | `__create_symlink()`               | Low        | **Input:** `src_path`, `link_path`. Creates the symlink. Handles existing link removal if needed.                                                                |
| **Task 2.4** | `do_status()`                      | High-Order | **Input:** `pkg_name` or `all`. Fetches and displays formatted manifest data for the specified package(s).                                                       |
| "           | `do_meta()`                        | High-Order | **Input:** `pkg_name`. Fetches and displays the known key-value metadata from the source script's header.                                                        |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- TECHNICAL_BREAKDOWN_M3_SECTION_9 SENTINEL | lines: 121 | words: 703 | headers: 1 | tables: 1 ----- #

<br>
<br>

## 9. Technical Breakdown: Milestone 3

This section provides the specific, function-level implementation plan for the tasks defined in Milestone 3.

| PRD Task     | Component / Function               | Ordinality | Description                                                                                                                                              |
| :----------- | :--------------------------------- | :--------- | :------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Task 3.1** | `do_disable()`                     | High-Order | **Input:** `pkg_name`. Checks if status is `INSTALLED`. Calls `__remove_symlink` and updates status to `DISABLED`.                                         |
| "           | `do_enable()`                      | High-Order | **Input:** `pkg_name`. Checks if status is `DISABLED`. Calls the existing `_link_package` helper (from M2) to relink and update status to `INSTALLED`.       |
| "           | `__remove_symlink()`               | Low        | **Input:** `link_path`. Atomically removes the specified symlink.                                                                                        |
| **Task 3.2** | `do_uninstall()`                   | High-Order | **Input:** `pkg_name`. Orchestrates the full uninstall process.                                                                                          |
| "           | `_uninstall_package()`             | Mid        | **Input:** `pkg_name`. Orchestrates artifact removal. Calls `__remove_symlink` and `__remove_file`, then updates manifest status to `REMOVED`.             |
| "           | `__remove_file()`                  | Low        | **Input:** `file_path`. Atomically removes the specified file from the library directory.                                                                |
| **Task 3.3** | `do_restore()`                     | High-Order | **Input:** `pkg_name`. Checks if status is `REMOVED`. Calls `_load_package` and `_link_package` directly, trusting existing manifest data.                   |
| **Task 3.4** | `do_clean()`                       | High-Order | **Input:** `pkg_name`. After user confirmation, calls `__remove_row_from_manifest` for a package with `REMOVED` status.                                    |
| "           | `_confirm_action()`                | Mid        | **Input:** `prompt_string`. A generic helper that prompts the user for [y/N] confirmation. Returns success/fail based on input. Respects `opt_yes` flag. |
| "           | `__remove_row_from_manifest()`     | Low        | **Input:** `pkg_name`. Uses `sed -i` to find and delete the entire line corresponding to the package name from the manifest.                               |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- EXCEPTIONS_SECTION_10 SENTINEL | lines: 43 | words: 386 | headers: 1 | tables: 1 ----- #

<br>
<br>

## 10. Exceptions, Edge Cases, & Resolutions

This section defines the mandated behavior for specific edge cases to ensure consistent and predictable script execution for the MVP.

| Situation                           | MVP Resolution                                                                                                                              | Justification / Future Work                                                                                                 |
| :---------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------ | :-------------------------------------------------------------------------------------------------------------------------- |
| **Invalid `SRC_TREE`**                | At script start, `main()` must validate that `$SRC_TREE` is a non-empty, existing directory. If not, print a fatal error and `exit 1`.        | This is a critical configuration error. The script cannot function without it. No complex recovery is needed for MVP.         |
| **Missing Write Permissions**       | Do not pre-check permissions. Let commands like `cp` or `mkdir` fail. The calling function must check the return code and exit with a clear error. | This is the simplest, most Unix-like approach. It avoids complex up-front checks and relies on standard tool behavior.       |
| **Manifest File Corruption**        | When parsing the manifest, if a line is malformed (e.g., wrong column count), `stderr` will show a warning, and the line will be skipped.      | This makes the parser resilient to minor corruption without adding complex recovery logic. Halting is too brittle for MVP.    |
| **Tool Incompatibility**            | Assume a **GNU** environment for tools like `sed` and `awk`. Note this dependency in the script's `portable` header comments.                 | Forcing a single standard is the simplest path to a working MVP. Cross-platform compatibility can be a `v2` feature.          |
| **Duplicate Package Registration**  | `do_register` should be idempotent. If a package already exists, treat the call as an update request. Print a notice and proceed with an update. | This provides a more user-friendly and symmetrical experience than simply erroring out. Follows the "Principle of Least Surprise." |
| **Missing Command Dependencies**    | Before using a critical external command (e.g., `git`), check for its existence with `command -v`. If not found, print an error and exit.      | This is a simple, required dependency check that prevents cryptic downstream errors and provides a clear user message.          |

<br>
<br>

<--- END OF FILE PRD_PACKAGEX.md --->