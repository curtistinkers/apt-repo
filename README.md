# APT Repository Website Infrastructure

This repository hosts the static frontend and indexing automation for the custom
APT repository served at **`http://apt.curtistinkers.com`**.

The project uses a dual-branch architecture deployed using GitHub Actions
to keep the `main` branch clean whilst securely handling binary package uploads.

---

## Architectural Overview

To keep development clean, the project isolates responsibilities between two
active branches:

```text
[Your Local Machine] 
         │  (Push layout/text changes)
         ▼
    [main Branch]
         │
         ▼ (Job 1: Rigid Linting & Verification)
         ▼ (Job 2: Jekyll compiles Markdown to static HTML)
   [gh-pages Branch]  ◄─── (External repos drop compiled .deb packages here)
         │
         ▼ (Job: Rebuilds Packages/Release maps & Deploys live)
[GitHub Pages Infrastructure]
         │
         ▼
   http://apt.curtistinkers.com
```

### 1. The Layout Branch (`main`)

* Contains only core source code, templates, theme configurations
    (`_config.yml`), linting matrices, and documentation.
* Jekyll compiling is handled *entirely* here inside isolated runners. Raw
    binary packages or Debian metadata indexes are hidden from this branch to
    eliminate source tree clutter.

### 2. The Delivery Staging Ground (`gh-pages`)

* Serves as the active assembly line for the web space.
* Core website templates are generated into flat HTML files on `main` and
    shuttled here via automation using a non-destructive file overlay flag
    (`keep_files: true`).
* External package pipelines securely use this branch to drop newly compiled
    `.deb` packages directly into structural storage pools.

---

## Phase 1: Main Pipeline Security Gates

Every push targeting the `main` branch triggers an isolated multi-job workflow
before any modifications touch live infrastructure.

### Job 1: Automated Quality & Syntax Gate

To keep the logging and debugging pipelines atomic, three specialized syntax
engines validate the branch properties sequentially:

1. **GitHub Workflow Verification:** Uses `raven-actions/actionlint`
    to monitor environment values and ensure pipeline files comply with
    Actions rules.
2. **YAML Compliance Validation:** Uses `ibiqlik/action-yamllint` coupled
    with a root `.yamllint.yml` file to parse variables and structural blocks
    across configurations.
3. **Document Consistency Check:** Uses `davidanson/markdownlint-cli2-action` to
    ensure structural consistency inside markdown files.

### Job 2: Compilation & Delivery Hand Off

Only after Job 1 finishes successfully, Job 2 kicks off on an isolated host
runner to build the layout matching your theme profiles. It drops the output
silently into `gh-pages`, preserving the existing binaries already stored there.

---

## Repository Configuration Files

* `_config.yml`
    The Jekyll static site builder config file.
* `.yamllint.yml`
    Establishes YAML syntax validation rules.
* `.markdownlint-cli2.jsonc`
    Establishes Markdown syntax validation rules.

---

## Next Steps

We are preparing to configure the automated **APT Indexer script** on the
`gh-pages` branch. This upcoming workflow will intercept package pushes,
automatically recalculate structural Debian indices (`Packages.gz` and
`Release`), and stream the finalized outputs live to the global internet via
native GitHub Actions.
