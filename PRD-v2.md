# ----- PRD_PACKAGEX_V2_1_MAIN_SENTINEL | lines: 181 | words: 1012 | sections: 5 | headers: 6 | tables: 6 ----- #

<br>
<br>

# 📦 PRD: packagex v2.1

<br>
<br>

# ----- OVERVIEW_AND_GOALS_SECTION_1 SENTINEL ----- #

<br>
<br>

## 1. Overview & Goals

`packagex` is a command-line utility for managing a personal library of Bash scripts. It operates on a non-destructive **Workspace Paradigm**, creating and managing its own private copies of source scripts to avoid modifying the developer's pristine, version-controlled source tree.

The primary goals of this project are:

| Goal                    | Description                                                                                                                              |
| :---------------------- | :--------------------------------------------------------------------------------------------------------------------------------------- |
| **Source Integrity**      | **(Primary Goal)** Never modify the developer's original source files. All operations occur in a separate, managed workspace.          |
| **Stateful Management**   | Track the status of every package (`KNOWN`, `INSTALLED`, etc.) in a persistent, machine-readable manifest file.                           |
| **Symmetrical Lifecycle** | Ensure every action has a corresponding, "rewindable" counter-action (`install`/`uninstall`, `clean`/`register`).                        |
| **Workspace-Centric Ops** | All core operations (installation, metadata reads) are performed on managed "working copies" within the workspace.                       |
| **Developer Ergonomics**  | Provide granular commands to prepare the workspace (`prepare`), enrich metadata (`normalize`), and persist state (`register`).           |
| **Self-Containment**      | Confine all artifacts (workspace, installed scripts, manifest) to predictable, non-polluting, and clearly defined directory structures. |

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

## 2. Core Concepts & Definitions (v2.1)

| Concept            | Definition                                                                                                                                    |
| :----------------- | :-------------------------------------------------------------------------------------------------------------------------------------------- |
| **Pristine Source**  | The developer's original script file, which `packagex` treats as strictly read-only.                                                          |
| **Workspace**        | A private directory (`.work/`) managed by `packagex` that contains its own copies of scripts. It is a volatile but reproducible cache.      |
| **Working Copy**     | (`*.pkg.sh`) A copy of a pristine source file within the workspace that `packagex` enriches with metadata and uses for installations.        |
| **Pristine Backup**  | (`*.orig.sh`) A clean copy of the pristine source file within the workspace, used as a baseline to detect changes with the `update` command. |
| **Manifest**         | The single source of truth for long-term package state. Its `path` field always points to the **Pristine Source**.                             |
| **Enrichment**       | The "Read-Modify-Write" protocol `packagex` uses to safely merge its canonical metadata with user-defined metadata in a Working Copy's header. |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- TASK_EXECUTION_PROTOCOL_SECTION_2A SENTINEL | lines: 81 | words: 462 | headers: 2 | tables: 2 ----- #

<br>
<br>

## 2A. Task Execution Protocol

Before implementation of any task from the technical breakdowns, a mandatory **Qualification Step** must be performed. This ensures that every task is clearly understood, correctly scoped, and of manageable complexity before work begins.

**The Qualification Step**

| Step | Action                                                                | Purpose                                                                          |
| :--- | :-------------------------------------------------------------------- | :------------------------------------------------------------------------------- |
| **1**  | **Declare Task**                                                      | State the specific task from the PRD to be implemented (e.g., "Task 1.2").       |
| **2**  | **Analyze & Decompose**                                               | Verbally outline the functions to be created or modified and their interactions. |
| **3**  | **Estimate Complexity**                                               | Assign a "Story Point" value based on the scale below.                           |
| **4**  | **Commit or Decompose**                                               | If the task is 3 points or less, commit to implementation. If 5+, go to Step 2.  |

**Complexity Point Scale**

| Points | Meaning                  | Example                                                                          |
| :----- | :----------------------- | :------------------------------------------------------------------------------- |
| **1**    | **Trivial**                | A single, well-understood change with no side effects (e.g., updating `usage()`).  |
| **2**    | **Simple**                 | Implementing one or two self-contained helper functions (e.g., `__get_file_checksum`). |
| **3**    | **Moderate**               | A high-level `do_*` function that orchestrates several existing helpers.         |
| **5+**   | **Complex / Must Decompose** | A large, multi-faceted task with many interactions (e.g., "Implement the entire `install` and `register` flow at once"). |

