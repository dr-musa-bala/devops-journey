# Ansible Configuration Management Journey

This repository contains hands-on Ansible playbooks, dynamic Jinja2 templates, modular Ansible Roles, and a Capstone web stack deployment.

## Projects Included
- **Module 1:** Sanity checks & idempotency testing
- **Module 2:** Logic & flow control (`register`, `when`, `loop`)
- **Module 3:** Dynamic Jinja2 templating (`.j2`)
- **Module 4:** Enterprise Ansible Roles (`roles/floci_app`)
- **Module 5:** Container orchestration & HTTP health probes (`uri`)
- **Capstone:** Automated Nginx web stack deployment on port 8090

## Minimal & Zero-File Ansible Execution

While structured roles and playbooks are essential for enterprise stacks, Ansible can also be executed with minimal overhead for lightweight tasks:

### 1. Single-File Execution (`deploy.yml`)
Setting `connection: local` inside the play bypasses the need for an external `inventory.ini` file:

```yaml
---
- name: Minimal Single-File Execution
  hosts: localhost
  connection: local

  tasks:
    - name: Ensure Nginx container is running
      command: docker run -d -p 80:80 nginx
Execution:

Bash
ansible-playbook deploy.yml
2. Zero-File Ad-Hoc Commands
Execute raw module actions directly from the terminal without creating any YAML files:

Bash
# Ping local system (0 files required)
ansible localhost -m ping -c local

# Execute system updates directly (0 files required)
ansible localhost -m apt -a "name=curl state=present" -c local --become
