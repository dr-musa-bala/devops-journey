# Phase 8: Lightweight Uptime Monitoring & Observability

## 1. Overview & Architecture

Before expanding into heavy observability stacks (Prometheus/Grafana), Phase 8 focuses on establishing an **active, continuous out-of-band monitoring layer** using **Uptime Kuma**.

### CI/CD Smoke Check vs. Continuous Monitoring
* **CI/CD Smoke Check:** Runs once during pipeline execution for ~30 seconds to block broken code deployments.
* **Continuous Monitoring (Uptime Kuma):** Runs 24/7/365 in an independent container environment. It pings application endpoints at regular intervals (every 20 seconds) to catch post-deployment runtime failures (memory leaks, database drops, server crashes) and measure response latency over time.

---

## 2. Infrastructure Setup (Standalone Container)

Uptime Kuma was deployed as a standalone Docker container with persistent storage to maintain configuration across restarts.

```bash
docker run -d \
  --restart=always \
  -p 3001:3001 \
  --add-host=host.docker.internal:host-gateway \
  -v uptime-kuma:/app/data \
  --name uptime-kuma \
  louislam/uptime-kuma:1

```

### Key Parameters:

* `-p 3001:3001`: Exposes Uptime Kuma web dashboard on host port `3001`.
* `-v uptime-kuma:/app/data`: Named Docker volume ensuring SQLite database and configuration settings persist.
* `--add-host=host.docker.internal:host-gateway`: Maps host gateway for cross-container networking on Linux environments.

---

## 3. Incident & Error Troubleshooting Ledger

During initial configuration, several connectivity and deployment issues were encountered. Below is the complete diagnostic and resolution log.

### ❌ Issue 1: `getaddrinfo ENOTFOUND host.docker.internal`

* **Symptom:** Uptime Kuma status displayed `DOWN` with error `getaddrinfo ENOTFOUND host.docker.internal`.
* **Root Cause:** Unlike Docker Desktop (macOS/Windows), native Docker on Linux does not resolve `host.docker.internal` out-of-the-box.
* **Resolution:** Re-created the container passing the `--add-host=host.docker.internal:host-gateway` flag. Alternatively, routed traffic directly via the Linux Docker bridge IP (`172.17.0.1`).

---

### ❌ Issue 2: `curl: (7) Failed to connect to localhost port 8000`

* **Symptom:** `curl http://localhost:8000` returned a connection refusal error.
* **Root Cause:** The application container (`sillypets-app`) was not actively running on the host machine; previous CI/CD checks ran on ephemeral GitHub Action runners.
* **Resolution:** Spun up the target container locally to listen on host port `8000`.

---

### ❌ Issue 3: `Unable to find image 'sillypets-app:latest' locally`

* **Symptom:** `docker run -d --name sillypets-app -p 8000:8080 sillypets-app:latest` failed because Docker attempted to pull from Docker Hub.
* **Root Cause:** Local image tag mismatch.
* **Diagnostic Step:** Inspected local images using `docker images`.
* **Discovered Local Image:** `musabalaaudu/sillypets-image:V1.0`.
* **Resolution:** Executed container using exact repository name and version tag:
```bash
docker run -d --name sillypets-app -p 8000:80 musabalaaudu/sillypets-image:V1.0

```



---

### ❌ Issue 4: Monitor Remained RED After Container Launch

* **Symptom:** `sillypets-app` container was running (`Up`), but Uptime Kuma still reported `DOWN`.
* **Diagnostic Step:** Verified local host health endpoint:
```bash
curl -I http://localhost:8000

```


**Output:** `HTTP/1.1 200 OK` (Server: Nginx, Port mapping `0.0.0.0:8000->80/tcp`).
* **Root Cause:** Uptime Kuma inside its container network could not reach `host.docker.internal:8000` due to host routing restrictions.
* **Resolution:** Updated monitor endpoint URL in Uptime Kuma settings to target the Linux Docker bridge gateway IP directly:
```text
[http://172.17.0.1:8000/](http://172.17.0.1:8000/)

```



---

## 4. Verification & Current Status

* **Application Endpoint:** `http://localhost:8000` (`HTTP 200 OK`)
* **Monitoring Dashboard:** `http://localhost:3001`
* **Target Monitored URL:** `http://172.17.0.1:8000/`
* **Heartbeat Interval:** 20 Seconds
* **Operational Status:** **UP (GREEN 🟢)**

---

## 5. Next Planned Actions

1. Trigger simulated outage (`docker stop sillypets-app`) to verify Discord alert delivery.
2. Convert standalone CLI configurations into a multi-container `docker-compose.yml` file.

```
