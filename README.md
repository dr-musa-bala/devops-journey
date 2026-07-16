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

### 🖼️ Project Evolution & Visual Evidence

A key part of engineering is documenting the iteration loop. Below is the visual progression of identifying, debugging, and solving the text-encoding challenge:

#### ❌ 1. The Emoji Encoding Bug (Before)
*The baseline deployment encountered a classic "Mojibake" character transformation issue. The Nginx server was rendering raw text without explicitly instructing the client browser to interpret modern UTF-8 emoji characters.*

<img src="https://github.com/dr-musa-bala/devops-journey/raw/main/sillypets-bug.png" alt="SillyPets Bug Deployment" width="700">

#### 🐳 2. The UTF-8 Hot Swap Resolution (After)
*The resolution: Successfully injected a `<meta charset="UTF-8">` tag into the application's layout header, re-baked the Docker image payload, and hot-swapped the isolated container instance to port 8081.*

<img src="https://github.com/dr-musa-bala/devops-journey/raw/main/sillypets-fixed.png" alt="SillyPets Fixed Deployment" width="700">