### The Milestone Gate Protocol

To accommodate manual, human-in-the-loop processes such as version control, the following rule is mandatory:

**At the completion of all tasks within a single Milestone, the agent MUST halt execution.**

The agent must state that the milestone is complete and explicitly wait for a confirmation command from the user before proceeding to the next milestone. This provides a required checkpoint for the user to save, test, and commit the completed body of work.

<br>
<br>


# ----- V2_1_COMMAND_HIERARCHY_SECTION_3 SENTINEL ----- #

<br>
<br>

## 3. The v2.1 Command Hierarchy

The v2.1 architecture breaks down the monolithic `register` command into a logical, state-based hierarchy. Each command has a single, clear responsibility.

| Command         | Responsibility                                                                                                 | Analogy                                   |
| :-------------- | :------------------------------------------------------------------------------------------------------------- | :---------------------------------------- |
| `prepare` **(New)** | **Workspace Gateway.** Creates the `.work/` directory and the atomic pair of `.pkg.sh` and `.orig.sh` files for a package. | "Staging the ingredients."                |
| `normalize`     | **Enrichment Engine.** Executes the "Read-Modify-Write" header protocol on the `.pkg.sh` file in the workspace. | "Preparing and seasoning the ingredients."|
| `register`      | **Manifest Writer.** Persists the state of the prepared package to the manifest file.                            | "Writing the recipe to the cookbook."     |
| `install`       | **Deployer.** Copies the final, enriched `.pkg.sh` file from the workspace to its destination.                   | "Serving the final dish."                 |

<br>
<br>
<br>
<br>

---

<br>
<br>
<br>
<br>

# ----- HIGH_LEVEL_MILESTONES_V2_1_SECTION_4 SENTINEL ----- #

<br>
<br>

## 4. High-Level Milestones (v2.1)

The implementation is broken down into three sequential milestones, architected around the Workspace Paradigm.

### Milestone 1: The Workspace Foundation

*Goal: Establish the non-destructive workspace and the tools to interact with it. All operations in this milestone are confined to the `.work/` directory.*

| Task Focus         | Core Commands to Implement | Key Outcome                                                                          |
| :----------------- | :------------------------- | :----------------------------------------------------------------------------------- |
| **Workspace Prep** | `prepare`                  | Create the namespaced `.work/` directory and populate it with working/backup copies. |
| **Enrichment**     | `normalize`                | Read, merge, and write enriched metadata headers back to the working copies.         |
| **Inspection**     | `meta`                     | Read and display the final, enriched metadata from a working copy.                   |

### Milestone 2: State Persistence & Deployment

*Goal: Connect the prepared workspace to the persistent manifest and the user's `PATH`.*

| Task Focus   | Core Commands to Implement | Key Outcome                                                                                      |
| :----------- | :------------------------- | :----------------------------------------------------------------------------------------------- |
| **State**      | `register`, `status`       | Write package state to the manifest; provide tools to inspect that state.                        |
| **Deployment** | `install`                  | Copy the prepared working copy from the workspace to the final `lib` and `bin` (symlink) paths. |

### Milestone 3: Symmetrical Lifecycle & Maintenance

*Goal: Implement the full "down" lifecycle and maintenance utilities to ensure the system is robust and rewindable.*

| Task Focus      | Core Commands to Implement     | Key Outcome                                                                                             |
| :-------------- | :----------------------------- | :------------------------------------------------------------------------------------------------------ |
| **Deactivation**  | `uninstall`, `enable`/`disable` | Provide "soft" deactivation (unlinking) that preserves the workspace for fast restoration.              |
| **Cleanup**       | `clean`                        | Implement "hard" removal that purges the package from the manifest AND its assets from the workspace.   |
| **Maintenance**   | `update`                       | Compare the pristine source to its workspace backup and trigger a re-registration if it has changed. |

<br>
<br>










it 

# ----- DEV_DRIVER_PROTOCOL_SECTION_4 SENTINEL | lines: 65 | words: 442 | headers: 3 | tables: 1 ----- #

