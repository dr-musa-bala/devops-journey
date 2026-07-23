# 📄 Technical Documentation: GHCR Image Retrieval, Container Deployment & Runtime Verification

**Project:** `devops-journey`

**Module:** Module 1 — CI/CD Automation & Artifact Management

**Topic:** Pulling Public Artifacts from GHCR, Local Runtime Execution, and HTTP Layer Verification

---

## 1. Executive Summary

This milestone completes the end-to-end software delivery lifecycle for `devops-journey`. Following the automated build and release of the containerized Nginx application to GitHub Container Registry (`ghcr.io`), the public package was retrieved onto an independent host environment without needing local source code files or build context.

The image was instantiated as an isolated background container on host port `8083` and verified via an in-band HTTP header inspection (`curl -I`).

---

## 2. End-to-End Architectural Pipeline

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                          CI/CD AUTOMATION PIPELINE                      │
│                                                                         │
│ [ Git Push / PR ] ──> [ GitHub Actions Runner ] ──> [ Publish to GHCR ]  │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      GHCR REGISTRY (ghcr.io)                            │
│                                                                         │
│ Package: ghcr.io/dr-musa-bala/my-web-app                                │
│ Tags: latest | 699b91300f99746e766a1ffd8aa31b6285055650                 │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │
                               docker pull
                                     │
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      LOCAL RUNTIME / DEPLOYMENT TARGET                  │
│                                                                         │
│ Host Port 8083  ──> [ Container Bridge ] ──> Container Port 80 (Nginx)  │
│                                                                         │
│ Verification: curl -I http://localhost:8083 ──> 🟢 HTTP 200 OK         │
└─────────────────────────────────────────────────────────────────────────┘

```

---

## 3. Exact Commands Executed & Terminal Output

### Step 1: Pull the Published Artifact from GHCR

```bash
docker pull ghcr.io/dr-musa-bala/my-web-app:latest

```

> **Operation:** Connects to `ghcr.io`, fetches the manifest for tag `latest`, and downloads all associated container layers to the local Docker engine cache.

---

### Step 2: Instantiate Container in Detached Mode

```bash
docker run -d -p 8083:80 --name ghcr-sillypets ghcr.io/dr-musa-bala/my-web-app:latest

```

* `-d`: Runs the container in **detached mode** (background process).
* `-p 8083:80`: Maps host TCP port `8083` to the container's internal Nginx port `80`.
* `--name ghcr-sillypets`: Assigns a clean human-readable name to the running process.

---

### Step 3: Execute Ingress HTTP Header Verification

```bash
curl -I http://localhost:8083

```

### Exact Terminal Response Log:

```http
HTTP/1.1 200 OK
Server: nginx/1.31.3
Date: Thu, 23 Jul 2026 22:19:31 GMT
Content-Type: text/html
Content-Length: 217
Last-Modified: Thu, 23 Jul 2026 22:02:42 GMT
Connection: keep-alive
ETag: "6a628f82-d9"
Accept-Ranges: bytes

```

---

## 4. In-Depth Response Header Analysis

| Header | Returned Value | Technical Meaning & Significance |
| --- | --- | --- |
| **Status Line** | `HTTP/1.1 200 OK` | The HTTP request completed successfully. The web server is active and serving traffic. |
| **`Server`** | `nginx/1.31.3` | Identifies the server engine process running inside the `nginx:alpine` container. |
| **`Content-Type`** | `text/html` | Proves Nginx correctly identified and served the application payload as rendered markup. |
| **`Content-Length`** | `217` | Matches the exact byte payload size of the deployed `index.html` asset. |
| **`ETag`** | `"6a628f82-d9"` | Entity Tag validator used by client browsers and proxies for HTTP caching verification. |

---

## 5. Host Port Allocation Strategy

To avoid runtime collisions with existing system daemons and background containers, host ports were managed as follows:

| Port | Service / Listener | Status |
| --- | --- | --- |
| `8080` | Local Jenkins CI Engine | 🛑 Occupied (Avoided) |
| `8081` | Secondary Host Service | 🛑 Occupied (Avoided) |
| `8082` | Multi-Tier Compose Stack | 🟢 Reserved |
| `8083` | **GHCR Image Integration Test** | 🟢 **Active / Verified (`200 OK`)** |

---

## 6. Summary of Artifact Identifiers

* **Package Registry URI:** `ghcr.io/dr-musa-bala/my-web-app`
* **Latest Release Tag:** `latest`
* **Immutable Commit SHA Tag:** `699b91300f99746e766a1ffd8aa31b6285055650`
* **Visibility:** Public
* **Integrity Status:** Verified Healthy (`200 OK`)
