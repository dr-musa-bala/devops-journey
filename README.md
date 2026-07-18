# 🚀 My DevOps & Cloud Journey

Welcome to my comprehensive engineering log! This repository tracks my hands-on transition into Cloud and DevOps architecture.

---

## ☁️ Phase 1: AWS Core Services
I have successfully mastered the foundational AWS Core Services:
* **EC2:** Virtual compute instances for running applications.
* **S3:** Scalable object storage for files and assets.
* **IAM:** Identity and access management policies for secure cloud infrastructure.
* **VPC:** Isolated virtual networks to safeguard cloud resources.
* **CloudWatch:** Infrastructure monitoring and centralized logging.
* **Lambda:** Serverless, event-driven compute functions.
* **RDS:** Managed relational database deployments.
* **ECS/ECR:** Container orchestration and Docker image registries.

---

## 🐳 Phase 2: Docker & Containerization

I built and containerized a static web application (**SillyPets**) to eliminate the classic *"works on my machine"* dilemma by packaging application runtime environments.

### 🛠️ Project Files

#### 1. `index.html` (The Application)
```html
<!DOCTYPE html>
<html>
<head>
    <title>SillyPets App</title>
    <style>
        body { font-family: sans-serif; text-align: center; background-color: #f0f8ff; padding-top: 50px; }
        h1 { color: #ff6b6b; }
    </style>
</head>
<body>
    <h1>🐱 Welcome to SillyPets! 🕶️</h1>
    <p>This page is running safely inside a magic Docker container!</p>
</body>
</html>

```

#### 2. `Dockerfile` (The Container Blueprint)

```dockerfile
# Step 1: Grab a pre-made kitchen from the internet
FROM nginx:alpine

# Step 2: Put our webpage (the sandwich) into the kitchen's serving tray
COPY index.html /usr/share/nginx/html/index.html

# Step 3: Tell the kitchen to open its doors to the public
EXPOSE 80

```

---

### 🛑 Challenges Encountered & Solutions

Real engineering happens during troubleshooting. Here is how I navigated the blockers encountered during this project:

#### 1. Git Dubious Ownership Error

* **The Blocker:** Running Git commands across the Windows-to-WSL local filesystem triggered a `惹fatal: detected dubious ownership` security block.
* **The Fix:** Configured a global exception rule inside the Linux environment to recognize the working directory safely:
```bash
git config --global --add safe.directory '*'

```

#### 2. Missing Docker Daemon Connection

* **The Blocker:** Executing `docker build` threw an error stating it could not connect to the Docker daemon.
* **The Fix:** Opened Docker Desktop on the host machine and verified that the specialized **WSL 2 Integration** toggle was fully activated for my specific Ubuntu distribution.

#### 3. Source Metadata Resolution Failure (Typo)

* **The Blocker:** The build failed with `docker.io/library/nginx:alphine: not found`.
* **The Fix:** Diagnosed a syntax error in the base image tag. Corrected the spelling from `alphine` to `alpine` in the `Dockerfile` and re-baked the image.

#### 4. Host Network Port Collision (Jenkins)

* **The Blocker:** Attempting to bind the container to host port `8080` failed because a local **Jenkins** CI/CD instance was already listening on that port.
* **The Fix:** Gracefully dismantled the conflicting container and refactored the port mapping to route traffic through an open channel on port `8081`:
```bash
docker rm -f sillypets-container
docker run -d -p 8081:80 --name sillypets-container sillypets-image

```

### 🖼️ Project Evolution & Visual Evidence

A key part of engineering is documenting the iteration loop. Below is the visual progression of identifying, debugging, and solving the text-encoding challenge:

#### ❌ 1. The Emoji Encoding Bug (Before)
*The baseline deployment encountered a classic "Mojibake" character transformation issue. The Nginx server was rendering raw text without explicitly instructing the client browser to interpret modern UTF-8 emoji characters.*

<img src="https://github.com/dr-musa-bala/devops-journey/raw/main/sillypets-bug.png" alt="SillyPets Bug Deployment" width="700">

#### 🐳 2. The UTF-8 Hot Swap Resolution (After)
*The resolution: Successfully injected a `<meta charset="UTF-8">` tag into the application's layout header, re-baked the Docker image payload, and hot-swapped the isolated container instance to port 8081.*

<img src="https://github.com/dr-musa-bala/devops-journey/raw/main/sillypets-fixed.png" alt="SillyPets Fixed Deployment" width="700">
```

### ☁️ Cloud Distribution & Container Registry (Docker Hub)

To transition the application from a localized development environment to a globally accessible cloud footprint, the containerized image was published to **Docker Hub** (an enterprise-grade public container registry). This ensures the application blueprint is immutable, versioned, and deployable on any cloud infrastructure worldwide.

#### 1. Authentication & Local Handshake
Established a secure CLI session from the local Ubuntu instance to the remote container registry registry:
```bash
docker login

