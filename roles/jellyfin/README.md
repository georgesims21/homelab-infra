# Jellyfin Role

Ansible role to deploy Jellyfin media server as a Docker container.

## Requirements

- Docker installed on target host
- `community.docker` collection

## Role Variables

See [defaults/main.yml](defaults/main.yml) for all available variables.

Key variables:
- `jellyfin_state`: Container state (started, stopped, absent)
- `jellyfin_version`: Docker image tag (default: latest)
- `jellyfin_config_dir`: Configuration directory
- `jellyfin_cache_dir`: Cache directory
- `jellyfin_media_dir`: Media directory

## Dependencies

- geerlingguy.docker (or equivalent)

## Example Playbook

```yaml
- hosts: docker_hosts
  roles:
    - role: jellyfin
      vars:
        jellyfin_media_dir: /home/movies
```

## License

MIT
