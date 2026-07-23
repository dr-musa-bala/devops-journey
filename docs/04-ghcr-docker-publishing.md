 **Lesson 4: Publishing Docker Images to GitHub Container Registry (GHCR)**!

Now that your CI pipeline builds and tests your Nginx container, the next production stage is **publishing the container image to a central registry**.

This allows cloud servers, Kubernetes clusters, or deployment tools to pull your image and run it anywhere in the world.

---

## 1. What is a Container Registry?

Think of Git as a repository for **source code**, and a Container Registry as a repository for **compiled Docker images**.

```text
┌─────────────────┐       docker build        ┌────────────────────────┐
│  Source Code    │  ──────────────────────>  │   Docker Image         │
│ (index.html, .tf)│                           │  (Nginx + Web Assets)  │
└─────────────────┘                           └───────────┬────────────┘
                                                          │
                                                     docker push
                                                          │
                                                          ▼
                                              ┌────────────────────────┐
                                              │ Container Registry     │
                                              │ (ghcr.io or DockerHub) │
                                              └────────────────────────┘

```

### Why use GitHub Container Registry (GHCR)?

* **Zero Configuration:** It is built directly into GitHub.
* **No Extra Passwords:** It authenticates automatically using GitHub's built-in `GITHUB_TOKEN` secret.
* **Production Best Practice:** Every build is tagged with the unique Git commit hash (`${{ github.sha }}`), making every release 100% traceable.

---

## Hands-On Exercise: Publish Your Nginx Image

We are going to update `.github/workflows/docker-build.yml` so that whenever code is merged into `main`, GitHub Actions automatically pushes your Nginx image to **GHCR**.

---

### Step 1: Create a Working Branch

In your local terminal (`devops-journey` directory), create a new branch:

```bash
git checkout -b feat/publish-docker-image

```

---

### Step 2: Update `.github/workflows/docker-build.yml`

Open `.github/workflows/docker-build.yml` and replace its entire content with this production-ready workflow:

```yaml
name: Docker Image Build & Test

on:
  push:
    branches: [ "main", "feat/*" ]
  pull_request:
    branches: [ "main" ]

# Grants permission to publish packages to GitHub Container Registry
permissions:
  contents: read
  packages: write

jobs:
  build-and-test-container:
    runs-on: ubuntu-latest

    steps:
      - name: Step 1 - Download Repository Code
        uses: actions/checkout@v4

      - name: Step 2 - Verify Docker Engine
        run: |
          docker --version

      - name: Step 3 - Build Nginx Web Server Image
        run: |
          echo "Building Nginx container image tagged with commit SHA and latest..."
          docker build \
            -t ghcr.io/${{ github.repository_owner }}/my-web-app:${{ github.sha }} \
            -t ghcr.io/${{ github.repository_owner }}/my-web-app:latest .

      - name: Step 4 - Boot Web Container & Test HTTP Response
        run: |
          echo "Starting Nginx container in background on port 8080..."
          docker run -d -p 8080:80 --name test-web-server ghcr.io/${{ github.repository_owner }}/my-web-app:latest
          
          sleep 2
          
          echo "Sending HTTP request to test web server:"
          curl -I http://localhost:8080

      - name: Step 5 - Log in to GitHub Container Registry
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Step 6 - Push Image to GHCR
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: |
          echo "Publishing container image to ghcr.io..."
          docker push ghcr.io/${{ github.repository_owner }}/my-web-app:${{ github.sha }}
          docker push ghcr.io/${{ github.repository_owner }}/my-web-app:latest

```

---

## 🔍 Key New Concepts in This Workflow

| Concept | Explanation |
| --- | --- |
| `permissions: packages: write` | Authorizes the runner's `GITHUB_TOKEN` to publish images to GitHub Packages/GHCR. |
| `${{ github.sha }}` | The unique 40-character Git commit hash. Tagging images with this ensures you never overwrite previous image versions. |
| `if: github.ref == 'refs/heads/main' ...` | **Deployment Guard:** Tests run on feature branches, but image publishing **only** happens when code is merged into `main`. |
| `docker/login-action@v3` | Pre-built action that securely authenticates Docker CLI with `ghcr.io`. |

