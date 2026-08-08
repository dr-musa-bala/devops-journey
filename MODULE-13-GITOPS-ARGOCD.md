# Module 13: GitOps Principles & Automated Deployments with ArgoCD

## Overview

This module covers the operational implementation of **GitOps continuous delivery** using **ArgoCD**. By designating Git as the single source of truth for application infrastructure, ArgoCD automates the deployment lifecycle, enforces state reconciliation, and enables continuous automated synchronization and self-healing across target Kubernetes environments.

---

## 1. GitOps Core Principles

GitOps is an operational framework that applies DevOps best practices—such as version control, collaboration, compliance, and CI/CD pipelines—to infrastructure automation.

* **Declarative Specification:** The entire system state (deployments, services, ingress rules, values) is defined declaratively in Git (`sillypets-chart/`).
* **Versioned and Immutable:** Desired state changes are made via Git commits (`git push`), providing audit trails, governance, and seamless rollback capability.
* **Automated Pull-Based Sync:** Software agents (ArgoCD) running inside the cluster pull desired configurations from Git, eliminating the need to expose cluster API credentials to external pipeline runners.
* **Continuous State Reconciliation:** ArgoCD continuously compares the live cluster state against the desired Git state, automatically detecting drift and restoring compliance.

---

## 2. Infrastructure Architecture & Installation

ArgoCD operates inside the target Kubernetes cluster within a dedicated isolated namespace (`argocd`).

```text
  ┌─────────────────────────────────────────────────────────────┐
  │                   GitHub Repository (Git)                   │
  │     https://github.com/dr-musa-bala/devops-journey.git      │
  └──────────────────────────────┬──────────────────────────────┘
                                 │
                 (Continuous Polling / Git Webhook)
                                 │
                                 ▼
  ┌─────────────────────────────────────────────────────────────┐
  │                 Kubernetes Cluster (Minikube)               │
  │                                                             │
  │  ┌───────────────────────────────────────────────────────┐  │
  │  │                  'argocd' Namespace                    │  │
  │  │  - argocd-server (Web UI & API Engine)                │  │
  │  │  - argocd-repo-server (Fetches & renders Helm charts) │  │
  │  │  - argocd-application-controller (Reconciliation Loop)│  │
  │  └───────────────────────────┬───────────────────────────┘  │
  │                              │                              │
  │                (Automated Sync / Self-Healing)              │
  │                              │                              │
  │                              ▼                              │
  │  ┌───────────────────────────────────────────────────────┐  │
  │  │                  'default' Namespace                  │  │
  │  │  - sillypets-gitops-deployment                        │  │
  │  │  - sillypets-gitops-service                           │  │
  │  │  - Pods (App Workloads)                                 │  │
  │  └───────────────────────────────────────────────────────┘  │
  └─────────────────────────────────────────────────────────────┘

```

### Installation Procedure

1. **Namespace Creation:**
```bash
kubectl create namespace argocd

```


2. **Server-Side Manifest Application:**
*Note: Server-side apply (`--server-side`) was utilized to bypass client-side annotation size constraints (`262,144 bytes`) imposed by complex OpenAPI schemas within ArgoCD CustomResourceDefinitions (CRDs).*
```bash
kubectl apply --server-side --force-conflicts -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

```


3. **Cluster Rollout Verification:**
```bash
kubectl rollout status deployment/argocd-server -n argocd

```


4. **Web UI Access & Admin Credential Retrieval:**
```bash
# Port-forward ArgoCD API server locally
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Decode initial administrative secret
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

```



---

## 3. Declarative Application Deployment

Rather than using manual imperative CLI operations (`kubectl apply` or `helm install`), the application deployment is specified as a custom Kubernetes resource (`kind: Application`).

### Application Manifest Specification (`argocd-sillypets-app.yaml`)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sillypets-gitops
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/dr-musa-bala/devops-journey.git'
    targetRevision: main
    path: sillypets-chart
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true