<br>
<br>

## 4. The Dev Driver Protocol (`$`/`#`)

The Dev Driver is a core architectural pattern that provides a controlled "backdoor" for developers to interact with a script's internal functions directly from the command line for testing and debugging. It is only active when the script is run with the `-D` flag.

### 4.1 Dual Entry-Point Mechanism

The driver has two distinct entry points. The invoker used determines the state context in which the target function is executed.

| Invoker | Architectural Name | When it Runs                                                             | State Context                               | Typical Use Case                                                                                                   |
| :------ | :----------------- | :----------------------------------------------------------------------- | :------------------------------------------ | :----------------------------------------------------------------------------------------------------------------- |
| **`$`**   | **Pre-Dispatch**   | Handled in `main()` **before** the main `dispatch` function is called.     | **Not Guaranteed Stateful.** `options` has run. | Testing pure helper functions (`__get_file_checksum`) or inspecting state before the main application logic runs.      |
| **`#`**   | **Stateful**       | Handled as a special case **inside** the main `dispatch` function's `case`. | **Assumed Stateful.** Runs after normal setup. | Testing functions that depend on application state or flags parsed by `options()` (e.g., testing with `opt_force=1`).   |

**Exit Protocol:** Any successful invocation via the Dev Driver **must** terminate the script with `exit`. This is a safety mechanism to prevent the script from falling through to the normal command flow.

### 4.2 Core `dev_dispatch` Functionality

A single `dev_dispatch` function handles the logic for both invokers. Its primary purpose is to execute the specified function with the given arguments.

*   **Discoverability (`func`):** The command `pkgx -D $ func` is a special case. It does not execute a function named `func`. Instead, it calls an `__low_inspect` helper to print a sorted list of all available internal (`_`, `__`) and API (`do_*`) functions.
*   **Safety Guard:** The entire Dev Driver pattern is inert by default. It is activated **only** if the `DEV_MODE` global variable is set to `1` (e.g., `DEV_MODE=1 ./packagex ...`). All checks for this mode must be performed via a dedicated `is_dev()` guard function. Command-line activation via a `-D` flag is explicitly out of scope for the MVP.
<br>
<br>




# ----- TECHNICAL_BREAKDOWN_M1_V2_1_SECTION_6 SENTINEL | lines: 111 | words: 671 | headers: 1 | tables: 1 ----- #

<br>
<br>

## 6. Technical Breakdown: Milestone 1 (v2.1)

This section provides the specific, function-level implementation plan for the tasks defined in Milestone 1: The Workspace Foundation.

| PRD Task    | Component / Function               | Ordinality | Description                                                                                                                                                    |
| :---------- | :--------------------------------- | :--------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Prepare** | `do_prepare`                       | High-Order | **Input:** `pkg_name`. The public entry point for workspace preparation. Orchestrates the creation of the workspace for a package.                                 |
| "           | `_prepare_workspace_for_pkg`       | Mid        | **Input:** `pkg_name`. The atomic "gateway" function. Ensures the namespaced subdir exists, then calls helpers to create both the `.pkg.sh` and `.orig.sh` files. |
| "           | `_get_workspace_path()`            | Mid        | **Input:** `pkg_name`, `type (pkg\|orig)`. **Output:** The absolute path to a file within the namespaced workspace (e.g., `.work/fx/semver.pkg.sh`).               |
| "           | `__create_workspace_dir()`         | Low        | **Input:** `pkg_name`. Creates the required namespaced subdirectory within `.work/` (e.g., `.work/fx/`).                                                            |
| "           | `__create_working_copy()`          | Low        | **Input:** `src_path`, `dest_path`. Copies the pristine source to the `.pkg.sh` working copy path.                                                               |
| "           | `__create_pristine_backup()`       | Low        | **Input:** `src_path`, `dest_path`. Copies the pristine source to the `.orig.sh` backup path.                                                                    |
| **Normalize** | `do_normalize`                     | High-Order | **Input:** `pkg_name`. The public entry point for enrichment. Orchestrates the "Read-Modify-Write" protocol on the working copy.                                 |
| "           | `_enrich_working_copy()`           | Mid        | **Input:** `pkg_name`. Orchestrates the entire header enrichment process by calling the helpers for reading, modifying, and writing.                               |
| "           | `_get_all_header_meta()`           | Mid        | **Input:** `file_path`. **Output:** An associative array of all key-value pairs from the file's header. This is the "Read" step.                                   |
| "           | `_get_canonical_meta()`            | Mid        | **Input:** `pkg_name`. **Output:** An associative array of all values that `packagex` manages (e.g., status, checksum). This is the "Modify" step.                 |
| "           | `__write_header_block()`           | Low        | **Input:** `file_path`, `(in-memory_array)`. Overwrites the existing header in the file with the new, merged metadata. This is the "Write" step.                 |
| **Inspect**   | `do_meta`                          | High-Order | **Input:** `pkg_name`. The public entry point for inspection. Displays the enriched metadata from the package's **working copy**.                                  |
| "           | `_display_meta_array()`            | Mid        | **Input:** `(in-memory_array)`. Formats and prints the key-value pairs from a metadata array to `stdout` for the user.                                            |

