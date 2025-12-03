# Homelab Infrastructure

This repository contains the Ansible playbooks and configuration used to manage my personal homelab servers.

## Overview

This project automates the provisioning and configuration of my infrastructure, including:
*   Base system configuration (users, packages, SSH hardening)
*   Docker & Container orchestration
*   Network configuration
*   Service deployment (Plex, Nextcloud, Home Assistant, etc.)

## Prerequisites

*   Ansible installed on the control node.
*   SSH access to the target servers.
*   A valid `inventory/hosts.yml` file 

## Bootstrapping a server

1. Install OS on sever
2. ssh into server
3. `ssh-copy-id -i ~/.ssh/<private-key> <user>@<server-ip>` for password-less access
4. Use initial user in `hosts.yml` for that server
5. Run `ansible-galaxy install -r requirements.yml`
6. Run this playbook for the first time:
```
ansible-playbook -i inventory/hosts.yml playbooks/bootstrap.yml \
-u <init-user> \
--private-key ~/.ssh/<private-key> \
--ask-become-pass
```
7. Update user in `hosts.yml` to use value of `ansible_service_user` below
8. Run `ansible all -m ping -i inventory/hosts.yml` to verify ansible user was creatd and is valid

## Quickstart Commands

Here are the most common commands needed to manage the infrastructure.

### 1. Test Connectivity

Ensure Ansible can reach all hosts defined in the inventory.

```bash
ansible all -i inventory/hosts.yml -m ping
```

### 2. Run the Main Playbook

Apply the configuration to all servers.

```bash
ansible-playbook -i inventory/hosts.yml site.yml
```

### 3. Run a Specific Tag

If you only want to update a specific part of the system (e.g., just update Docker containers or system packages).

```bash
# Only run tasks tagged with 'docker'
ansible-playbook -i inventory/hosts.yml site.yml --tags "docker"

# Only run system updates
ansible-playbook -i inventory/hosts.yml site.yml --tags "updates"
```

### 4. Limit to a Specific Host

Run the playbook only on a specific server (e.g., `media-server`).

```bash
ansible-playbook -i inventory/hosts.yml site.yml --limit media-server
```

### 5. Decrypt/Encrypt Secrets

This repository uses Ansible Vault to protect sensitive variables.

```bash
# Edit encrypted secrets
ansible-vault edit group_vars/all/vault.yml

# Run playbook asking for vault password
ansible-playbook -i inventory/hosts.yml site.yml --ask-vault-pass
```

## Directory Structure

*   `inventory/`: Contains inventory files (hosts).
*   `roles/`: Ansible roles for specific services or configurations.
*   `group_vars/`: Variables applied to groups of servers.
*   `site.yml`: The main playbook entry point.