```

#### 2. Image Tagging & Semantic Versioning

Abstracted the local build target (`sillypets-image`) into a globally unique registry path using an explicit repository namespace and a `V1.0` release tag to prevent configuration drift:

```bash
# Syntax: docker tag local-image username/repository:tag
docker tag sillypets-image musabalaaudu/sillypets-image:V1.0

```

#### 3. Image Push & Registry Uplink

Transferred the locally baked image layers up to the central cloud storage repository:

```bash
docker push musabalaaudu/sillypets-image:V1.0

```

#### 🌐 Global Verification & Execution

The application can now be fetched from the internet and instantiated on any Docker-enabled target machine with a single, highly optimized runtime instruction—bypassing the need for local source code duplication entirely:

```bash
docker run -d -p 8081:80 --name cloud-sillypets musabalaaudu/sillypets-image:V1.0
```

## 🪵 Phase 2, Week 1: Infrastructure as Code (IaC) with Terraform & Floci

### 🎯 Objective

Transition from manual container deployments to declarative Infrastructure as Code (IaC). To eliminate cloud billing risks, a lightweight, offline GraalVM-compiled AWS emulator (**Floci.io**) was integrated to mock AWS services locally on port `4566`.

---

### 🛑 Troubleshooting Log & Architecture Challenges

#### Challenge 1: The WSL Systemd / Snap Package Trap

* **The Error:** When executing `terraform`, Ubuntu suggested installing via `sudo snap install terraform`.
* **The Cause:** Snaps require a fully operational `systemd` daemon running in the background. In WSL environments, this frequently triggers dependency and connection failures.
* **The Resolution:** Bypassed the snap engine entirely. Registered HashiCorp’s official GPG security keys and appended their upstream native APT repository directly to `/etc/apt/sources.list.d/hashicorp.list` for a native Debian installation.

#### Challenge 2: S3 Virtual-Hosted-Style Routing Failure

* **The Error:** `dial tcp: lookup sillypets-dev-storage-bucket.localhost on 8.8.8.8:53: no such host`
* **The Cause:** By default, the AWS provider attempts to communicate with S3 using *virtual-hosted-style* addressing (appending the bucket name as a subdomain prefix: `[http://bucket.localhost:4566](http://bucket.localhost:4566)`). Because the environment was offline, internal WSL lookups leaked to public DNS (`8.8.8.8`), which cannot resolve local mock subdomains.
* **The Resolution:** Patched the `provider "aws"` block by explicitly setting `s3_use_path_style = true`. This forced Terraform to target the host directly and append the bucket as a sub-path (`http://localhost:4566/bucket`), keeping all traffic strictly localized.

#### Challenge 3: Obsolete Upstream AWS CLI Packages

* **The Error:** `E: Package 'awscli' has no installation candidate`
* **The Cause:** Standard Ubuntu APT distributions are phasing out legacy AWS CLI v1 packages, leaving no native package candidates available on newer versions.
* **The Resolution:** Installed the enterprise-grade AWS CLI v2 bundle manually. Pulled the raw linux-x86_64 zip archive directly from Amazon's servers using `curl`, extracted it with `unzip`, and executed the native binary `./aws/install` script.

#### Challenge 4: Immutable Structural Naming Drift

* **The Error:** `Plan: 1 to add, 0 to change, 1 to destroy.`
* **The Cause:** Refactoring hardcoded resource values into a decoupled configuration (`variables.tf`) inadvertently modified the literal string of the secondary profile bucket. Because cloud provider S3 bucket names are immutable (cannot be modified in-place), Terraform flagged a destructive re-creation.
* **The Resolution:** Leveraged Floci's sandbox isolation to execute `terraform apply -auto-approve` safely without data-loss consequences, successfully standardizing naming conventions to `${var.project_name}-${var.environment}-*` before executing a final workspace teardown via `terraform destroy`.

---

### 🛠️ Verified Configuration Blueprints

```hcl
# main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  access_key                  = "mock_key"
  secret_key                  = "mock_secret"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true # Critical local routing patch

  endpoints {
    s3  = "http://localhost:4566"
    ec2 = "http://localhost:4566"
    iam = "http://localhost:4566"
  }
}

resource "aws_s3_bucket" "local_bucket" {
  bucket = "${var.project_name}-${var.environment}-storage-bucket"
}

resource "aws_s3_bucket" "profile_pictures" {
  bucket = "${var.project_name}-${var.environment}-user-profiles"
}
