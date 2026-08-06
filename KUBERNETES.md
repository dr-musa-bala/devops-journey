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
# Module 10: Kubernetes Environment Configuration (ConfigMaps & Secrets)

A technical reference guide detailing dynamic configuration management, data decoupling, Base64 secret handling, and container environment injection in Kubernetes using `ConfigMap` and `Secret` resources.

---

## 1. Architectural Overview & Configuration Philosophy

Decoupling environment configuration from application source code and container images is a core principle of cloud-native application design (Factor III of the Twelve-Factor App methodology). Hardcoding configuration parameters or credentials into Docker images forces image rebuilds whenever settings change and risks leaking sensitive data.

Kubernetes provides two specialized API objects to manage externalized runtime configuration:

### ConfigMap vs. Secret Comparison

| Feature / Metric | ConfigMap (`kind: ConfigMap`) | Secret (`kind: Secret`) |
| --- | --- | --- |
| **Primary Purpose** | Stores non-sensitive configuration data (UI themes, domain endpoints, feature flags). | Stores sensitive, confidential data (API keys, database passwords, TLS certificates). |
| **Storage Format** | Plain text string key-value pairs. | Base64-encoded binary/string values stored in `etcd`. |
| **Default Encoding** | Unencoded UTF-8 text. | Base64 (`c2lsbHk...`) to safely handle binary data and prevent accidental plain-text exposure. |
| **Memory Isolation** | Standard API access controls. | Mounted via `tmpfs` (RAM-backed filesystem) when injected as volumes, preventing writes to host disk. |
| **Access Control** | Standard RBAC rules. | RBAC restrictable per namespace; can be further secured using Encryption at Rest in `etcd`. |

---

## 2. Manifest Specifications

### 2.1 Non-Sensitive Configuration (`k8s/configmap.yaml`)

The `ConfigMap` holds public settings used by the frontend or backend application services.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: sillypets-config
  namespace: default
  labels:
    app.kubernetes.io/name: sillypets
    app.kubernetes.io/part-of: devops-journey
data:
  APP_TITLE: "Silly Pets Gallery"
  APP_COLOR: "coral"

```

* **`apiVersion: v1`**: Belongs to the core Kubernetes API group.
* **`data`**: Key-value pairs containing non-sensitive application settings.

---

### 2.2 Sensitive Credentials Configuration (`k8s/secret.yaml`)

The `Secret` resource stores confidential runtime parameters. Using the `stringData` field allows you to write plain-text values in the manifest file; Kubernetes automatically converts these into Base64-encoded strings when creating the resource in `etcd`.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: sillypets-secret
  namespace: default
  labels:
    app.kubernetes.io/name: sillypets
    app.kubernetes.io/part-of: devops-journey
type: Opaque
stringData:
  API_KEY: "silly-secret-key-998877"
  DB_PASSWORD: "PetPassword2026!"

```

* **`type: Opaque`**: The default secret type for arbitrary user-defined key-value data.
* **`stringData`**: Write-only field accepting plain-text values, converted to Base64 in the cluster state.

---

## 3. Integrating ConfigMaps & Secrets into Deployments

To expose configuration parameters to running containers, update `k8s/deployment.yaml`. Using `envFrom` imports all keys from targeted `ConfigMap` and `Secret` manifests directly into the container's environment variables.

### Complete Manifest (`k8s/deployment.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sillypets-deployment
  namespace: default
  labels:
    app: sillypets
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
        envFrom:
        - configMapRef:
            name: sillypets-config
        - secretRef:
            name: sillypets-secret

```

### Alternative: Individual Variable Mapping (`valueFrom`)

If you prefer to map specific individual keys rather than importing all keys via `envFrom`, use `valueFrom`:

```yaml
env:
  - name: APP_TITLE
    valueFrom:
      configMapKeyRef:
        name: sillypets-config
        key: APP_TITLE
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: sillypets-secret
        key: DB_PASSWORD

```

---

## 4. Execution & Verification Workflow Log

### Step 1: Apply Resources to Cluster

Apply all manifests inside the `k8s/` directory in a single command:

```bash
kubectl apply -f k8s/