---

### Step 3: Stage, Commit, and Push

Run these commands in your terminal:

```bash
# 1. Stage the workflow update
git add .github/workflows/docker-build.yml

# 2. Commit changes
git commit -m "ci: update docker-build workflow to publish image to GHCR on main merge"

# 3. Push branch to GitHub
git push -u origin feat/publish-docker-image

```

---

### Step 4: Merge PR to Trigger Image Publish

1. Go to **GitHub.com** $\rightarrow$ **Pull Requests** $\rightarrow$ Open PR for `feat/publish-docker-image`.
2. Notice that Steps 1–4 run (Build & Test), but Steps 5–6 are skipped because this is a feature branch PR.
3. Click **Merge pull request** $\rightarrow$ **Confirm merge**.
4. Go to the **Actions** tab on `main`. The pipeline will execute again on `main`, run Steps 5 and 6, and push your container image to `ghcr.io`!
5. On your main repository page on GitHub, look at the right sidebar under **Packages**—you will see `my-web-app` published live!

---

## 🛠️ Step-by-Step Guide: Sync Local Terminal & Push Detailed Documentation

Now let's sync your local `main` branch, create the technical documentation for GHCR publishing, and push it to GitHub.

### Step 1: Sync Local Main & Create Docs Branch

```bash
# 1. Checkout main and pull latest merged code
git checkout main
git pull origin main

# 2. Create documentation branch
git checkout -b docs/add-ghcr-publishing-doc

# 3. Create the markdown file
touch docs/04-ghcr-docker-publishing.md

```

---

### Step 2: Add Content to `docs/04-ghcr-docker-publishing.md`

Open `docs/04-ghcr-docker-publishing.md` and paste the following detailed documentation:

```markdown
# 📄 Technical Documentation: Publishing Container Images to GitHub Container Registry (GHCR)

**Project:** `devops-journey`  
**Module:** Module 1 — CI/CD Automation & Artifact Management  
**Topic:** Container Registry Authentication & Image Release Automation  

---

## 1. Executive Summary

This document details the configuration of automated Docker image publishing to GitHub Container Registry (`ghcr.io`) using GitHub Actions. 

Image builds are tested across all branches, but artifact publishing is restricted exclusively to merged commits on the `main` branch using GitHub conditional checks.

---

## 2. Key Accomplishments

1. **GHCR Authorization:** Configured workflow-level permissions (`packages: write`) to allow the runner's ephemeral `GITHUB_TOKEN` to push registry artifacts.
2. **Immutable Image Tagging:** Implemented dual-tagging using both immutable Git commit SHA (`${{ github.sha }}`) and the mutable release tag (`latest`).
3. **Conditional Release Gating:** Applied condition `if: github.ref == 'refs/heads/main' && github.event_name == 'push'` to prevent unreviewed feature branch code from releasing to the package registry.
4. **Registry Authentication:** Integrated `docker/login-action@v3` for secure zero-credential authentication against `ghcr.io`.

---

## 3. Pipeline Workflow Logic

```text
[ Developer Branch Push ] ──> [ Build & Integration Test (curl 200 OK) ] ──> 🛑 Skip Push
                                                                               │
[ Merge PR to main ]      ──> [ Build & Integration Test ] ──> [ Auth GHCR ] ──> 🚀 Push ghcr.io

```

---

## 4. Commands & Configuration Reference

### Permissions Configuration

```yaml
permissions:
  contents: read
  packages: write

```

### Docker Tagging Syntax

```bash
docker build \
  -t ghcr.io/${{ github.repository_owner }}/my-web-app:${{ github.sha }} \
  -t ghcr.io/${{ github.repository_owner }}/my-web-app:latest .

```

### Registry Push Commands

```bash
docker push ghcr.io/${{ github.repository_owner }}/my-web-app:${{ github.sha }}
docker push ghcr.io/${{ github.repository_owner }}/my-web-app:latest

```

---

## 5. Verification

* Verified package availability under the repository's **Packages** tab on GitHub.
* Confirmed image layers are accessible for deployment using standard docker pull commands:
`docker pull ghcr.io/<owner>/my-web-app:latest`

```