<br>
<br>


# ----- TECHNICAL_BREAKDOWN_M2_V2_1_SECTION_7 SENTINEL | lines: 87 | words: 574 | headers: 1 | tables: 1 ----- #

<br>
<br>

## 7. Technical Breakdown: Milestone 2 (v2.1)

This section provides the specific, function-level implementation plan for the tasks defined in Milestone 2: State Persistence & Deployment.

| PRD Task     | Component / Function               | Ordinality | Description                                                                                                                                                    |
| :----------- | :--------------------------------- | :--------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **State**      | `do_register`                      | High-Order | **Input:** `pkg_name`. The public entry point for manifest writing. Orchestrates persisting the state of a prepared package to the manifest.                       |
| "            | `_register_package()`              | Mid        | **Input:** `pkg_name`. Ensures the workspace is prepared (calling `do_normalize` logic), then calls helpers to build and write the manifest row.                 |
| "            | `__write_manifest_row()`           | Low        | **Input:** `row_string`. A low-level writer that appends or updates a row in the manifest file. Handles creating the file with a header if it doesn't exist.     |
| "            | `do_status`                        | High-Order | **Input:** `pkg_name` or `all`. The public entry point for checking status. Fetches and displays formatted data from the manifest.                                 |
| "            | `_get_manifest_row()`              | Mid        | **Input:** `pkg_name`. **Output:** The raw manifest line for the package. (This function might be defined in a shared "Manifest Helpers" group).                |
| "            | `_display_status_info()`           | Mid        | **Input:** `row_string`. Formats and prints the contents of a manifest row for the user.                                                                       |
| **Deployment** | `do_install`                       | High-Order | **Input:** `pkg_name`. The public entry point for deployment. Orchestrates the deployment of the prepared working copy.                                          |
| "            | `_deploy_package()`                | Mid        | **Input:** `pkg_name`. Copies the working copy to `$TARGET_LIB_DIR` and creates the symlink in `$TARGET_BIN_DIR`.                                                |
| "            | `_update_manifest_status()`        | Mid        | **Input:** `pkg_name`, `new_status`. A dedicated helper to update only the `status` field for a package in the manifest.                                        |
| "            | `__copy_to_lib()`                  | Low        | **Input:** `src_path`, `dest_path`. A wrapper around `cp` to copy the working copy to its final library destination. (May reuse a generic `__copy_file` helper). |
| "            | `__create_bin_symlink()`           | Low        | **Input:** `lib_path`, `bin_path`. A wrapper around `ln -s` to create the executable symlink in the bin directory.                                                  |

<br>
<br>


# ----- TECHNICAL_BREAKDOWN_M3_V2_1_SECTION_8 SENTINEL | lines: 111 | words: 712 | headers: 1 | tables: 1 ----- #

<br>
<br>

## 8. Technical Breakdown: Milestone 3 (v2.1)

This section provides the specific, function-level implementation plan for the tasks defined in Milestone 3: Symmetrical Lifecycle & Maintenance.

