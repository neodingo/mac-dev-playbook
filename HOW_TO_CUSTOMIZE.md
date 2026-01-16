# How to Customize This Playbook

This guide explains how to customize the mac-dev-playbook for your personal macOS development environment.

## Quick Start

1. **Create your configuration file:**
   ```bash
   cp default.config.yml config.yml
   ```

2. **Edit `config.yml`** with your preferences (see sections below)

3. **Run the playbook:**
   ```bash
   ansible-galaxy install -r requirements.yml
   ansible-playbook main.yml --ask-become-pass
   ```

## Configuration Philosophy

- **`default.config.yml`** - Contains defaults; do NOT modify this file
- **`config.yml`** - Your personal overrides; this file is gitignored

Variables in `config.yml` override those in `default.config.yml`. You only need to include settings you want to change.

---

## Homebrew Packages

### CLI Tools

Add command-line tools you use daily:

```yaml
homebrew_installed_packages:
  # Development
  - git
  - gh
  - node
  - python
  - go
  - rust

  # DevOps
  - docker-compose
  - terraform
  - kubectl
  - awscli

  # Utilities
  - jq
  - ripgrep
  - fzf
  - tmux
  - htop

  # Database clients
  - postgresql
  - mysql
  - redis
```

### GUI Applications (Casks)

Add macOS applications:

```yaml
homebrew_cask_apps:
  # Browsers
  - google-chrome
  - firefox
  - arc

  # Development
  - visual-studio-code
  - iterm2
  - docker
  - postman
  - tableplus

  # Productivity
  - slack
  - zoom
  - notion
  - 1password
  - raycast

  # Design
  - figma
  - imageoptim

  # Media
  - spotify
  - vlc
```

### Custom Taps

Add third-party Homebrew repositories:

```yaml
homebrew_taps:
  - homebrew/cask-fonts
  - hashicorp/tap
  - cloudflare/cloudflare
```

---

## Mac App Store Apps

Install apps from the Mac App Store. You must be signed in to the App Store first.

Find app IDs by searching the App Store, then extract the ID from the URL (e.g., `https://apps.apple.com/app/id497799835` -> ID is `497799835`).

```yaml
mas_installed_apps:
  - { id: 497799835, name: "Xcode" }
  - { id: 1475387142, name: "Tailscale" }
  - { id: 904280696, name: "Things 3" }
  - { id: 1295203466, name: "Microsoft Remote Desktop" }
  - { id: 409183694, name: "Keynote" }
```

---

## Dotfiles

Manage your shell configuration, git settings, and other dotfiles:

```yaml
configure_dotfiles: true

# Point to YOUR dotfiles repository
dotfiles_repo: https://github.com/YOUR_USERNAME/dotfiles.git
dotfiles_repo_local_destination: ~/Development/dotfiles
dotfiles_repo_version: main  # branch name

# Which files to symlink to your home directory
dotfiles_files:
  - .zshrc
  - .bashrc
  - .gitconfig
  - .gitignore_global
  - .vimrc
  - .tmux.conf
  - .ssh/config
```

**Tip:** Create your own dotfiles repo on GitHub and customize it over time.

---

## Dock Configuration

Customize the macOS Dock:

```yaml
configure_dock: true

# Remove default apps you don't use
dockitems_remove:
  - Launchpad
  - TV
  - Podcasts
  - News
  - Keynote
  - Numbers
  - Pages
  - Maps
  - FaceTime
  - Freeform

# Add apps in specific positions
dockitems_persist:
  - name: "Google Chrome"
    path: "/Applications/Google Chrome.app/"
    pos: 1
  - name: "iTerm"
    path: "/Applications/iTerm.app/"
    pos: 2
  - name: "Visual Studio Code"
    path: "/Applications/Visual Studio Code.app/"
    pos: 3
  - name: "Slack"
    path: "/Applications/Slack.app/"
    pos: 4
  - name: "Spotify"
    path: "/Applications/Spotify.app/"
    pos: 5
```

---

## Extra Package Managers

Install packages from npm, pip, gem, and composer:

### Node.js / npm

```yaml
npm_packages:
  - name: typescript
  - name: eslint
  - name: prettier
  - name: yarn
  - name: pnpm
  - name: "@angular/cli"
    version: "^17"
```

### Python / pip

```yaml
pip_packages:
  - name: ansible
  - name: black
  - name: pytest
  - name: httpie
  - name: pipenv
    state: latest
```

### Ruby / gem

```yaml
gem_packages:
  - name: bundler
  - name: rails
  - name: cocoapods
  - name: fastlane
```

### PHP / Composer

```yaml
composer_packages:
  - name: laravel/installer
  - name: phpunit/phpunit
    version: "^10"
```

---

## Sudoers Configuration

Enable passwordless sudo (use with caution):

```yaml
configure_sudoers: true
sudoers_custom_config: |
  # Allow admin users to sudo without password
  %admin ALL=(ALL) NOPASSWD: ALL
```

---

## macOS System Preferences

The playbook runs a `.osx` script from your dotfiles to configure system preferences:

