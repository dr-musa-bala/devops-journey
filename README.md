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
```
You are completely right to call that out. If we are building a true production-grade engineering log, our infrastructure-as-code phase needs to match the exact same rigorous level of detail as our container orchestration phase.

Here is the completely overhauled, deep-dive section for your **`README.md`** covering the network scaling and virtual compute deployment. Open your documentation file in VS Code and replace that brief summary with this comprehensive version:

---

## 🌐 Phase 2: Declarative Network Scaling & Virtual Compute (Terraform)

### 🎯 Objective

Scale the local infrastructure blueprint from basic cloud storage arrays to an isolated, multi-tier network topology. This layout provisions a custom Virtual Private Cloud (VPC), configures an accessible public network tier, and deploys a live virtual compute node (EC2) under clean Infrastructure-as-Code (IaC) governance.

---

### 🗺️ Infrastructure Network Topology

```text
 ┌──────────────────────────────────────────────────────────────────┐
 │ LOCAL CLOUD EMULATOR (FLOCI / LOCALSTACK runtime)                │
 │                                                                  │
 │  VPC BOUNDARY: sillypets-dev-vpc (CIDR: 10.0.0.0/16)             │
 │                                                                  │
 │   ┌──────────────────────────────────────────────────────────┐   │
 │   │ PUBLIC SUBNET: sillypets-dev-public-subnet               │   │
 │   │ Routing Grid: 10.0.1.0/24                                │   │
 │   │                                                          │   │
 │   │   ┌──────────────────────────────────────────────────┐   │   │
 │   │   │ VIRTUAL COMPUTE INSTANCE (EC2)                   │   │   │
 │   │   │ Name: sillypets-dev-web-server                   │   │   │
 │   │   │ State: "running" | Size: t3.micro                │   │   │
 │   │   │ Mock Image: ami-12345678                         │   │   │
 │   │   └──────────────────────────────────────────────────┘   │   │
 │   └──────────────────────────────────────────────────────────┘   │
 └──────────────────────────────────────────────────────────────────┘

```

---

### 🧱 Declarative Infrastructure Blueprint (`main.tf`)

```hcl
# 1. Establish Private Isolated Cloud Network Border
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-vpc"
    Environment = var.environment
  }
}

# 2. Segment an Ingress Network Room within the VPC Mesh
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-${var.environment}-public-subnet"
  }
}

# 3. Instantiate a Virtual Server running inside the Segmented Subnet
resource "aws_instance" "web_server" {
  ami           = "ami-12345678" # Mock AMI schema for offline runtime verification
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "${var.project_name}-${var.environment}-web-server"
  }
}

```
---

### 🛑 Troubleshooting Log & Terminal Pager Insights

#### Insight 1: Escaping the Terminal Pager Prison (`less` utility)

* **The Phenomenon:** Running long network description commands like `aws ec2 describe-vpcs` causes the Ubuntu terminal stream to pause, printing an `(END)` marker at the baseline and locking interactive input.
* **The Cause:** The AWS CLI automatically channels extensive JSON payloads through the system default pager interface (`less`) to prevent screen clutter.
* **The Resolution:** Execute the **`q`** keystroke to safely terminate the text-stream reader and immediately recover the standard interactive terminal prompt layout.

#### Insight 2: Provisioning Target Alignment over Cloud Emulation Emulators

* **The Challenge:** Deploying real-world hardware manifests financial billing spikes.
* **The Resolution:** Targeted a local cloud virtualization engine loopback address (`--endpoint-url=http://localhost:4566`), asserting the network map layout accurately populated metadata pools prior to real staging system initialization.

---

### 💻 Verified IaC Execution Sequences

```bash
# Step 1: Execute speculative calculation engine to verify a 5-resource construction plan
dr-musa@DRMUSA:~/devops-journey$ terraform plan

# Step 2: Instantly build out the network array and virtual compute nodes
dr-musa@DRMUSA:~/devops-journey$ terraform apply -auto-approve

# Step 3: Query the cloud engine to parse the custom VPC network configuration
dr-musa@DRMUSA:~/devops-journey$ aws ec2 describe-vpcs --endpoint-url=http://localhost:4566

# Step 4: Confirm active execution state metrics of the virtual EC2 hardware unit
dr-musa@DRMUSA:~/devops-journey$ aws ec2 describe-instances --endpoint-url=http://localhost:4566

# Step 5: Tear down all hardware topologies to maintain a completely clean host workspace
dr-musa@DRMUSA:~/devops-journey$ terraform destroy -auto-approve

```
---

