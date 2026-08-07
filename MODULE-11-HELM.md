# Module 11: Kubernetes Package Management with Helm

## Overview

This module demonstrates how to transform static Kubernetes manifests (`deployment.yaml`, `service.yaml`) into a dynamic, reusable **Helm Chart** for the `sillypets` microservice.

Helm acts as the package manager for Kubernetes, enabling single-command deployments, environment parameterization through `values.yaml`, release versioning, and instant rollbacks.

---

## 1. Core Architecture & Concepts

| Term | Description |
| --- | --- |
| **Helm Chart** | A structured package containing template manifests and configuration settings (`sillypets-chart`). |
| **`values.yaml`** | The single source of truth for variables (replicas, image tags, ports, environment settings). |
| **Templates** | Dynamic Kubernetes YAML manifests using Go templating logic (`{{ .Values... }}`). |
| **Release** | A specific deployed instance of a Helm chart running inside the cluster. |

---

## 2. Directory Structure

```text
sillypets-chart/
├── Chart.yaml          # Metadata (chart name, version, description)
├── values.yaml         # Configuration values & parameters
└── templates/          # Go-templated Kubernetes manifests
    ├── deployment.yaml
    └── service.yaml

```

---

## 3. Configuration & Template Manifests

### Configuration (`values.yaml`)

```yaml
replicaCount: 3

image:
  repository: musabalaaudu/sillypets
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: NodePort
  port: 80
  nodePort: 30080

config:
  appTitle: "Silly Pets Gallery (Helm Powered)"
  appColor: "coral"

```

### Deployment Template (`templates/deployment.yaml`)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-deployment
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
      - name: {{ .Chart.Name }}
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        ports:
        - containerPort: {{ .Values.service.port }}
        env:
        - name: APP_TITLE
          value: {{ .Values.config.appTitle | quote }}
        - name: APP_COLOR
          value: {{ .Values.config.appColor | quote }}

```

### Service Template (`templates/service.yaml`)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-service
spec:
  type: {{ .Values.service.type }}
  selector:
    app: {{ .Release.Name }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.port }}
      nodePort: {{ .Values.service.nodePort }}

```

---

## 4. Operational Playbook & Commands

### Chart Lifecycle Management

```bash
# 1. Preview generated manifest without applying (Dry-Run / Debug)
helm template sillypets .

# 2. Deploy the Helm release
helm install sillypets .

# 3. View deployed releases in the current namespace
helm list

# 4. View detailed release revision history
helm history sillypets

```

### Dynamic Updates & Rollbacks

```bash
# Scale pods and change color on the fly without editing files
helm upgrade sillypets . --set replicaCount=5 --set config.appColor="purple"

# Instantly rollback to Revision 1
helm rollback sillypets 1

# Complete teardown of release and associated resources
helm uninstall sillypets

```

---

## 5. Verification & Testing

### Confirm Running Pods and Service

```bash
kubectl get pods,svc -l app=sillypets

```

### Verify Dynamic Environment Variable Injection

```bash
kubectl exec -it <POD_NAME> -- env | grep APP_

```

**Output:**

```text
APP_TITLE=Silly Pets Gallery (Helm Powered)
APP_COLOR=coral

```

---

## 6. Troubleshooting Edge Cases & Fixes

| Issue / Error | Cause | Resolution |
| --- | --- | --- |
| `nil pointer evaluating interface {}.create` | Default boilerplate templates (`serviceaccount.yaml`) missing keys in custom `values.yaml`. | Clear out unused default templates (`rm -rf templates/*`) and recreate targeted manifests. |
| `chart file ... is larger than maximum file size 5242880` | Executing `helm install` from parent directory, causing Helm to archive entire repo directory. | Change directory into the chart folder (`cd sillypets-chart`) before running `helm install`. |
| `invalid ownership metadata` | Pre-existing resources created via `kubectl apply` without Helm release annotations. | Remove raw manifests (`kubectl delete -f ../k8s/`) before deploying via Helm. |
| `cannot re-use a name that is still in use` | A release with the same name is already deployed. | Run `helm uninstall sillypets` or use `helm upgrade --install sillypets .`. |

---

## 7. Key Takeaways

1. **Declarative Parameterization:** `values.yaml` separates operational parameters from structural deployment logic.
2. **Release Versioning:** Helm maintains an immutable revision history for easy auditing and fast disaster recovery (`helm rollback`).
3. **Atomic Operations:** Helm ensures all manifests inside a chart are managed as a single cohesive unit.
