# Homelab Infrastructure

Ansible playbooks that prepare my homelab machines (Ubuntu Server LTS) to run a
Kubernetes cluster. Cluster workloads live in the separate `homelab` repo
(deployed with Flux).

## Machines

| Host        | Role          | Notes  |
|-------------|---------------|--------|
| `nucbox`    | control plane | server |
| `xps9370`   | worker        | laptop |
| `asusx550c` | worker        | laptop |

Hosts are grouped in `inventory/hosts.yml` along two independent axes:

- **Cluster role** (`k8s_control`, `k8s_worker`, under `k8s_cluster`): what the machine does in Kubernetes.
- **Hardware traits** (`laptops`): what the machine is. Playbooks target groups, never hostnames.

Each machine's hostname is set from its inventory name (override with `node_hostname`).

## Prerequisites

- Ansible on the control node, plus the required collections:

  ```bash
  ansible-galaxy collection install -r requirements.yml
  ```

- `~/.ssh/ansible_id_ed25519` (and `.pub`): the key used for the `ansible` service user.
- `~/.ansible_vault_pass`: vault password file (referenced in `ansible.cfg`).
- Static IPs for every host, reserved in the router and matching `inventory/hosts.yml`.

## Bootstrapping a new machine

1. Install Ubuntu Server LTS and add the machine to `inventory/hosts.yml`.
2. Copy your key to the install user: `ssh-copy-id -i ~/.ssh/<private-key> <user>@<server-ip>`
3. Run the bootstrap, connecting as the install user. Use `-e`, **not** `-u` or `--private-key`: the `ansible_user` set in the inventory takes precedence over those flags.

   ```bash
   ansible-playbook playbooks/bootstrap.yml \
     -e ansible_user=<init-user> \
     -e ansible_ssh_private_key_file=~/.ssh/<private-key> \
     --ask-become-pass \
     --limit <host>
   ```

4. Verify the `ansible` user works: `ansible all -m ping`

The bootstrap is safe to re-run. It:

- creates the `ansible` user and sets the hostname
- installs base packages
- syncs time (chrony, timezone from `node_timezone`)
- makes journald persistent
- configures security-only unattended upgrades (never auto-reboot)
- enables Wake-on-LAN
- hardens SSH (key-only, no root login)

Laptops additionally ignore the lid switch and blank the console after 60s
(effective after the next reboot).

## Everyday commands

```bash
ansible all -m ping                                    # connectivity
ansible-playbook playbooks/update.yml                  # patch and reboot if needed, one host at a time
ansible-playbook playbooks/bootstrap.yml --limit <host>
ansible-playbook playbooks/<name>.yml --check --diff   # dry run
ansible-vault edit inventory/group_vars/k8s_cluster/vault.yml
```

## Layout

- `inventory/hosts.yml`: hosts and groups.
- `inventory/group_vars/`: variables per group (vault-encrypted secrets live here).
- `playbooks/bootstrap.yml`: first-run configuration for every machine.
- `playbooks/update.yml`: OS patching.
- `requirements.yml`: Ansible collections.
