
# 📄 Technical Documentation: Automated Nginx Docker CI Pipeline

**Project:** `devops-journey`  
**Module:** Module 1 — CI/CD Automation  
**Topic:** Containerizing & Testing Web Servers in GitHub Actions  

## Overview
Automated packaging and integration testing for an Nginx web application. Every commit automatically builds an `nginx:alpine` container with custom `index.html` assets and validates live HTTP response headers (`200 OK`) inside the runner workspace.

## Workflow Execution Summary
1. **Checkout:** Cloned repository source code containing `index.html` and `Dockerfile`.
2. **Build:** Executed `docker build -t my-web-app:latest .`
3. **Integration Test:** 
   * Instantiated container in detached mode (`-d`) mapping port `8080:80`.
   * Executed `curl -I http://localhost:8080` inside the cloud VM.
   * Confirmed HTTP `200 OK` exit status.