```

**Output:**

```text
configmap/sillypets-config created
deployment.apps/sillypets-deployment configured
secret/sillypets-secret created
service/sillypets-service unchanged

```

---

### Step 2: Verify Pod Execution Status

List running pods to ensure zero initialization or image pull errors occurred:

```bash
kubectl get pods -l app=sillypets

```

**Output:**

```text
NAME                                    READY   STATUS    RESTARTS   AGE
sillypets-deployment-765849586c-89kh9   1/1     Running   0          16s
sillypets-deployment-765849586c-cj66c   1/1     Running   0          8s
sillypets-deployment-765849586c-xgnmr   1/1     Running   0          9s

```

---

### Step 3: Inspect Injected Runtime Environment Variables

Execute into one of the active container instances and verify that environment variables from both the `ConfigMap` and `Secret` are loaded:

```bash
kubectl exec -it sillypets-deployment-765849586c-89kh9 -- env | grep -E "APP_|API_|DB_"

```

**Output:**

```text
APP_COLOR=coral
APP_TITLE=Silly Pets Gallery
API_KEY=silly-secret-key-998877
DB_PASSWORD=PetPassword2026!

```

---

### Step 4: Examine Base64 Secret Obfuscation in `etcd`

View how Kubernetes converts plain-text `stringData` into Base64 within the cluster state:

```bash
kubectl get secret sillypets-secret -o yaml

```

**Output:**

```yaml
apiVersion: v1
data:
  API_KEY: c2lsbHktc2VjcmV0LWtleS05OTg4Nzc=
  DB_PASSWORD: UGV0UGFzc3dvcmQyMDI2IQ==
kind: Secret
metadata:
  name: sillypets-secret
  namespace: default
type: Opaque

```

---

### Step 5: Programmatic Base64 Secret Decoding

Extract and decode Base64 data directly using `kubectl` and the `base64` utility:

```bash
kubectl get secret sillypets-secret -o jsonpath="{.data.DB_PASSWORD}" | base64 --decode

```

**Output:**

```text
PetPassword2026!

```

---

## 5. Advanced Injection Patterns: Volume Mounts

While environment variables are easy to set up, they remain static for the lifetime of a container. If a `ConfigMap` is updated, containers using environment variables **will not** reflect the change until the Pod is restarted.

Mounting a `ConfigMap` or `Secret` as a **Volume** projects configuration keys as files inside the container directory. Kubernetes automatically updates mounted files in near real-time when the underlying `ConfigMap` or `Secret` changes.

### Manifest Example: Volume Mounting

```yaml
spec:
  containers:
  - name: sillypets-container
    image: musabalaaudu/sillypets:latest
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
      readOnly: true
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: config-volume
    configMap:
      name: sillypets-config
  - name: secret-volume
    secret:
      secretName: sillypets-secret