| PRD Task       | Component / Function              | Ordinality | Description                                                                                                                                                    |
| :------------- | :-------------------------------- | :--------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Deactivation** | `do_uninstall`                    | High-Order | **Input:** `pkg_name`. Public entry point for "soft" deactivation. Orchestrates symlink and file removal without touching the workspace.                           |
| "              | `do_disable`                      | High-Order | **Input:** `pkg_name`. Public entry point. Removes the symlink but leaves the library file in place. Updates status to `DISABLED`.                                 |
| "              | `do_enable`                       | High-Order | **Input:** `pkg_name`. Public entry point. Recreates the symlink for a `DISABLED` package.                                                                       |
| "              | `_deactivate_package()`           | Mid        | **Input:** `pkg_name`. The core logic for `uninstall`. Calls `__remove_bin_symlink` and `__remove_lib_file`, then updates manifest status to `REMOVED`.             |
| "              | `__remove_bin_symlink()`          | Low        | **Input:** `pkg_name`. Removes the executable symlink from `$TARGET_BIN_DIR`.                                                                                    |
| "              | `__remove_lib_file()`             | Low        | **Input:** `pkg_name`. Removes the script file from `$TARGET_LIB_DIR`.                                                                                         |
| **Cleanup**      | `do_clean`                        | High-Order | **Input:** `pkg_name`. Public entry point for "hard" removal. Orchestrates the full purge of a package from the system.                                         |
| "              | `_purge_package()`                | Mid        | **Input:** `pkg_name`. The core logic for `clean`. Calls helpers to remove the manifest entry AND the package's assets from the `.work/` directory.             |
| "              | `__remove_manifest_row()`         | Low        | **Input:** `pkg_name`. Removes the entire row for a package from the manifest file.                                                                              |
| "              | `__remove_from_workspace()`       | Low        | **Input:** `pkg_name`. Removes both the `.pkg.sh` and `.orig.sh` files for a package from the namespaced `.work/` directory.                                      |
| **Maintenance**  | `do_update`                       | High-Order | **Input:** `pkg_name`. Public entry point. Orchestrates checking for source changes and re-registering if needed.                                                 |
| "              | `_is_update_required()`           | Mid        | **Input:** `pkg_name`. **Output:** `0` (true) or `1` (false). Compares the checksum of the pristine source with the pristine backup (`.orig.sh`) in the workspace. |
| "              | `_re_register_package()`          | Mid        | **Input:** `pkg_name`. The core logic for `update`. Calls helpers to remove the old workspace assets and then runs the full `do_prepare` and `do_register` flow again. |

<br>
<br>




# ----- LIFECYCLE_PROTOCOL_SECTION_9 SENTINEL | lines: 114 | words: 785 | headers: 3 | tables: 2 ----- #

<br>
<br>

## 9. The Package Lifecycle Protocol

This section provides explicit, literal guidance on the package state machine. It defines the preconditions, triggers, and outcomes for every state transition, serving as the definitive rulebook for the implementation of all lifecycle commands.

### 9.1 The Primary ("Up") Lifecycle

This sequence describes the process of taking a package from a non-existent state to a fully installed and usable state.

| State Transition                | Triggering Command | Preconditions (Critical Assumptions)                                                                       | Core Actions                                                                                                  | Final Manifest Status |
| :------------------------------ | :----------------- | :--------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------ | :-------------------- |
| **`UNKNOWN` -> `KNOWN`**          | `register`         | <ul><li>Pristine source file must exist.</li><li>Package must not already be in the manifest.</li></ul>      | <ul><li>Run `prepare` logic to create workspace.</li><li>Run `normalize` logic to enrich working copy.</li><li>Write new entry to manifest.</li></ul> | **`KNOWN`**           |
| **`KNOWN` -> `INSTALLED`**        | `install`          | <ul><li>Package status must be `KNOWN`.</li><li>Workspace (`.pkg.sh`) must exist and be valid.</li></ul>       | <ul><li>Copy `.pkg.sh` from workspace to `lib` dir.</li><li>Create executable symlink in `bin` dir.</li></ul>       | **`INSTALLED`**       |
| **`KNOWN` -> `KNOWN` (Refreshed)** | `update`           | <ul><li>Package status must be `KNOWN`.</li></ul>                                                          | <ul><li>Compare checksum of pristine source vs. workspace backup.</li><li>If different, re-run full `register` logic to refresh workspace and manifest.</li></ul> | **`KNOWN`** (w/ new data) |

