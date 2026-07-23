# 📄 Technical Documentation: CI/CD Pipeline Foundation

**Project:** `devops-journey`

**Module:** Module 1 — CI/CD Automation

**Technology Stack:** Git, GitHub Actions, Ubuntu Linux Runners, YAML

---

## 1. Executive Summary

You have successfully implemented, tested, and merged a production-grade Continuous Integration (CI) pipeline using **GitHub Actions**.

The pipeline automatically triggers on code pushes and Pull Requests, provisions an isolated cloud virtual machine, inspects the runtime environment, and validates repository health before allowing code to be merged into the `main` branch.

---

## 2. Key Milestones Achieved

### A. Repository & Directory Architecture

* Established the standard directory structure required by GitHub Actions: `.github/workflows/`.
* Created a clean declarative workflow file: `smoke-test.yml`.

### B. Automated Pipeline Event Triggers

* Configured workflow filters to monitor two primary Git events:
1. `push` events on `main` and feature branches (`feat/*`).
2. `pull_request` events targeting `main`.



### C. Isolated Cloud Runner Provisioning

* Delegated build tasks to GitHub-hosted virtual machines (`ubuntu-latest`).
* Utilized official GitHub Marketplace actions (`actions/checkout@v4`) to automatically pull repository source code into the fresh cloud workspace.

### D. System Diagnostics & Quality Gates

* Implemented pre-flight health checks to output OS details (`uname -a`), current working directory (`pwd`), and file trees (`ls -la`).
* Verified software environment capabilities by checking pre-installed tools (`python3 --version`).

### E. Error Handling & Exit Code Testing

* Intentionally injected a failing step (`non_existent_command_test`) to observe pipeline failure behavior.
* Confirmed that non-zero Linux exit codes (`127`) instantly halt pipeline execution and block unsafe code merges.
* Successfully resolved the error and restored the build to a **Green (Passing)** state.

### F. Complete Git & Merge Lifecycle

* Worked on an isolated feature branch (`feat/first-github-action`).
* Opened a Pull Request on GitHub.com and verified that CI status checks ran automatically.
* Completed the Pull Request merge into `main` and synchronized local terminal code via `git pull origin main`.

---

## 3. Workflow Architecture & Execution Flow

```text
  [ Developer Push / PR ]
             │
             ▼
┌───────────────────────────┐
│  GitHub Event Listener    │  Matches filter: main or feat/*
└────────────┬──────────────┘
             │
             ▼
┌───────────────────────────┐
│ Provision Ubuntu Cloud VM │  runs-on: ubuntu-latest
└────────────┬──────────────┘
             │
             ▼
┌───────────────────────────┐
│  1. Checkout Code         │  uses: actions/checkout@v4
│  2. Check OS & Directory  │  run: uname -a && pwd
│  3. Verify Workspace      │  run: ls -la
│  4. Check Python Runtime  │  run: python3 --version
└────────────┬──────────────┘
             │
      Exit Code == 0 ?
      ├── YES ──> 🟢 Pipeline PASSES  ──> PR Ready to Merge
      └── NO  ───> 🔴 Pipeline FAILS   ──> PR Merge Blocked

```

---

## 4. Final Code Reference (`.github/workflows/smoke-test.yml`)

```yaml
name: Sanity & Smoke Test

on:
  push:
    branches: [ "main", "feat/*" ]
  pull_request:
    branches: [ "main" ]

jobs:
  smoke-test-job:
    runs-on: ubuntu-latest

    steps:
      - name: Step 1 - Download Repository Code
        uses: actions/checkout@v4

      - name: Step 2 - Check Runner System Info
        run: |
          echo "=========================================="
          echo "Running on OS: $(uname -a)"
          echo "Current Directory: $(pwd)"
          echo "=========================================="

      - name: Step 3 - Verify Repository Files
        run: |
          echo "Listing all files in repository:"
          ls -la

      - name: Step 4 - Verify Python Installation
        run: |
          echo "Checking if Python 3 is available on the runner:"
          python3 --version

```

---

## 5. Core Concepts Mastered

| Concept | Definition | Practical Application |
| --- | --- | --- |
| **CI (Continuous Integration)** | Automating code testing and building. | Every push triggers tests automatically before human review. |
| **Runner** | Ephemeral VM hosted by GitHub. | Provides a clean, isolated `ubuntu-latest` OS for every job. |
| **Exit Code `0` vs `>0**` | Standard Linux program output signals. | `0` = Success (Green check); Non-zero = Error (Red X, halts pipeline). |
| **5-Step Skeleton** | `name` $\rightarrow$ `on` $\rightarrow$ `jobs` $\rightarrow$ `runs-on` $\rightarrow$ `steps`. | The fundamental structure for all GitHub Actions workflows. |

---

## 6. Current Repository State
* **Active Branch:** `main`
* **Local & Remote Sync:** Up to date with `origin/main`
* **Working Tree:** Clean
* **CI Status:** Active and passing on all future pushes to `main` and `feat/*`

---