```

**Resulting Container File Layout:**

* `/etc/config/APP_TITLE` contains `"Silly Pets Gallery"`
* `/etc/config/APP_COLOR` contains `"coral"`
* `/etc/secrets/API_KEY` contains `"silly-secret-key-998877"`
* `/etc/secrets/DB_PASSWORD` contains `"PetPassword2026!"`

---

## 6. Production Security & Best Practices

1. **Base64 is NOT Encryption:** Base64 encoding is purely a structural format, not security. Anyone with read access to the cluster namespace can decode secrets.
2. **Enable Encryption at Rest:** Configure Kubernetes API server to encrypt `etcd` secrets at rest using AWS KMS, Azure Key Vault, or GCP KMS.
3. **RBAC Isolation:** Restrict access to `Secret` resources using Role-Based Access Control (`RBAC`) so developers or non-admin service accounts cannot read sensitive data.
4. **GitOps Secret Hygiene:** Never commit raw `secret.yaml` files with plain-text credentials to Git repositories. Use secret management solutions like **HashiCorp Vault**, **Bitnami SealedSecrets**, or **SOPS** (Secrets OPerationS) to encrypt secrets before committing to source control.
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

# Module 10: Kubernetes Environment Configuration (ConfigMaps & Secrets)

A technical reference guide detailing dynamic configuration management, data decoupling, Base64 secret handling, and container environment injection in Kubernetes using `ConfigMap` and `Secret` resources.

---

## 1. Architectural Overview & Configuration Philosophy

Decoupling environment configuration from application source code and container images is a core principle of cloud-native application design (Factor III of the Twelve-Factor App methodology). Hardcoding configuration parameters or credentials into Docker images forces image rebuilds whenever settings change and risks leaking sensitive data.

Kubernetes provides two specialized API objects to manage externalized runtime configuration:

### ConfigMap vs. Secret Comparison

| Feature / Metric | ConfigMap (`kind: ConfigMap`) | Secret (`kind: Secret`) |
| --- | --- | --- |
| **Primary Purpose** | Stores non-sensitive configuration data (UI themes, domain endpoints, feature flags). | Stores sensitive, confidential data (API keys, database passwords, TLS certificates). |
| **Storage Format** | Plain text string key-value pairs. | Base64-encoded binary/string values stored in `etcd`. |
| **Default Encoding** | Unencoded UTF-8 text. | Base64 (`c2lsbHk...`) to safely handle binary data and prevent accidental plain-text exposure. |
| **Memory Isolation** | Standard API access controls. | Mounted via `tmpfs` (RAM-backed filesystem) when injected as volumes, preventing writes to host disk. |
| **Access Control** | Standard RBAC rules. | RBAC restrictable per namespace; can be further secured using Encryption at Rest in `etcd`. |

---

## 2. Manifest Specifications

### 2.1 Non-Sensitive Configuration (`k8s/configmap.yaml`)

The `ConfigMap` holds public settings used by the frontend or backend application services.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: sillypets-config
  namespace: default
  labels:
    app.kubernetes.io/name: sillypets
    app.kubernetes.io/part-of: devops-journey
data:
  APP_TITLE: "Silly Pets Gallery"
  APP_COLOR: "coral"

```

* **`apiVersion: v1`**: Belongs to the core Kubernetes API group.
* **`data`**: Key-value pairs containing non-sensitive application settings.

---

### 2.2 Sensitive Credentials Configuration (`k8s/secret.yaml`)

The `Secret` resource stores confidential runtime parameters. Using the `stringData` field allows you to write plain-text values in the manifest file; Kubernetes automatically converts these into Base64-encoded strings when creating the resource in `etcd`.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: sillypets-secret
  namespace: default
  labels:
    app.kubernetes.io/name: sillypets
    app.kubernetes.io/part-of: devops-journey
type: Opaque
stringData:
  API_KEY: "silly-secret-key-998877"
  DB_PASSWORD: "PetPassword2026!"

```

* **`type: Opaque`**: The default secret type for arbitrary user-defined key-value data.
* **`stringData`**: Write-only field accepting plain-text values, converted to Base64 in the cluster state.

---

## 3. Integrating ConfigMaps & Secrets into Deployments

To expose configuration parameters to running containers, update `k8s/deployment.yaml`. Using `envFrom` imports all keys from targeted `ConfigMap` and `Secret` manifests directly into the container's environment variables.

### Complete Manifest (`k8s/deployment.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sillypets-deployment
  namespace: default
  labels:
    app: sillypets
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
        envFrom:
        - configMapRef:
            name: sillypets-config
        - secretRef:
            name: sillypets-secret

```

### Alternative: Individual Variable Mapping (`valueFrom`)

If you prefer to map specific individual keys rather than importing all keys via `envFrom`, use `valueFrom`:

```yaml
env:
  - name: APP_TITLE
    valueFrom:
      configMapKeyRef:
        name: sillypets-config
        key: APP_TITLE
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: sillypets-secret
        key: DB_PASSWORD

```

---

## 4. Execution & Verification Workflow Log

### Step 1: Apply Resources to Cluster

Apply all manifests inside the `k8s/` directory in a single command:

```bash
kubectl apply -f k8s/