### 9.2 The Symmetrical ("Down") Lifecycle

This sequence describes the process of deactivating, restoring, and permanently removing a package from the system.

| State Transition                  | Triggering Command | Preconditions (Critical Assumptions)                                                                  | Core Actions                                                                                                                                | Final Manifest Status |
| :-------------------------------- | :----------------- | :---------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------ | :-------------------- |
| **`INSTALLED` -> `DISABLED`**       | `disable`          | <ul><li>Package status must be `INSTALLED`.</li></ul>                                                   | <ul><li>Remove executable symlink from `bin` dir.</li></ul>                                                                                 | **`DISABLED`**        |
| **`DISABLED` -> `INSTALLED`**       | `enable`           | <ul><li>Package status must be `DISABLED`.</li><li>Script must still exist in `lib` dir.</li></ul>       | <ul><li>Re-create executable symlink in `bin` dir.</li></ul>                                                                                | **`INSTALLED`**       |
| **`INSTALLED` -> `REMOVED`**        | `uninstall`        | <ul><li>Package status must be `INSTALLED` or `DISABLED`.</li></ul>                                     | <ul><li>Remove symlink from `bin` (if exists).</li><li>Remove script file from `lib`.</li><li>Workspace is **left untouched**.</li></ul>       | **`REMOVED`**         |
| **`REMOVED` -> `INSTALLED`**        | `restore`          | <ul><li>Package status must be `REMOVED`.</li><li>Workspace (`.pkg.sh`) must still exist.</li></ul>    | <ul><li>Re-run `install` logic, using the existing workspace cache to deploy the package without re-processing the pristine source.</li></ul> | **`INSTALLED`**       |
| **`REMOVED` -> `(Deleted)`**        | `clean`            | <ul><li>Package status must be `REMOVED`.</li></ul>                                                   | <ul><li>Remove the package's row from the manifest.</li><li>Delete the package's assets (`.pkg.sh`, `.orig.sh`) from the workspace.</li></ul> | **(No Entry)**        |

<br>
<br>

# ----- STRUCTURAL_ASSUMPTIONS_SECTION_10 SENTINEL | lines: 75 | words: 494 | headers: 3 | tables: 1 ----- #

<br>
<br>

## 10. Structural & Environmental Assumptions

This section defines the explicit contract between `packagex` and the environment in which it operates, particularly regarding the structure of the source code it manages. Adherence to these assumptions is required for correct functionality.

### 10.1 The Source Tree (`SRC_TREE`)

*   **Configurable Root:** The `SRC_TREE` variable is a user-configurable setting. `packagex` is not hardcoded to a single project; it can be pointed at any directory, provided that directory respects the structural contract below.
*   **The `pkgs/` Directory:** `packagex` assumes that the root of all manageable packages is a directory named `pkgs/` located directly inside `SRC_TREE`. If this directory does not exist, no packages can be found.
*   **The Namespace Directory:** The first-level directories inside `pkgs/` define the **package namespace** (e.g., `pkgs/fx/`, `pkgs/utils/`).
    *   **Namespace Translation (MVP Rule):** A special-case translation rule exists for the `utils` namespace: it is always translated to `util` for canonical naming (e.g., `util.colorx`). This is a hardcoded, one-off rule for MVP simplicity.
    *   **Protected Namespaces:** The `fx` and `util` namespaces are considered reserved for internal use within the BASHFX ecosystem. While `packagex` will not prevent a user from using them, the user assumes the risk of future naming collisions.

### 10.2 The Package Path (MVP)

*   **The "Name-as-Directory" Pattern:** For the MVP, `packagex` assumes a strict and simple pathing structure. The script file must be nested inside a directory that shares its base name.
*   **Canonical Path Structure:** `pkgs/<namespace>/<pkg_name>/<pkg_name>.sh`
*   **Example:**
    *   **Path:** `pkgs/fx/knife/knife.sh`
    *   **Namespace:** `fx`
    *   **Package Name:** `knife`
    *   **Canonical ID:** `fx.knife`