### 🌐 Scaling Infrastructure: VPC Networks & Compute Instances
Successfully expanded the declarative blueprint to stand up an isolated cloud network architecture containing virtual compute nodes.

*   **Network Border Control (VPC):** Provisioned a custom Virtual Private Cloud isolated to the `10.0.0.0/16` routing grid, breaking away from standard cloud defaults.
*   **Subnet Partitioning:** Structured a dedicated Public Subnet (`10.0.1.0/24`) inside the VPC to map public IPs automatically upon server spin-up.
*   **Virtual Compute Engine (EC2):** Provisioned an `aws_instance` node running a mock AMI image (`ami-12345678`) sized to a `t3.micro` instance layout, verified via the AWS CLI v2 as officially `"running"`.

---
## 🐳 Phase 3: Multi-Container Orchestration (Docker Compose)

### 🎯 Objective

Transition from manual, single-container lifecycle management to declarative multi-tier service orchestration. This architecture maps out a highly resilient web-to-database layout, utilizing internal network service discovery and isolated data persistence.

---

### 🗺️ System Topology & Network Architecture

```text
 ┌────────────────────────────────────────────────────────┐
 │ WSL2 / HOST LINUX KERNEL: DOCKER DAEMON MESH            │
 │                                                        │
 │   ┌──────────────────────┐      ┌──────────────────┐   │
 │   │  Frontend Container  │      │ Backend Database │   │
 │   │    (nginx:alpine)    │      │ (postgres:15)    │   │
 │   │  Name: frontend-web  │      │  Name: backend-db│   │
 │   └──────────┬───────────┘      └──────────┬───────┘   │
 │              │                             │           │
 │              ▼                             ▼           │
 │      [sillypets-net] ◄─────────────────────┘           │
 │       (Bridge Driver)                                  │
 │              │                                         │
 └──────────────┼─────────────────────────────────────────┘
                │
         Inbound Request
         Host Port 8082 ──► Container Port 80
                │
                ▼
       (Local Web Browser)

```

---

### 🛑 Troubleshooting Log & Port Virtualization Edge Cases

#### Challenge 1: The Obsolete Top-Level Specification Warning

* **The Error:** `yaml: line 1: top-level attribute "version" is obsolete`
* **The Cause:** Under the modern unified **Compose Specification** used by the core Docker engine (`docker compose`), hardcoding a locked format identifier version (such as `version: '3.8'`) is deprecated. The runtime automatically assumes the newest baseline standard features.
* **The Resolution:** Stripped the `version` configuration line directly from the header of the `docker-compose.yml` block, allowing the native Docker deployment runtime to dynamically parse structural definitions against the latest host engine capabilities.

#### Challenge 2: Ingress Resource Collision with Existing CI/CD Engines (Port 8080)

* **The Error:** `curl -I http://localhost:8080` returned `Server: Jetty / X-Jenkins: 2.541.3 - HTTP 403 Forbidden`.
* **The Cause:** Host port `8080` was pre-allocated and actively bound by a background automated Jenkins continuous integration engine. The inbound request was hijacked by the Jenkins internal Jetty server before reaching the Nginx endpoint.
* **The Resolution:** Brought down the stack via `docker compose down`. Reallocated the external listening assignment within the configuration file from `"8080:80"` to `"8081:80"`.

#### Challenge 3: Secondary Port Locking Discovered (Port 8081)

* **The Error:** Port binding conflicts persisted on host address layer `8081` due to unrecognized secondary system services running background listeners within the local environment.
* **The Resolution:** Dynamically shifted paths up the network index stack, hardcoding the frontend host proxy to port **`8082`** (`"8082:80"`). This isolated the web tier from environment daemons, securing a clean `HTTP 200 OK` handshake response from the Nginx container proxy.

---

### 🛠️ Production-Ready Orchestration Blueprint

```yaml
services:
  # Tier 1: The Relational Database Engine
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

  # Tier 2: The High-Performance Proxy Web Server
  web:
    image: nginx:alpine
    container_name: sillypets-frontend-web
    ports:
      - "8082:80" # Bypassed Jenkins (8080) and blocked assets (8081)
    networks:
      - sillypets-net
    depends_on:
      - db # Enforcement constraint: DB container boots prior to Web layer

volumes:
  pgdata: # Persistent named infrastructure storage block

networks:
  sillypets-net:
    driver: bridge # Provision an isolated local software bridge mesh

```

