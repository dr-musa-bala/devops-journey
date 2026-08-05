# Kubernetes Deep Dive: Architecture, Deployment, & Service Management

A comprehensive technical documentation log for container orchestration using Kubernetes (`minikube` & `kubectl`) for the `sillypets` microservice application.

---

## 1. Kubernetes Core Architecture & Mental Model

Kubernetes operates on a Master/Worker model dividing control logic from container execution workloads.

### Component Layer Breakdown

| Component | Layer | Role & Analogy | Technical Description |
| :--- | :--- | :--- | :--- |
| **`kube-apiserver`** | Control Plane | **The Front Desk** | Exposes the Kubernetes API (REST). Serves as the central entry point for all operational requests (`kubectl`, CI/CD pipelines). Validates and configures data for pod, service, and deployment objects. |
| **`etcd`** | Control Plane | **The Secret Notebook** | Consistent, highly-available key-value store. Holds the complete state and configuration database of the cluster. Every state change is written here. |
| **`kube-scheduler`** | Control Plane | **The Matchmaker** | Evaluates unassigned Pods and selects optimal Worker Nodes for them based on resource availability (CPU/Memory requirements), constraints, and affinity specs. |
| **`kube-controller-manager`** | Control Plane | **The Safety Inspector** | Runs continuous background control loops (Node controller, ReplicaSet controller, ServiceAccount controller). Constantly enforces that the actual state matches the target desired state. |
| **`kubelet`** | Worker Node | **The Floor Supervisor** | An agent that runs on every node in the cluster. Receives PodSpecs from `kube-apiserver` and ensures containers described in those specs are running and healthy via the container runtime (Docker/Containerd). |
| **`kube-proxy`** | Worker Node | **The Traffic Guard** | Network proxy running on each node. Maintains network rules (IPVS/iptables) allowing network communication to Pods from inside or outside the cluster. |

---

## 2. Environment Setup & Troubleshooting Log

### Installation Steps (`kubectl` & `minikube`)
1. **`kubectl` CLI:** Downloaded stable release binary, granted execution privileges (`chmod +x`), and installed to `/usr/local/bin/kubectl`.
2. **`minikube`:** Installed Minikube local engine driver for single-node cluster emulation.

### Issue Resolution: Connection Refused on `localhost:8443`
* **Symptom:** During initial startup (`minikube start --driver=docker`), `kube-apiserver` returned API connection refused errors while attempting to apply storageclass addons.
* **Root Cause:** Stale state files from previous incomplete cluster creations caused a race condition where Minikube attempted addon configuration before `kube-apiserver` finished initialization.
* **Resolution:** 
  ```bash
  minikube delete
  minikube start --driver=driver
  ```

---

## 3. Phase 1: Standalone Pod Deployment

Pods are the smallest deployable units in Kubernetes. A Pod wraps one or more containers, sharing storage, network IP, and runtime options.

### `k8s/pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sillypets-pod
  labels:
    app: sillypets
spec:
  containers:
  - name: sillypets-container
    image: musabalaaudu/sillypets:latest
    ports:
    - containerPort: 80
```

### Operational Commands & Debugging
* **Apply Manifest:** `kubectl apply -f k8s/pod.yaml`
* **Inspect Status:** `kubectl get pods`
* **Port-Forwarding & Conflict Resolution:**
  ```bash
  # Forward cluster port 80 to host port 8085 (resolving port 8080 collision)
  kubectl port-forward sillypets-pod 8085:80
  ```
* **Key Limitation:** Standalone Pods are ephemeral. If a Pod dies or its host fails, Kubernetes will not automatically recreate it.

---

## 4. Phase 2: Self-Healing Deployment Setup

Deployments provide declarative updates for Pods and ReplicaSets, enabling auto-scaling, rolling updates, and self-healing resilience.

### `k8s/deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sillypets-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: sillypets
  template:
    metadata:
      labels:
        app: sillypets
    spec:
      containers:
      - name: sillypets-container
        image: musabalaaudu/sillypets:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
```

### Handling `ErrImagePull` / `ImagePullBackOff` Timeouts
* **Symptom:** Pod status transitioned to `ImagePullBackOff` during pod recreation.
* **Root Cause:** Default `imagePullPolicy: Always` forced Kubernetes to contact Docker Hub remote registry on every pod creation, triggering connection timeouts.
* **Fix Strategy:**
  1. Cached local Docker image into Minikube container runtime environment:
     ```bash
     minikube image load musabalaaudu/sillypets:latest
     ```
  2. Set `imagePullPolicy: IfNotPresent` in `deployment.yaml` to prioritize local cache.

### Self-Healing Verification Test
1. Target active pod: `kubectl delete pod sillypets-deployment-5db957bb6-md4qd`
2. Result: ReplicaSet controller detected 2/3 running pods, immediately initiated a new replacement pod (`sillypets-deployment-5db957bb6-d7jwk`) reaching `Running` state within 8 seconds.

---

## 5. Phase 3: Traffic Exposure with NodePort Service

Services abstract access to Pods. Because Pod IPs are volatile, a Service provides a stable endpoint and distributes incoming traffic across all matching pod replicas.

### `k8s/service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: sillypets-service
spec:
  type: NodePort
  selector:
    app: sillypets
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

### Accessing the Application
```bash
# Expose Service URL through Minikube tunnel
minikube service sillypets-service
```

---

## 6. Commands Quick Reference

| Action | Command |
| :--- | :--- |
| **Check Cluster Health** | `kubectl get nodes` |
| **Apply All Manifests** | `kubectl apply -f k8s/` |
| **View Resources** | `kubectl get pods,deployments,services` |
| **Inspect Pod Details** | `kubectl describe pod <pod-name>` |
| **View Container Logs** | `kubectl logs <pod-name>` |
| **Load Image into Minikube** | `minikube image load <image-name>:<tag>` |
| **Access Service** | `minikube service sillypets-service` |