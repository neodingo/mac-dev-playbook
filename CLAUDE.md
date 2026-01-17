# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Ansible playbook for automating macOS development environment setup. It installs and configures software via Homebrew, Mac App Store, dotfiles, and various package managers.

## Virtual Environment

All Python/pip operations use the local virtual environment. Activate it before running any commands:
```bash
source .venv/bin/activate
```

## Common Commands

### Run the playbook
```bash
source .venv/bin/activate
ansible-playbook main.yml --ask-become-pass
```

### Install dependencies (required before first run)
```bash
source .venv/bin/activate
ansible-galaxy install -r requirements.yml
```

### Run specific tagged tasks
```bash
ansible-playbook main.yml -K --tags "dotfiles,homebrew"
```
Available tags: `dotfiles`, `homebrew`, `mas`, `extra-packages`, `osx`, `dock`, `terminal`, `sudoers`, `sublime-text`, `post`

### Linting
```bash
yamllint .
ansible-lint
```

### Test playbook syntax
```bash
ansible-playbook main.yml --syntax-check
```

### Dry run (check mode)
```bash
ansible-playbook main.yml -K --check --diff
```

## CI

GitHub Actions runs lint and integration tests on PRs and pushes to master. Integration tests run the full playbook on macOS 14 and 15 and verify idempotence.

## Architecture

### Configuration
- `default.config.yml` - Default configuration values (do not modify for personal use)
- `config.yml` - User overrides (create this file, not tracked in git)
- Variables in `config.yml` override those in `default.config.yml`

### Main Playbook Structure (`main.yml`)
The playbook runs in this order:
1. **Roles** (external Ansible roles):
   - `elliotweiser.osx-command-line-tools` - Ensures Xcode CLI tools installed
   - `geerlingguy.mac.homebrew` - Manages Homebrew packages and casks
   - `geerlingguy.dotfiles` - Clones and symlinks dotfiles
   - `geerlingguy.mac.mas` - Mac App Store app installation
   - `geerlingguy.mac.dock` - Dock configuration via dockutil

2. **Tasks** (in `tasks/` directory):
   - `sudoers.yml` - Custom sudoers configuration
   - `terminal.yml` - Terminal.app preferences
   - `osx.yml` - Runs the `.osx` dotfile script
   - `extra-packages.yml` - Composer, gem, npm, pip packages
   - `sublime-text.yml` - Sublime Text package configuration

3. **Post-provision tasks** - Custom task files via `post_provision_tasks` variable

### External Dependencies (`requirements.yml`)
- `elliotweiser.osx-command-line-tools` - Role for Xcode CLI tools
- `geerlingguy.dotfiles` - Role for dotfiles management
- `geerlingguy.mac` - Collection (includes homebrew, mas, dock roles)
- `community.general` - Collection for additional modules

### Key Configuration Variables
- `homebrew_installed_packages` / `homebrew_cask_apps` - Packages to install
- `mas_installed_apps` - Mac App Store apps (requires App Store login)
- `configure_*` booleans - Toggle features: `dotfiles`, `terminal`, `osx`, `dock`, `sudoers`, `sublime`
- `*_packages` - Extra packages: `composer_packages`, `gem_packages`, `npm_packages`, `pip_packages`
- `post_provision_tasks` - Glob pattern for additional task files to run at the end

### Style Conventions

#### Path Expansion
- Use `~` for paths in Ansible module parameters (file, copy, stat, get_url, etc.)
- Use `{{ ansible_facts['env']['HOME'] }}` for paths in:
  - `command` or `shell` module command strings (not args like `creates`)
  - Template files
  - When the literal expanded path is needed
- The `~` shorthand is expanded by Python's `os.path.expanduser` in most modules

#### When Clauses
- Use unquoted simple conditions: `when: configure_dotfiles`
- Use single quotes for string comparisons: `when: "'value' in variable"`
- Use boolean expressions without quotes: `when: not variable.stat.exists`

#### Command Tasks
- Always include `changed_when` on command/shell tasks
- Use `changed_when: false` for read-only commands
- Use `changed_when: true` when the command always changes state
- Use conditional `changed_when` when change detection is possible