```

**Output:**

```text
configmap/sillypets-config created
deployment.apps/sillypets-deployment configured
secret/sillypets-secret created
service/sillypets-service unchanged

```

---

### Step 2: Verify Pod Execution Status

List running pods to ensure zero initialization or image pull errors occurred:

```bash
kubectl get pods -l app=sillypets

```

**Output:**

```text
NAME                                    READY   STATUS    RESTARTS   AGE
sillypets-deployment-765849586c-89kh9   1/1     Running   0          16s
sillypets-deployment-765849586c-cj66c   1/1     Running   0          8s
sillypets-deployment-765849586c-xgnmr   1/1     Running   0          9s

```

---

### Step 3: Inspect Injected Runtime Environment Variables

Execute into one of the active container instances and verify that environment variables from both the `ConfigMap` and `Secret` are loaded:

```bash
kubectl exec -it sillypets-deployment-765849586c-89kh9 -- env | grep -E "APP_|API_|DB_"

```

**Output:**

```text
APP_COLOR=coral
APP_TITLE=Silly Pets Gallery
API_KEY=silly-secret-key-998877
DB_PASSWORD=PetPassword2026!

```

---

### Step 4: Examine Base64 Secret Obfuscation in `etcd`

View how Kubernetes converts plain-text `stringData` into Base64 within the cluster state:

```bash
kubectl get secret sillypets-secret -o yaml

```

**Output:**

```yaml
apiVersion: v1
data:
  API_KEY: c2lsbHktc2VjcmV0LWtleS05OTg4Nzc=
  DB_PASSWORD: UGV0UGFzc3dvcmQyMDI2IQ==
kind: Secret
metadata:
  name: sillypets-secret
  namespace: default
type: Opaque

```

---

### Step 5: Programmatic Base64 Secret Decoding

Extract and decode Base64 data directly using `kubectl` and the `base64` utility:

```bash
kubectl get secret sillypets-secret -o jsonpath="{.data.DB_PASSWORD}" | base64 --decode

```

**Output:**

```text
PetPassword2026!

```

---

## 5. Advanced Injection Patterns: Volume Mounts

While environment variables are easy to set up, they remain static for the lifetime of a container. If a `ConfigMap` is updated, containers using environment variables **will not** reflect the change until the Pod is restarted.

Mounting a `ConfigMap` or `Secret` as a **Volume** projects configuration keys as files inside the container directory. Kubernetes automatically updates mounted files in near real-time when the underlying `ConfigMap` or `Secret` changes.

### Manifest Example: Volume Mounting

```yaml
spec:
  containers:
  - name: sillypets-container
    image: musabalaaudu/sillypets:latest
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
      readOnly: true
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
  volumes:
  - name: config-volume
    configMap:
      name: sillypets-config
  - name: secret-volume
    secret:
      secretName: sillypets-secret

```

**Resulting Container File Layout:**

* `/etc/config/APP_TITLE` contains `"Silly Pets Gallery"`
* `/etc/config/APP_COLOR` contains `"coral"`
* `/etc/secrets/API_KEY` contains `"silly-secret-key-998877"`
* `/etc/secrets/DB_PASSWORD` contains `"PetPassword2026!"`

---

## 6. Production Security & Best Practices

1. **Base64 is NOT Encryption:** Base64 encoding is purely a structural format, not security. Anyone with read access to the cluster namespace can decode secrets.
2. **Enable Encryption at Rest:** Configure Kubernetes API server to encrypt `etcd` secrets at rest using AWS KMS, Azure Key Vault, or GCP KMS.
3. **RBAC Isolation:** Restrict access to `Secret` resources using Role-Based Access Control (`RBAC`) so developers or non-admin service accounts cannot read sensitive data.
4. **GitOps Secret Hygiene:** Never commit raw `secret.yaml` files with plain-text credentials to Git repositories. Use secret management solutions like **HashiCorp Vault**, **Bitnami SealedSecrets**, or **SOPS** (Secrets OPerationS) to encrypt secrets before committing to source control.
