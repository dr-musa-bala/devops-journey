# 🚀 Automated CI/CD Container Pipeline with Local AWS Emulation

This repository features a fully automated, multi-job continuous integration pipeline using GitHub Actions. To eliminate cloud provider costs, reduce pipeline latency, and test with 100% environment fidelity, the workflow utilizes **Floci** (`floci.io`) — a high-performance, open-source local AWS cloud emulator.

The pipeline runs two decoupled operations sequentially:
1. **Infrastructure Compliance (Job 1):** Verifies syntax correctness, linting, and structural formatting of all Terraform workspace files.
2. **Application Containerization (Job 2):** Dynamically provisions an ephemeral local AWS ECR service, builds our application Docker image, and offloads it safely into the emulator's data plane registry.

---

## 🏗️ Pipeline Architecture

```mermaid
graph TD
    subgraph GitHub Cloud Runner Environment [Ubuntu Host Runner]
        A[Git Push / Main Branch] --> B(Job 1: Validate Infrastructure)
        B -->|Passes Compliance| C(Job 2: Build Application)
        
        subgraph Floci Emulator Service Container
            D[Universal Control Plane API<br>Port 4566]
            E[OCI Container Registry Data Plane<br>Port 5100]
        end
        
        C -->|1. Mounts Socket| F[Host Docker Engine /var/run/docker.sock]
        F -->|2. Spawns Backend Registry| E
        
        C -->|3. CLI API Initialization| D
        C -->|4. Docker Buildx Layer Compile| G[Docker BuildKit Engine]
        G -->|5. HTTP Non-TLS Push Blobs| E
    end

```

---

## 🕵️‍♂️ Engineering Journey & Troubleshooting Log

During the development of this container pipeline, we encountered and solved four sequential systems-level integration hurdles. Below is the historical engineering log detailing our diagnostics and resolutions:

### 1. The Cloud Environment Disconnect

* **The Symptom:** The initial execution threw an immediate authentication failure during the credential handshake:
```text
Error: The security token included in the request is invalid.

```


* **The Root Cause:** The workflow was attempting to use official AWS credential actions (`aws-actions/configure-aws-credentials`). These actions reached out to live, production AWS authentication endpoints, which immediately rejected our local mock authentication variables (`test`/`test`). Furthermore, the runner could not see the `localhost` emulator running on the local laptop.
* **The Resolution:** We modified the runner architecture to host its own isolated local cloud. We declared Floci natively as a GitHub **Service Container** directly inside the remote pipeline runner environment.

### 2. Docker-out-of-Docker (DooD) Socket Isolation

* **The Symptom:** When running the repository creation step, the pipeline crashed with a raw internal failure:
```text
Error: An error occurred (InternalFailure) when calling the CreateRepository operation... 
Failed to start ECR backing registry container: java.net.SocketException: No such file or directory

```


* **The Root Cause:** Floci maintains strict protocol fidelity. When `aws ecr create-repository` is executed, it actively spins up an actual, secondary OCI-compliant registry container inside Docker to store image blobs. Because the emulator was isolated inside its own service container wrapper, it could not find or communicate with the host container runtime to spawn this backend child process.
* **The Resolution:** We passed explicit host mounting arguments using the `options` metadata directive, mapping the host's primary Docker communication socket directly into the container filesystem:
```yaml
options: -v /var/run/docker.sock:/var/run/docker.sock

```



### 3. Transport Layer Security (TLS) Enforcement

* **The Symptom:** The compiler successfully built our image layers but crashed instantly at the initialization of the transmission pipeline:
```text
failed to push localhost:4566/sillypets-app:latest: ... http: server gave HTTP response to HTTPS client

```


* **The Root Cause:** Modern container build backends (`Buildx` and `BuildKit`) are highly protective by default. They strictly assume every target remote container registry is secured by TLS encryption (`https://`). Because our emulator sandbox works as a local testing environment, it processes data transfers over plain text HTTP. The build engine rejected the unencrypted channel.
* **The Resolution:** We added an inline driver configuration directly into our Buildx instantiation step, whitelisting our target loopback domain as an insecure plain text channel:
```yaml
config-inline: |
  [registry."localhost:5100"]
    http = true
    insecure = true

```



### 4. Control Plane vs. Data Plane Multi-Tenancy Routing

* **The Symptom:** Even with security parameters lowered, pushes to port `4566` were consistently dropped by an unexpected cloud storage error:
```text
400 Bad Request: <?xml version="1.0" encoding="UTF-8"?><Error><Code>InvalidArgument</Code><Message>POST requires either ?uploads, ?uploadId...</Message>

```


* **The Root Cause:** Floci splits its architecture between an administrative **Control Plane (Port 4566)** and a stateful **Data Plane (Port 5100)**. Port `4566` acts as a universal traffic cop listening for AWS CLI structural commands. When we forced heavy, raw Docker image blobs into port `4566`, the control plane router failed to match it to an ECR schema and fell back to its default S3 bucket handler, causing an XML payload collision.
* **The Resolution:** We split our data routing. We directed the AWS CLI to create the repository registry structure over the control gateway (`http://localhost:4566`), but configured Buildx and our container tag signatures to offload heavy container layer streams directly to the data plane endpoint on port **`5100`**.

---

## 📦 Verified Pipeline Configuration

The fully resolved, green-verified `.github/workflows/terraform-guard.yml` layout can be reviewed directly in our codebase. It runs independently of real AWS credentials, ensures zero data drift, and verifies our container logic end-to-end within runtime memory boundaries.