```yaml
configure_osx: true
osx_script: "~/.osx --no-restart"
```

Example `.osx` script settings (put this in your dotfiles):

```bash
#!/usr/bin/env bash

# Faster key repeat
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show path bar in Finder
defaults write com.apple.finder ShowPathbar -bool true

# Disable press-and-hold for keys
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Enable tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
```

---

## Terminal.app Configuration

Configure the built-in Terminal app:

```yaml
configure_terminal: true
```

---

## Sublime Text

Configure Sublime Text packages:

```yaml
configure_sublime: true
sublime_package_control:
  - "Package Control"
  - "Theme - One Dark"
  - "SublimeLinter"
  - "GitGutter"
  - "Emmet"
  - "BracketHighlighter"
```

---

## Post-Provision Tasks

Run custom Ansible tasks after the main playbook:

```yaml
post_provision_tasks:
  - "{{ playbook_dir }}/tasks/custom/*.yml"
```

Create custom task files in `tasks/custom/`:

**Example: `tasks/custom/dev-directories.yml`**
```yaml
---
- name: Create development directories.
  file:
    path: "{{ item }}"
    state: directory
    mode: 0755
  loop:
    - ~/Development
    - ~/Development/projects
    - ~/Development/sandbox
    - ~/Development/work

- name: Clone frequently used repositories.
  git:
    repo: "{{ item.repo }}"
    dest: "{{ item.dest }}"
  loop:
    - { repo: "https://github.com/my-org/project.git", dest: "~/Development/work/project" }
```

**Example: `tasks/custom/ssh-keys.yml`**
```yaml
---
- name: Ensure .ssh directory exists.
  file:
    path: ~/.ssh
    state: directory
    mode: 0700

- name: Generate SSH key if not present.
  community.crypto.openssh_keypair:
    path: ~/.ssh/id_ed25519
    type: ed25519
  register: ssh_key

- name: Display public key for GitHub.
  debug:
    msg: "Add this to GitHub: {{ ssh_key.public_key }}"
  when: ssh_key.changed
```

---

## Feature Toggles

Disable features you don't need:

```yaml
# Set to false to skip these sections
configure_dotfiles: true
configure_terminal: false    # Skip Terminal.app config
configure_osx: true
configure_dock: false        # Skip Dock customization
configure_sudoers: false     # Skip sudoers changes
configure_sublime: false     # Skip Sublime Text config
```

---

## Running Specific Parts

Run only certain sections using tags:

```bash
# Only install Homebrew packages
ansible-playbook main.yml -K --tags "homebrew"

# Only configure dotfiles and Dock
ansible-playbook main.yml -K --tags "dotfiles,dock"

# Available tags:
#   homebrew, dotfiles, mas, dock, sudoers,
#   terminal, osx, extra-packages, sublime-text, post
```

---

## Complete Example config.yml

Here's a full example configuration:

```yaml
---
# Dotfiles
configure_dotfiles: true
dotfiles_repo: https://github.com/myuser/dotfiles.git
dotfiles_repo_local_destination: ~/Development/dotfiles
dotfiles_files:
  - .zshrc
  - .gitconfig
  - .vimrc

# Homebrew CLI tools
homebrew_installed_packages:
  - git
  - gh
  - node
  - python
  - go
  - jq
  - ripgrep
  - fzf
  - tmux
  - wget
  - awscli
  - kubectl

# Homebrew GUI apps
homebrew_cask_apps:
  - google-chrome
  - visual-studio-code
  - iterm2
  - docker
  - slack
  - spotify
  - 1password
  - raycast

# Mac App Store
mas_installed_apps:
  - { id: 497799835, name: "Xcode" }
  - { id: 1475387142, name: "Tailscale" }

# Dock
configure_dock: true
dockitems_remove:
  - Launchpad
  - TV
  - Podcasts
  - News
dockitems_persist:
  - name: "Google Chrome"
    path: "/Applications/Google Chrome.app/"
    pos: 1
  - name: "iTerm"
    path: "/Applications/iTerm.app/"
    pos: 2
  - name: "Visual Studio Code"
    path: "/Applications/Visual Studio Code.app/"
    pos: 3

# Extra packages
npm_packages:
  - name: typescript
  - name: prettier

pip_packages:
  - name: black
  - name: pytest

# Feature toggles
configure_terminal: false
configure_sudoers: false
configure_sublime: false
configure_osx: true

# Post-provision
post_provision_tasks:
  - "{{ playbook_dir }}/tasks/custom/*.yml"
```

---

## Tips

1. **Start small** - Begin with just the packages you know you need, add more over time

2. **Version control your config** - Keep your `config.yml` in a private gist or separate repo

3. **Test incrementally** - Use `--check` flag for dry runs:
   ```bash
   ansible-playbook main.yml -K --check
   ```

4. **Debug with verbosity**:
   ```bash
   ansible-playbook main.yml -K -vvv
   ```

5. **Skip slow parts during testing**:
   ```bash
   ansible-playbook main.yml -K --skip-tags "mas"
   ```
