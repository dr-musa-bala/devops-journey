# 📄 Technical Documentation: Terraform Initialization & Variable Scope Resolution

**Project:** `devops-journey`

**Module:** Module 1 — Infrastructure as Code & CI/CD

**Topic:** Resolving Duplicate Variable Declarations & Local Initialization

---

## 1. Executive Summary

During the execution of local pre-flight checks and automated workflow validations for Terraform configurations, the initialization command failed during provider and module parsing.

This document details the exact error encountered, the root cause within Terraform's module scoping mechanism, the remediation steps applied to `main.tf` and `variables.tf`, and the verification process using `terraform init -backend=false` and `terraform validate`.

---

## 2. Command Executed & Error Output

To initialize the working directory without attempting to connect to remote state storage (such as AWS S3 or HashiCorp Cloud), the following command was executed:

```bash
terraform init -backend=false

```

### Exact Error Log Returned:

```text
Run terraform init -backend=false
╷
│ Error: Terraform encountered problems during initialisation, including problems
│ with the configuration, described below.
│ 
│ The Terraform configuration must be valid before initialization so that
│ Terraform can determine which modules and providers need to be installed.
│ 
│ 
╵
╷
│ Error: Duplicate variable declaration
│ 
│   on variables.tf line 13:
│   13: variable "image_tag" {
│ 
│ A variable named "image_tag" was already declared at main.tf:4,1-21.
│ Variable names must be unique within a module.
╵
Error: Process completed with exit code 1.

```

---

## 3. Technical Root Cause Analysis

### A. Terraform File Merging Mechanism

Unlike programming languages where files represent separate isolated namespaces or modules, **Terraform evaluates all `.tf` files in a single root directory as one combined configuration block**.

Whether code is split across `main.tf`, `variables.tf`, `outputs.tf`, or `providers.tf`, Terraform concatenates them internally into a single flat namespace.

```text
   ┌────────────────────────────────┐
   │            main.tf             │
   │  variable "image_tag" { ... }  │
   └───────────────┬────────────────┘
                   │
                   ├───> Merged into single Root Module Namespace
                   │
   ┌───────────────┴────────────────┐
   │          variables.tf          │
   │  variable "image_tag" { ... }  │
   └────────────────────────────────┘
                   │
                   ▼
  💥 ERROR: Duplicate Variable "image_tag"

```

### B. Namespace Collision

Because `variable "image_tag"` was defined in `main.tf` (lines 4–21) AND re-declared in `variables.tf` (line 13), Terraform flagged a fatal scope conflict. Variable names must be unique across the entire directory.

---

## 4. Remediation Steps Applied

To align with standard Terraform design patterns and separation-of-concerns guidelines:

1. **Cleaned `main.tf`:** Deleted the duplicate `variable "image_tag"` block from lines 4–21 in `main.tf`. Reserved `main.tf` strictly for infrastructure resources, data sources, and provider blocks.
2. **Standardized `variables.tf`:** Consolidated all variable definitions inside `variables.tf` as the single source of truth:

```hcl
# variables.tf
variable "image_tag" {
  type        = string
  description = "The container image tag to deploy"
  default     = "latest"
}

```

---

## 5. Verification & Testing Commands

After removing the duplicate variable definition from `main.tf`, the configuration was re-validated using two core CLI commands:

### Step 1: Re-Run Initialization

```bash
terraform init -backend=false

```

> **What `-backend=false` does:** Instructs Terraform to initialize provider plugins and validate configuration files *without* configuring or attempting to connect to a remote backend state file (e.g., AWS S3, Terraform Cloud). This is ideal for local testing, syntax checks, and CI pipeline validation jobs.

### Step 2: Validate Configuration Syntax

```bash
terraform validate

```

> **What `terraform validate` does:** Verifies whether the configuration is syntactically valid and internally consistent across all `.tf` files in the directory.

---

## 6. Summary of Standard Directory Conventions

| File Name | Intended Purpose | Allowed Blocks |
| --- | --- | --- |
| `main.tf` | Primary infrastructure resource declarations | `resource`, `data`, `module` |
| `variables.tf` | Input variable declarations and defaults | `variable` |
| `outputs.tf` | Values to expose after deployment | `output` |
| `providers.tf` | Cloud provider requirements & versions | `terraform`, `provider` |