*   **Out of Scope (Deep Nesting):** Deeper pathing (e.g., `pkgs/fun/thing/name/name.sh`) is not supported by the MVP's name resolution logic. The parser will only look at the first two levels (`pkgs/<namespace>`) to determine the package's identity.

<br>
<br>

# ----- ROADMAP_CONSIDERATIONS_SECTION_11 SENTINEL | lines: 52 | words: 326 | headers: 3 | tables: 1 ----- #

<br>
<br>

## 11. Future-Proofing & Roadmap Considerations

While the following features are explicitly out of scope for the v2.1 MVP, the implementation should be architected in a way that does not preclude their future addition. This section serves as a set of guiding principles for the development agent to ensure a clean evolution path to v3.x.

### 11.1 The v3.x Vision

The long-term vision for `packagex` is to evolve from a local-only package manager into a tool that can manage scripts from multiple, potentially remote, sources.

| Feature Area                | v3.x Goal                                                                                                                                |
| :-------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------- |
| **Multi-Source Management**   | Introduce a command-line flag (e.g., `--src-tree`) to override the default `SRC_TREE` at runtime, enabling seamless switching between projects. |
| **Remote Git Integration**    | Add the ability to download/clone a remote Git repository into a managed cache directory (`~/.my/repos/`).                                   |
| **Remote Package Sourcing** | Allow `packagex` to treat a cached remote repository as a valid `SRC_TREE`, enabling the installation of third-party scripts.                  |

### 11.2 Architectural Implications for the v2.1 Build

The v2.1 implementation must adhere to the following principles to avoid painting ourselves into a corner:

*   **No Hardcoded `SRC_TREE`:** All helper functions that interact with the source tree must receive the `SRC_TREE` path as an argument or read it from the global `readonly` variable. There should be no hardcoded paths that assume a single, static source location.
*   **Decouple Path Logic:** The functions responsible for resolving package paths (`_get_source_path`) must be self-contained and easily modifiable. This will allow us to plug in more sophisticated path resolution logic later (e.g., searching in `~/.my/repos/` if a local package isn't found).
*   **Generic Workspace Naming:** The workspace naming convention (`.work/`) should remain generic. We should not, for example, tie its name to the base name of the local `SRC_TREE`, which would complicate the addition of remote sources.

<br>
<br>

# ----- ARCHITECTURAL_GUARDRAILS_SECTION_12 SENTINEL | lines: 61 | words: 388 | headers: 1 | tables: 1 ----- #

<br>
<br>

## 12. Architectural Guardrails & Anti-Patterns

To ensure the v2.1 implementation remains robust and maintainable, it must be checked against the following set of "must-have" patterns and explicitly avoid their corresponding anti-patterns. These rules are derived from the post-mortem of previous development attempts.

| Anti-Pattern (What to Avoid)                                                               | Required Pattern (The BASHFX Way)                                                                                                                  |
| :----------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------- |
| **The "God" Function:** A single command (`register`) that attempts to manage the entire "up" lifecycle (workspace prep, enrichment, and manifest writing). | **Granular Command Hierarchy:** Each core step of the lifecycle (`prepare`, `normalize`, `register`) is its own independent, testable command. |
| **"Impure" Helpers:** A function with a "get" name that has side effects (e.g., `_get_working_path` also creating the workspace if it's missing). | **Strict Separation of Concerns:** Functions that "get" information are read-only. Functions that "create" or "write" are explicitly named as such. |
| **Broken Symmetry:** A "down" lifecycle command (`clean`) that does not fully reverse its "up" counterpart (`register`), leaving orphaned files in the workspace. | **Complete Lifecycle Symmetry:** `clean` must be a true and total "undo." It must purge the package's assets from both the manifest and the workspace. |
| **Ignoring Safety Guards:** A developer-only feature (`dev_driver`) that can be activated without the explicit `DEV_MODE` guard being in place. | **Guards are Non-Negotiable:** All developer-facing or potentially destructive functionality **must** be wrapped in an `is_dev()` check. No exceptions. |
| **Brittle Parsers:** Using complex, multi-line `sed` commands to rewrite file blocks.                                                                             | **Simple, Robust Tools:** The header protocol must use a simple, line-based `# key: value` format that can be reliably parsed with `grep` and `awk`.      |

<br>
<br>
