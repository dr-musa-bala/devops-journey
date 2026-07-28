
# Phase 7 CI/CD Pipeline Technical Documentation

## 1. Repository Directory Structure

```text
devops-journey/
├── .github/
│   └── workflows/
│       ├── ansible-ci.yml        # Ansible linting, syntax verification & secret testing
│       ├── docker-ci.yml         # Container build, GHA caching & Docker Hub registry delivery
│       ├── smoke-test.yml        # Automated API health & endpoint smoke testing
│       └── terraform-guard.yml   # IaC security & plan validation
├── ansible/
│   └── deploy.yml                # Main Ansible deployment playbook
└── Dockerfile                    # Container build definitions

```

---

## 2. Encrypted Secrets & Environment Matrix

Secrets are configured under **Settings $\rightarrow$ Secrets and variables $\rightarrow$ Actions** at the repository level.

| Secret Name | Value Type | Purpose | Security Control |
| --- | --- | --- | --- |
| `DOCKERHUB_USERNAME` | Plaintext String (`musabalaaudu`) | Docker Hub registry namespace | Automatically masked (`***`) in logs |
| `DOCKERHUB_TOKEN` | Personal Access Token (Read/Write) | Non-interactive registry login | Encrypted via AES-256; masked (`***`) |
| `STAGING_API_KEY` | Sensitive Credential | Staging environment authentication | Injected runtime variable; masked (`***`) |

---

## 3. Workflow Specifications

### Pipeline A: Ansible Syntax & Secret Injection (`ansible-ci.yml`)

* **Triggers:** `push` on `feature/*` and `main`, `pull_request` to `main`, and `workflow_dispatch`.
* **Execution Environment:** `ubuntu-latest`.
* **Key Tasks:** Validates playbook syntax and verifies environment variable masking.

```yaml
name: Phase 7 - Ansible CI Workflow

on:
  push:
    branches: [ "feature/*", "main" ]
  pull_request:
    branches: [ "main" ]
  workflow_dispatch:

env:
  DEPLOY_ENV: "staging"
  ANSIBLE_FORCE_COLOR: "1"

jobs:
  lint-and-test:
    name: Run Ansible Syntax & Secret Check
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository code
        uses: actions/checkout@v4

      - name: Verify Environment & Injected Secret
        env:
          MY_API_KEY: ${{ secrets.STAGING_API_KEY }}
        run: |
          echo "Target Environment: $DEPLOY_ENV"
          echo "Testing secret injection..."
          echo "Secret value length: ${#MY_API_KEY} characters"
          echo "Direct printed secret: $MY_API_KEY"

      - name: Run Ansible syntax check
        run: |
          ansible-playbook ansible/deploy.yml --syntax-check

```

---

### Pipeline B: Docker Build, Layer Caching & Registry Delivery (`docker-ci.yml`)

* **Triggers:** `push` on `main`, `pull_request` to `main`, and `workflow_dispatch`.
* **Execution Environment:** `ubuntu-latest` with Docker Buildx.
* **Key Tasks:**
* Builds multi-stage images.
* Conditional pushing (`push: false` on Pull Requests; `push: true` on merge to `main`).
* Utilizes GitHub Actions Inline Cache (`cache-from/to: type=gha`).
* Tags with `:latest` and `:${{ github.sha }}`.



```yaml
name: Phase 7 - Docker Build and Push CI

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]
  workflow_dispatch:

jobs:
  build-and-push:
    name: Build & Push Docker Image
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build and Push Docker Image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: ./Dockerfile
          push: ${{ github.event_name != 'pull_request' }}
          tags: |
            ${{ secrets.DOCKERHUB_USERNAME }}/devops-journey:latest
            ${{ secrets.DOCKERHUB_USERNAME }}/devops-journey:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

```

---

## 4. Git Strategy & Branch Protection Rules

1. **Branch Protection Enforced:** Direct pushes to `main` are blocked by protected branch hooks (`GH006`).
2. **Feature Branch Workflow:**
* Branch pattern: `feature/<feature-name>`
* Changes are committed locally and pushed to `origin/feature/<feature-name>`.
* Open a Pull Request on GitHub against `main`.


3. **CI Validation Gates:** Pull Requests trigger `ansible-ci.yml` and `docker-ci.yml` (dry-run build without registry push).
4. **Merge Strategy:** Once status checks turn green, merge PR into `main` to trigger registry publishing (`docker.io/musabalaaudu/devops-journey:latest`).

---
That is a clean **`HTTP/1.1 200 OK`** — your end-to-end continuous deployment pipeline is officially functional!

Your setup now automatically handles the full software lifecycle:

1. **CI (GitHub Cloud):** Code push triggers testing, builds the Docker image, and publishes it to Docker Hub.
2. **CD (Local WSL Runner):** The self-hosted service picks up the signal, pulls the latest image, and deploys the container on port `9090` automatically.


```

# DevOps Journey: Automated CI/CD Pipeline Architecture

## Overview
This repository implements an automated Continuous Integration and Continuous Deployment (CI/CD) pipeline using **GitHub Actions**, **Docker Hub**, and a **Local Self-Hosted Runner** operating on WSL (Ubuntu).

---

## Architecture Flow Diagram


```

[ Local Dev / Feature Branch ]
│
▼ (Git Push & PR)
[ GitHub Repository (main) ]
│
├──► 1. CI Stage (GitHub-Hosted Runner)
│      ├── Run linting & unit tests
│      ├── Build Docker image
│      └── Push to Docker Hub (`musabalaaudu/devops-journey:latest`)
│
└──► 2. CD Stage (Local Self-Hosted Runner)
├── GitHub Actions triggers local system daemon (`svc.sh`)
├── Pull latest Docker image from Docker Hub
├── Remove old container (`devops-app`)
└── Spin up container bound to `http://localhost:9090`

---

## Pipeline Specification (`.github/workflows/docker-ci.yml`)

### Job 1: `build-and-push` (Continuous Integration)
* **Runner Environment:** `ubuntu-latest` (GitHub-hosted)
* **Trigger:** Pushes and merged Pull Requests to `main`
* **Key Steps:**
  1. Checkout source code.
  2. Log in to Docker Hub using secrets (`DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`).
  3. Build container image and push tag `latest`.

### Job 2: `deploy` (Continuous Deployment)
* **Runner Environment:** `self-hosted` (Local WSL Instance)
* **Prerequisites:** Depends on successful `build-and-push` completion.
* **Key Steps:**
  1. Pull `musabalaaudu/devops-journey:latest` from Docker Hub.
  2. Stop and remove existing `devops-app` container if present.
  3. Launch container with port mapping `-p 9090:80`.
  4. Verify container process status (`docker ps`).

---

## Local Self-Hosted Runner Configuration

* **Runner Directory:** `~/devops-journey/actions-runner`
* **Service Management Commands:**

```

bash

# Check background runner daemon status

sudo ./svc.sh status

# Start/Stop service

sudo ./svc.sh start
sudo ./svc.sh stop

```

---

## Verification & Health Check

To test the live local deployment directly after a successful pipeline run:


```

bash
curl -I http://localhost:9090

```

Expected Output:

```

http
HTTP/1.1 200 OK
Server: nginx

```