```

### Configuration Breakdown

| Manifest Key | Operational Purpose |
| --- | --- |
| **`spec.source.repoURL`** | Target Git repository containing the application code and deployment configurations. |
| **`spec.source.targetRevision`** | Specifies the exact Git branch, tag, or commit SHA tracked by ArgoCD. |
| **`spec.source.path`** | Relative file path within the repository where the target Helm chart resides. |
| **`spec.destination.server`** | Internal Kubernetes API server endpoint (`[https://kubernetes.default.svc](https://kubernetes.default.svc)`). |
| **`spec.syncPolicy.automated.selfHeal`** | Enforces immediate restoration of live cluster state if manual out-of-band modifications or deletions occur. |
| **`spec.syncPolicy.automated.prune`** | Automatically deletes live resources in Kubernetes if their underlying definitions are removed from Git. |

---

## 4. Verification & Operational Testing

### Test 1: Self-Healing Reconciliation

To verify declarative state enforcement, an imperative deletion command was executed against live cluster resources:

```bash
# Imperative resource deletion
kubectl delete deployment sillypets-gitops-deployment -n default

```

**Observed Result:**
ArgoCD detected the missing Deployment object during its reconciliation loop, flagged the drift condition, and immediately re-applied the Helm templates from the Git repository, restoring the workload to `Healthy` and `Synced` status without manual operator intervention.

### Test 2: Declarative Auto-Sync (Git-Driven Rollout)

To test automated configuration rollouts via source control:

1. Updated `sillypets-chart/values.yaml` to modify the replica count or target configurations.
2. Committed and pushed changes to the tracking branch:
```bash
git add sillypets-chart/values.yaml
git commit -m "feat(gitops): update workload deployment parameters"
git push origin main

```



**Observed Result:**
ArgoCD polled the repository revision `main`, detected the new commit SHA (`a3d619e`), rendered the updated Helm templates, and applied the changes directly to the live Kubernetes cluster.

---

## 5. Playbook: Save Module 13 Documentation & Push

1. **Create MODULE-13-GITOPS-ARGOCD.md File:** Writes complete Module 13 documentation to repository root.
Run the following terminal command to save the file:

```bash
cat <<'EOF' > ~/devops-journey/MODULE-13-GITOPS-ARGOCD.md
# Module 13: GitOps Principles & Automated Deployments with ArgoCD

## Overview
This module covers the operational implementation of **GitOps continuous delivery** using **ArgoCD**. By designating Git as the single source of truth for application infrastructure, ArgoCD automates the deployment lifecycle, enforces state reconciliation, and enables continuous automated synchronization and self-healing across target Kubernetes environments.

---

## 1. GitOps Core Principles

* **Declarative Specification:** The entire system state is defined declaratively in Git (`sillypets-chart/`).
* **Versioned and Immutable:** Infrastructure changes occur strictly via version-controlled Git commits.
* **Automated Pull-Based Sync:** In-cluster agents pull desired configurations from Git, eliminating external cluster credential exposure.
* **Continuous Reconciliation:** ArgoCD continuously eliminates drift between desired Git state and live cluster state.

---

## 2. Infrastructure Architecture & Installation


```

text
┌─────────────────────────────────────────────────────────────┐
│                   GitHub Repository (Git)                   │
│     [https://github.com/dr-musa-bala/devops-journey.git](https://github.com/dr-musa-bala/devops-journey.git)      │
└──────────────────────────────┬──────────────────────────────┘
│
▼
┌─────────────────────────────────────────────────────────────┐
│                 Kubernetes Cluster (Minikube)               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                  'argocd' Namespace                    │  │
│  │  - argocd-server                                      │  │
│  │  - argocd-repo-server                                 │  │
│  │  - argocd-application-controller                      │  │
│  └───────────────────────────┬───────────────────────────┘  │
│                              │                              │
│                              ▼                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                  'default' Namespace                  │  │
│  │  - sillypets-gitops-deployment                        │  │
│  │  - sillypets-gitops-service                           │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

```

### Installation Summary

```

bash
kubectl create namespace argocd
kubectl apply --server-side --force-conflicts -n argocd -f [https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml](https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml)
kubectl rollout status deployment/argocd-server -n argocd

```

---

## 3. Application Manifest (`argocd-sillypets-app.yaml`)


```

yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
name: sillypets-gitops
namespace: argocd
spec:
project: default
source:
repoURL: '[https://github.com/dr-musa-bala/devops-journey.git](https://github.com/dr-musa-bala/devops-journey.git)'
targetRevision: main
path: sillypets-chart
helm:
valueFiles:
- values.yaml
destination:
server: '[https://kubernetes.default.svc](https://kubernetes.default.svc)'
namespace: default
syncPolicy:
automated:
prune: true
selfHeal: true
syncOptions:
- CreateNamespace=true

```

---

## 4. Verification & Operational Testing

* **Self-Healing Test:** Executed `kubectl delete deployment sillypets-gitops-deployment`. ArgoCD detected resource termination and automatically re-created the deployment.
* **Auto-Sync Test:** Pushed commit changes to `sillypets-chart/values.yaml`. ArgoCD detected revision updates and synced the cluster workload automatically.
