# SillyPets CI/CD Pipeline Documentation

This document provides complete technical documentation for the **SillyPets Automated CI/CD Pipeline**, covering system architecture, troubleshooting histories, pipeline stage breakdowns, and setup instructions.

---

## 1. Pipeline Overview & Architecture

The pipeline automates the complete continuous integration workflow for the **SillyPets** microservice: downloading source code, building a container image, running a transient container inside the Docker engine, executing automated health checks, and cleaning up test resources.

```
 [GitHub Repo] ──> (Stage 1: Fetch) ──> (Stage 2: Build Image) ──> (Stage 3: Run & Test) ──> [Cleanup]
                                                                          │
                                                                   curl http://test-sillypets

```

### Core Architecture Components

| Component | Function | Configuration / Context |
| --- | --- | --- |
| **Jenkins Controller** | Pipeline execution engine | Runs in Docker on a custom user-defined network |
| **Docker Engine** | Container runtime & build engine | Shared via Docker socket (`/var/run/docker.sock`) |
| **SillyPets App** | Target web application | Built from Dockerfile, exposed on standard web port |
| **Test Container** | Transient test environment | Spin up $\rightarrow$ Test via `curl` $\rightarrow$ Tear down |

---

## 2. Challenges Encountered & Navigation Steps

Building a containerized CI/CD pipeline inside a Docker-in-Docker / Docker-out-of-Docker environment introduces specific networking and lifecycle edge cases. Below are the sequential challenges faced during development and how each was navigated.

### Challenge 1: Connection Timeout During `curl` Health Check

* **Symptom:** The build stalled at Stage 3 for several minutes before failing with `curl: (7) Failed to connect to 172.17.0.x port 80: Connection timed out`.
* **Root Cause:** Network isolation between Docker networks. Jenkins was executing inside a custom user-defined bridge network (e.g., `sillypets-net`), while standard `docker run` launched `test-sillypets` onto the default `bridge` network (`172.17.0.0/16`). Containers on different Docker networks cannot communicate without explicit routing.
* **Navigation:**
1. Inspected Jenkins' environment to verify network mode.
2. Extracted the active network dynamically using `docker inspect` against the Jenkins container's hostname:
`JENKINS_NET=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' $(hostname))`
3. Appended `--network "${JENKINS_NET}"` to the `docker run` command in the pipeline script, joining both containers to the exact same virtual network.



---

### Challenge 2: Brittle IP Address Scraping & DNS Resolution

* **Symptom:** Relying on extracting dynamic container IP addresses via `docker inspect` was fragile, complex, and prone to breaking across host environments.
* **Root Cause:** Standard default `bridge` networks do not support container-name-based DNS lookup, forcing reliance on raw IP addresses.
* **Navigation:**
1. Recognized that custom Docker networks feature an **embedded DNS server** (`127.0.0.11`).
2. Updated the test step to leverage Docker DNS directly: `curl -f "http://test-sillypets"`.
3. Added fallback conditional logic so the pipeline stays portable even if executed on standard default bridge networks.



---

### Challenge 3: Container Name Conflicts on Aborted Builds

* **Symptom:** Re-running a failed pipeline caused instant crashes with the error: `docker: Error response from daemon: Conflict. The container name "/test-sillypets" is already in use`.
* **Root Cause:** When an inline test failed, the shell script exited immediately, skipping manual cleanup commands placed at the end of the `sh` step.
* **Navigation:**
1. Extracted container teardown commands out of the `stages` block entirely.
2. Placed cleanup routines inside the declarative Jenkins `post { always { ... } }` lifecycle hook.
3. Added fallback shell flags (`|| true`) to `docker stop` and `docker rm` to ensure non-zero exit codes during cleanup never fail a build:
```groovy
post {
    always {
        sh "docker stop test-sillypets || true"
        sh "docker rm test-sillypets || true"
    }
}

```





---

## 3. Production Jenkinsfile Code

```groovy
pipeline {
    agent any

    environment {
        IMAGE_NAME = 'musabalaaudu/sillypets-image:V1.0'
        GIT_REPO   = 'https://github.com/dr-musa-bala/devops-journey.git'
    }

    stages {
        stage('1. Fetch Code from GitHub') {
            steps {
                echo "--> Pulling latest source code and Dockerfile..."
                git branch: 'main', url: "${GIT_REPO}"
            }
        }

        stage('2. Bake the App (Build)') {
            steps {
                echo "--> Building Docker image: ${IMAGE_NAME}..."
                sh "docker build -t ${IMAGE_NAME} ."
            }
        }

        stage('3. Taste Test (Test)') {
            steps {
                echo "--> Setting up dynamic container testing..."
                sh '''
                    # Navigated Issue #1: Detect current network context dynamically
                    JENKINS_NET=$(docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' $(hostname) 2>/dev/null || echo "bridge")
                    echo "Active Network Context: ${JENKINS_NET}"

                    # Navigated Issue #1 & #2: Attach test container to shared network
                    docker run -d --name test-sillypets --network "${JENKINS_NET}" ${IMAGE_NAME}
                    sleep 3

                    # Navigated Issue #2: Health Check via Embedded DNS or IP fallback
                    if [ "${JENKINS_NET}" != "bridge" ]; then
                        echo "Testing via Docker DNS (http://test-sillypets)..."
                        curl -f "http://test-sillypets" || exit 1
                    else
                        echo "Testing via direct IP fallback..."
                        CONTAINER_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' test-sillypets)
                        curl -f "http://${CONTAINER_IP}" || exit 1
                    fi
                '''
            }
        }
    }

    post {
        always {
            # Navigated Issue #3: Safe lifecycle teardown
            echo "--> Cleaning up test container artifacts..."
            sh "docker stop test-sillypets || true"
            sh "docker rm test-sillypets || true"
        }
        success {
            echo "🎉 YAY! The app was built and tested successfully!"
        }
        failure {
            echo "❌ Build failed. Check execution logs above."
        }
    }
}

```

---

## 4. Stage Breakdown Summary

* **Stage 1 (Fetch Code):** Checks out code from GitHub branch `main`.
* **Stage 2 (Bake/Build):** Builds and tags the local Docker image (`musabalaaudu/sillypets-image:V1.0`).
* **Stage 3 (Taste Test):** Detects container network, launches transient container, and runs `curl -f` endpoint verification.
* **Post Actions:** Guaranteed execution of container shutdown and removal regardless of stage outcomes.

---

## 5. Deployment Setup

1. **Update Jenkins Script:**
1. Open Jenkins (`http://localhost:8081`).
2. Go to **`sillypets-ci`** $\rightarrow$ **Configure**.
3. Replace the existing pipeline script with the code above.
4. Click **Save**.


2. **Execute & Verify:**
1. Click **Build Now**.
2. Open **Console Output** to verify automatic network detection and successful HTTP status testing.


---