---

### 💻 Verified Terminal Control Sequences

```bash
# Step 1: Initialize the multi-container stack inside a detached background loop
dr-musa@DRMUSA:~/devops-journey/sillypets-compose$ docker compose up -d

# Step 2: Query active resource states to verify execution health
dr-musa@DRMUSA:~/devops-journey/sillypets-compose$ docker compose ps

# Step 3: Monitor inter-tier log initializations and standard outputs
dr-musa@DRMUSA:~/devops-journey/sillypets-compose$ docker compose logs

# Step 4: Validate clean ingress web mapping avoiding background resource conflicts
dr-musa@DRMUSA:~/devops-journey$ curl -I http://localhost:8082

# Expected Handshake Output:
# HTTP/1.1 200 OK
# Server: nginx/1.31.3
# Connection: keep-alive

# Step 5: Gracefully spin down container tiers while protecting persistent storage volumes
dr-musa@DRMUSA:~/devops-journey/sillypets-compose$ docker compose down

```
---
## 🌉 Phase 4: Automated Container Bootstrapping (The Integration Bridge)

### 🎯 Objective

Bridge Infrastructure-as-Code (IaC) with Configuration Management by completely automating server provisioning. This blueprint eliminates manual post-deployment configurations by leveraging cloud-init bootstrap engines to install runtime dependencies and initialize containerized applications at the moment of server instantiation.

---

### 🗺️ Integration System Layout

```text
 ┌────────────────────────────────────────────────────────┐
 │ TERRAFORM PROVISIONING LAYER                           │
 │                                                        │
 │  [main.tf]                                             │
 │     │                                                  │
 │     ├─► Creates Stateful Firewall (Security Group)     │
 │     │    └─► Ingress: TCP Port 80 (Public World)       │
 │     │                                                  │
 │     └─► Spawns Compute Instance (EC2)                  │
 │          └─► Injects Cloud-Init [user_data] Payload    │
 └──────────────┬─────────────────────────────────────────┘
                │
                ▼ (Server Birth & Boot Execution)
 ┌────────────────────────────────────────────────────────┐
 │ EC2 VIRTUAL COMPUTING NODE RUNTIME                     │
 │                                                        │
 │   1. apt-get update -y                                 │
 │   2. apt-get install docker.io -y                      │
 │   3. systemctl start/enable docker                     │
 │   4. docker run -d -p 80:80 nginx:alpine               │
 └────────────────────────────────────────────────────────┘

```

---

### 🧱 State Tracking & Automation Blueprints (`main.tf`)

```hcl
# 1. State-Enforced Security Group Profile
resource "aws_security_group" "web_firewall" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Allow inbound HTTP web traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Immutable Compute Target Matrix
resource "aws_instance" "web_server" {
  ami                    = "ami-12345678"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_firewall.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install docker.io -y
              systemctl start docker
              systemctl enable docker
              docker run -d --name sillypets-app -p 80:80 nginx:alpine
              EOF
}

```

---

### 🛑 Simulation Layer Nuances & Architectural Truths

* **The Emulation Guard:** When this specific code configuration layout hits live cloud fabrics (AWS), the `user_data` script triggers instantly as a root daemon process, downloading and initializing the live application.
* **The Local Boundary:** Inside local loopback virtualization runtimes, the sandbox successfully parses, stores, and validates the entire metadata block to prove state accuracy, though it refrains from nesting an actual operational inner-docker container stack within the local laptop compute engine.

---

### 💻 Verified CLI Control Assertions

```bash
# Step 1: Push changes to local cloud backend
dr-musa@DRMUSA:~/devops-journey$ terraform apply -auto-approve

# Step 2: Query security group tables to assert ingress validation metrics
dr-musa@DRMUSA:~/devops-journey$ aws ec2 describe-security-groups --endpoint-url=http://localhost:4566

# Step 3: Tear down stack architectures cleanly to save host processor loops
dr-musa@DRMUSA:~/devops-journey$ terraform destroy -auto-approve

```

---

## 🧹 Clean Up the Local Resources

Now that our local cloud emulator state is fully verified, let's wind down the mock hardware infrastructure to keep your machine's resources wide open:

```bash
terraform destroy -auto-approve

```

