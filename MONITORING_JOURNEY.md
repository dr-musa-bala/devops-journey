# 6. Phase 8.2: Infrastructure as Code (IaC) with Docker Compose

### 1. Architectural Evolution

To eliminate manual container management and hardcoded IP routing (`172.17.0.1`), the entire observability and application stack was refactored into a declarative **3-Tier Docker Compose Architecture**.

| Layer | Container / Service Name | Port Mapping | Purpose |
| :--- | :--- | :--- | :--- |
| **Tier 1 (Database)** | `sillypets-backend-db` (`db`) | Internal | PostgreSQL 15 relational storage |
| **Tier 2 (Web App)** | `sillypets-frontend-web` (`web`) | `8082:80` | Frontend Nginx application server |
| **Tier 3 (Observability)**| `uptime-kuma` | `3001:3001` | Out-of-band monitoring & alerting watchdog |

---
### 2. Service Discovery vs. IP Hacks

* **Old Method (Standalone CLI):** Uptime Kuma had to target the host bridge IP (`http://172.17.0.1:8000/`) because containers on the default Docker bridge cannot resolve each other by container name.
* **New Method (Docker Compose):** All three services sit on a user-defined bridge network (`sillypets-net`). Docker’s embedded DNS engine automatically resolves service names. Uptime Kuma now monitors:
  ```text
  http://web:80/

### 3. Complete Declarative Stack (`docker-compose.yml`)

```yaml
services:
  # Tier 1: The Relational Database System
  db:
    image: postgres:15-alpine
    container_name: sillypets-backend-db
    environment:
      POSTGRES_USER: musa_admin
      POSTGRES_PASSWORD: SuperSecurePassword123
      POSTGRES_DB: sillypets_records
    volumes:
      - pgdata:/var/lib/postgresql/data
    networks:
      - sillypets-net

  # Tier 2: The Front-End Web Application
  web:
    image: musabalaaudu/sillypets-image:V1.0
    container_name: sillypets-frontend-web
    ports:
      - "8082:80"
    networks:
      - sillypets-net
    depends_on:
      - db # Ensures database launches prior to web layer

  # Tier 3: Continuous Monitoring Watchdog
  uptime-kuma:
    image: louislam/uptime-kuma:1
    container_name: uptime-kuma
    restart: always
    ports:
      - "3001:3001"
    volumes:
      - uptime-kuma-data:/app/data
    networks:
      - sillypets-net

# Permanent disk storage across container restarts
volumes:
  pgdata:
  uptime-kuma-data:

# Private network mesh connecting all tiers
networks:
  sillypets-net:
    driver: bridge

```

### 4. Incident & Troubleshooting Ledger (Compose Phase)

#### ❌ Issue 1: Uptime Kuma Prompted to Create Account Again After `docker compose up`

* **Symptom:** Opening `http://localhost:3001` displayed the initial setup screen instead of the existing login page.
* **Root Cause:** Volume naming mismatch. The standalone CLI used volume name `uptime-kuma`, whereas Docker Compose automatically scoped the volume as `<project_folder>_uptime-kuma-data` (`devops-journey_uptime-kuma-data`). Since the volume was brand new, Uptime Kuma initialized an empty SQLite database.
* **Resolution:** Re-initialized the admin account and recreated the HTTP monitor targeting internal DNS (`http://web:80/`). *(Alternative fix: Map external volume using `external: true` in Compose).*

---

### 5. Verification Commands & Operational State

```bash
# Spin up all 3 tiers in background mode
docker compose up -d

# Verify container operational state
docker compose ps

```

* **Application Status:** `http://localhost:8082` (`HTTP 200 OK`)
* **Uptime Kuma Dashboard:** `http://localhost:3001`
* **Target Monitored Endpoint:** `http://web:80/`
* **Internal Resolution:** `sillypets-net` bridge mesh
* **Operational Health:** **UP (GREEN 🟢)**
```

## 7. Phase 8.3: Simulated Outage & Alert Verification

### 1. Incident Simulation Objective
Verify the full end-to-end observability and alerting pipeline under synthetic failure conditions using the multi-container Docker Compose architecture on `sillypets-net`.

---

### 2. Test Execution Timeline & Results

| Step / Action | Command / Trigger | Internal System Behavior | Dashboard & Alert Status |
| :--- | :--- | :--- | :--- |
| **1. Normal Baseline** | `docker compose up -d` | `sillypets-backend-db`, `sillypets-frontend-web`, and `uptime-kuma` running smoothly. | **UP (GREEN 🟢)** |
| **2. Trigger Outage** | `docker compose stop web` | The `web` container stops. Uptime Kuma's heartbeat ping to `http://web:80/` fails (`ECONNREFUSED`). | **DOWN (RED 🔴)** |
| **3. Discord Notification** | Automatic Webhook | Uptime Kuma fires an instant HTTP POST payload to Discord. | **ALERT DELIVERED 🚨** |
| **4. Trigger Recovery** | `docker compose start web` | The `web` container boots up. The next heartbeat ping returns `HTTP 200 OK`. | **RECOVERED (GREEN 🟢)** |
| **5. Discord Recovery** | Automatic Webhook | Uptime Kuma fires a resolution payload confirming service restoration. | **RESOLVED ALERT SENT 🟢** |

---

### 3. Alert Payloads Captured

* **Down Alert Received:**
  > 🔴 **[DOWN] Sillypets App**  
  > **Target:** `http://web:80/`  
  > **Error:** `connect ECONNREFUSED`  

* **Recovery Alert Received:**
  > 🟢 **[UP] Sillypets App**  
  > **Target:** `http://web:80/`  
  > **Ping:** `~2ms`  

---

### 4. Critical Technical Lessons Learned

1. **Embedded DNS Healing:** If container alias resolution fails across bridge networks, cycling the stack with `docker compose down && docker compose up -d` forces Docker's internal DNS resolver (`127.0.0.11`) to re-index all service endpoints on `sillypets-net`.
2. **Watchdog Health:** A monitoring tool can only alert if it is alive. Setting `restart: always` on the `uptime-kuma` service ensures the watchdog automatically recovers if the host reboots or crashes.
3. **Threshold Tuning:** Configuring a `20-second` heartbeat interval and `1` max retry count gives near-instant incident response without overwhelming alert channels with noise.

### 📸 Visual Verification & Proof

#### 1. Uptime Kuma Status Dashboard
| Outage State (Red) | Recovery State (Green) |
| :---: | :---: |
![Uptime Kuma Down](./images/kuma_down.png) | ![Uptime Kuma Up](./images/kuma_up.png) |

#### 2. Discord Real-Time Alert Delivery
![Discord Outage and Recovery Notifications](./images/discord_alert.png)
