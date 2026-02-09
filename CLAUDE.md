# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Ansible playbook that automates macOS development environment setup. It installs packages via Homebrew, configures dotfiles, manages Mac App Store apps, sets up the Dock, and applies macOS preferences. Originally by Jeff Geerling, forked for personal customization.

## Key Commands

```bash
# Install dependencies (roles and collections from Ansible Galaxy)
ansible-galaxy install -r requirements.yml

# Run the full playbook
ansible-playbook main.yml --ask-become-pass

# Run specific sections using tags
ansible-playbook main.yml -K --tags "homebrew"
ansible-playbook main.yml -K --tags "dotfiles,homebrew"
ansible-playbook main.yml -K --tags "mas"
ansible-playbook main.yml -K --tags "dock"
ansible-playbook main.yml -K --tags "osx"
ansible-playbook main.yml -K --tags "extra-packages"
ansible-playbook main.yml -K --tags "sublime-text"
ansible-playbook main.yml -K --tags "post"

# Dry run (check mode)
ansible-playbook main.yml --ask-become-pass --check

# Syntax check
ansible-playbook main.yml --syntax-check

# Linting
yamllint .
ansible-lint
```

## Architecture

**Entry point**: `main.yml` - single playbook that runs against localhost (see `inventory`).

**Variable layering**: `default.config.yml` defines all defaults. A user-created `config.yml` (gitignored) overrides any defaults. Variables are merged via `include_vars` with the `always` tag.

**Execution order in `main.yml`**:
1. **Pre-tasks**: Load user config overrides
2. **Roles** (external, installed via `requirements.yml`):
   - `elliotweiser.osx-command-line-tools` - Xcode CLI tools
   - `geerlingguy.mac.homebrew` - Homebrew packages and casks
   - `geerlingguy.dotfiles` - Clone and symlink dotfiles (conditional: `configure_dotfiles`)
   - `geerlingguy.mac.mas` - Mac App Store apps (conditional: mas lists non-empty)
   - `geerlingguy.mac.dock` - Dock layout (conditional: `configure_dock`)
3. **Tasks** (local, in `tasks/`):
   - `sudoers.yml`, `terminal.yml`, `osx.yml`, `extra-packages.yml`, `sublime-text.yml`
   - Each gated by a `configure_*` boolean and a tag
4. **Post-provision**: Runs any task files matched by the `post_provision_tasks` glob

**Customization**: Users create `config.yml` to override variables from `default.config.yml`. The `config.yml` file is gitignored so personal configuration stays local.

## CI/CD

GitHub Actions (`.github/workflows/ci.yml`):
- **Lint job** (Ubuntu): runs `yamllint .` and `ansible-lint`
- **Integration job** (macOS 14, 15): full playbook run + idempotence check (second run must produce `changed=0`)
- Test configs in `tests/` provide a minimal package set for CI

## Linting Configuration

- `.yamllint`: max line length 180 (warning level)
- `.ansible-lint`: skips `schema[meta]`, `role-name`, `experimental`, `fqcn`, `name[missing]`, `no-changed-when`, `risky-file-permissions`, `yaml`; excludes `roles/elliotweiser.osx-command-line-tools`
- `ansible.cfg`: `become = True` by default, YAML result format, roles in `./roles`

## Important Conventions

- External roles are gitignored in `roles/` - always install via `ansible-galaxy install -r requirements.yml`
- Each task section is gated by both a `configure_*` boolean variable and an Ansible tag
- The `extra-packages.yml` task handles composer, npm, pip, and gem packages - each expects a list variable with `name`, optional `state`, and optional `version`
- The playbook targets `127.0.0.1` with `ansible_connection=local` but can also manage remote Macs over SSH by changing the inventory
