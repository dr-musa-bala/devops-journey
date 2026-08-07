# Module 12: Automated Helm CI/CD Pipelines with GitHub Actions

## Overview

This module documents the implementation of an automated Continuous Integration and Continuous Delivery (CI/CD) pipeline for Helm charts using **GitHub Actions**.

The pipeline automates chart linting, syntax validation, dry-run template rendering, and chart packaging on every `push` or `pull_request` to target branches.

---

## 1. Pipeline Architecture

```text
  ┌─────────────────────────────────────────────────────────┐
  │                 Developer Git Push / PR                 │
  └────────────────────────────┬────────────────────────────┘
                               │
                               ▼
  ┌─────────────────────────────────────────────────────────┐
  │               GitHub Actions Runner Engine              │
  ├─────────────────────────────────────────────────────────┤
  │ 1. Checkout Code         (actions/checkout@v4)          │
  │ 2. Install Helm CLI      (azure/setup-helm@v4)          │
  │ 3. Helm Lint             (helm lint sillypets-chart/)   │
  │ 4. Dry-Run Template Test (helm template --debug)        │
  │ 5. Package Chart         (helm package)                 │
  │ 6. Upload Artifact       (actions/upload-artifact@v4)   │
  └─────────────────────────────────────────────────────────┘

```

---

## 2. Directory & Workflow Structure

```text
devops-journey/
├── .github/
│   └── workflows/
│       └── helm-ci.yaml         # GitHub Actions Workflow Manifest
├── sillypets-chart/             # Source Helm Chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── MODULE-11-HELM.md            # Module 11 Documentation
└── MODULE-12-HELM-CICD.md       # Module 12 Documentation (This File)

```

---

## 3. Workflow Manifest (`.github/workflows/helm-ci.yaml`)

```yaml
name: Helm CI/CD Pipeline

on:
  push:
    branches: [ "main", "module-11-helm", "module-12-cicd" ]
  pull_request:
    branches: [ "main" ]

jobs:
  lint-and-package:
    name: Lint, Test, and Package Helm Chart
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Set up Helm
        uses: azure/setup-helm@v4
        with:
          version: 'latest'

      - name: Helm Lint Check
        run: |
          echo "==> Running helm lint..."
          helm lint sillypets-chart/

      - name: Dry-Run Template Test
        run: |
          echo "==> Testing template rendering..."
          helm template test-release sillypets-chart/ --debug

      - name: Package Helm Chart
        run: |
          echo "==> Packaging Helm chart..."
          helm package sillypets-chart/ --destination ./dist

      - name: Upload Chart Artifact
        uses: actions/upload-artifact@v4
        with:
          name: sillypets-helm-chart
          path: ./dist/*.tgz

```

---

## 4. Pipeline Jobs & Step Analysis

| Action / Step | Command / Uses | Technical Function |
| --- | --- | --- |
| **Checkout Code** | `actions/checkout@v4` | Fetches the latest repository commit into the GitHub runner workspace. |
| **Setup Helm** | `azure/setup-helm@v4` | Downloads and installs the specified `helm` binary on the runner path. |
| **Helm Lint** | `helm lint sillypets-chart/` | Analyzes `Chart.yaml`, `values.yaml`, and templates for structural and syntax errors. |
| **Dry-Run Test** | `helm template test-release ... --debug` | Evaluates Go template logic (`{{ .Values... }}`) and ensures valid K8s YAML output without contacting a live cluster. |
| **Package Chart** | `helm package ... --destination ./dist` | Bundles the chart directory into a versioned `.tgz` compressed release artifact inside `./dist`. |
| **Upload Artifact** | `actions/upload-artifact@v4` | Persists the generated `.tgz` package to the GitHub run summary for direct downloading. |

---

## 5. Implementation Steps

1. **Create the Documentation File:** Saves MODULE-12-HELM-CICD.md to repository root.
Run this command from your terminal to generate `~/devops-journey/MODULE-12-HELM-CICD.md`:

```bash
cat <<'EOF' > ~/devops-journey/MODULE-12-HELM-CICD.md
# Module 12: Automated Helm CI/CD Pipelines with GitHub Actions

## Overview
This module documents the implementation of an automated Continuous Integration and Continuous Delivery (CI/CD) pipeline for Helm charts using **GitHub Actions**. 

The pipeline automates chart linting, syntax validation, dry-run template rendering, and chart packaging on every `push` or `pull_request` to target branches.

---

## 1. Pipeline Architecture


```

text
┌─────────────────────────────────────────────────────────┐
│                 Developer Git Push / PR                 │
└────────────────────────────┬────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────┐
│               GitHub Actions Runner Engine              │
├─────────────────────────────────────────────────────────┤
│ 1. Checkout Code         (actions/checkout@v4)          │
│ 2. Install Helm CLI      (azure/setup-helm@v4)          │
│ 3. Helm Lint             (helm lint sillypets-chart/)   │
│ 4. Dry-Run Template Test (helm template --debug)        │
│ 5. Package Chart         (helm package)                 │
│ 6. Upload Artifact       (actions/upload-artifact@v4)   │
└─────────────────────────────────────────────────────────┘

```

---

## 2. Directory Structure


```

text
devops-journey/
├── .github/
│   └── workflows/
│       └── helm-ci.yaml
├── sillypets-chart/
├── MODULE-11-HELM.md
└── MODULE-12-HELM-CICD.md

```

---

## 3. Workflow Manifest (`.github/workflows/helm-ci.yaml`)


```

yaml
name: Helm CI/CD Pipeline

on:
push:
branches: [ "main", "module-11-helm" ]
pull_request:
branches: [ "main" ]

jobs:
lint-and-package:
name: Lint, Test, and Package Helm Chart
runs-on: ubuntu-latest

```
steps:
  - name: Checkout Code
    uses: actions/checkout@v4

  - name: Set up Helm
    uses: azure/setup-helm@v4
    with:
      version: 'latest'

  - name: Helm Lint Check
    run: |
      echo "==> Running helm lint..."
      helm lint sillypets-chart/

  - name: Dry-Run Template Test
    run: |
      echo "==> Testing template rendering..."
      helm template test-release sillypets-chart/ --debug

  - name: Package Helm Chart
    run: |
      echo "==> Packaging Helm chart..."
      helm package sillypets-chart/ --destination ./dist

  - name: Upload Chart Artifact
    uses: actions/upload-artifact@v4
    with:
      name: sillypets-helm-chart
      path: ./dist/*.tgz

```

```

---

## 4. Key Takeaways

1. **Shift-Left Quality Control:** Catching syntax errors and malformed YAML via `helm lint` before code reaches production or live environments.
2. **Automated Artifact Generation:** Eliminating manual `helm package` commands by generating versioned `.tgz` releases automatically in CI.
3. **Template Validation:** Testing placeholder evaluation (`helm template`) dynamically in ephemeral GitHub runners.
EOF

```


2. **Stage and Commit Files:** Stages new workflow and documentation files.
Navigate to the root directory and stage all changes:

```bash
cd ~/devops-journey
git add .github/workflows/helm-ci.yaml MODULE-12-HELM-CICD.md
git commit -m "docs(helm): add module 12 cicd documentation and workflow"

```


3. **Push to GitHub:** Pushes commit to GitHub remote repository.
Push your committed changes to trigger the pipeline on GitHub:

```bash
git push origin module-11-helm

```

*(Replace `module-11-helm` with `main` if pushing directly to your main branch.)*


4. **Verify Run Status:** Checks GitHub Actions tab for execution.
Navigate to your repository on GitHub:

1. Click the **Actions** tab.
2. Select **Helm CI/CD Pipeline**.
3. Confirm that the run finishes with a green checkmark and check the **Artifacts** section at the bottom of the summary page to verify `sillypets-helm-chart` is downloadable.


---

## 6. Key Takeaways & Best Practices

1. **Shift-Left Quality Control:** Catching syntax errors and malformed YAML via `helm lint` before code reaches production or live environments.
2. **Automated Artifact Generation:** Eliminating manual `helm package` commands by generating versioned `.tgz` releases automatically in CI.
3. **Template Validation:** Testing placeholder evaluation (`helm template`) dynamically in ephemeral GitHub runners.
