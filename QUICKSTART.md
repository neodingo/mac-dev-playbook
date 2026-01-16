# Quickstart: Brand New Mac to Fully Configured

This guide takes you from unboxing a new Mac to a fully configured development environment.

---

## Prerequisites

- A new (or freshly wiped) Mac
- Internet connection
- Your Apple ID (for Mac App Store apps)
- ~30-60 minutes

---

## Phase 1: Initial macOS Setup

Complete the macOS Setup Assistant:

1. Select your country and language
2. Connect to Wi-Fi
3. Sign in with your Apple ID (or skip for later)
4. Create your local user account
5. Complete remaining setup prompts
6. Arrive at the macOS desktop

---

## Phase 2: Prepare the System

### Step 1: Open Terminal

Press `Cmd + Space`, type `Terminal`, and press Enter.

### Step 2: Install Xcode Command Line Tools

```bash
xcode-select --install
```

A popup will appear. Click **Install**, then **Agree** to the license. Wait for the installation to complete (~5-10 minutes).

### Step 3: Install Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Important:** Follow the "Next steps" instructions shown after installation to add Homebrew to your PATH. Typically:

```bash
# For Apple Silicon Macs (M1/M2/M3/M4):
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# For Intel Macs:
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/usr/local/bin/brew shellenv)"
```

Verify Homebrew is working:

```bash
brew --version
```

### Step 4: Install Ansible

```bash
brew install ansible
```

Verify:

```bash
ansible --version
```

---

## Phase 3: Get the Playbook

### Step 1: Create a Development Directory

```bash
mkdir -p ~/Development
cd ~/Development
```

### Step 2: Clone This Repository

**Option A: Using HTTPS (no SSH key needed)**
```bash
git clone https://github.com/geerlingguy/mac-dev-playbook.git
cd mac-dev-playbook
```

**Option B: Using SSH (if you have keys configured)**
```bash
git clone git@github.com:geerlingguy/mac-dev-playbook.git
cd mac-dev-playbook
```

### Step 3: Install Ansible Dependencies

```bash
ansible-galaxy install -r requirements.yml
```

---

## Phase 4: Customize for Your Needs

### Step 1: Create Your Configuration File

```bash
cp default.config.yml config.yml
```

### Step 2: Edit Your Configuration

Open `config.yml` in a text editor:

```bash
nano config.yml
# or
open -a TextEdit config.yml
```

At minimum, customize these sections:

#### Your Dotfiles (if you have them)

```yaml
configure_dotfiles: true
dotfiles_repo: https://github.com/YOUR_USERNAME/dotfiles.git
dotfiles_repo_local_destination: ~/Development/dotfiles
dotfiles_files:
  - .zshrc
  - .gitconfig
  - .vimrc
```

If you don't have a dotfiles repo yet, set:
```yaml
configure_dotfiles: false
```

#### Homebrew Packages

Replace the default list with your preferred tools:

```yaml
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

homebrew_cask_apps:
  - google-chrome
  - visual-studio-code
  - iterm2
  - docker
  - slack
  - spotify
  - 1password
```

#### Mac App Store Apps (Optional)

```yaml
mas_installed_apps:
  - { id: 497799835, name: "Xcode" }
  - { id: 1475387142, name: "Tailscale" }
```

To find app IDs: Search the App Store on the web, and extract the ID from the URL.
Example: `https://apps.apple.com/app/id497799835` → ID is `497799835`

#### Disable Features You Don't Need

```yaml
configure_terminal: false
configure_osx: false
configure_dock: false
configure_sudoers: false
configure_sublime: false
```

Save and close the file (`Ctrl+X`, then `Y`, then `Enter` in nano).

---

## Phase 5: Sign into Mac App Store

**Required if you're installing any Mac App Store apps.**

1. Open the **App Store** app
2. Click **Sign In** and enter your Apple ID
3. Complete any verification if prompted

The `mas` tool cannot sign in automatically—you must do this manually before running the playbook.

---

## Phase 6: Run the Playbook

### Full Run

```bash
ansible-playbook main.yml --ask-become-pass
```

Enter your macOS user password when prompted for "BECOME password."

### What Happens

The playbook will:
1. Ensure Xcode CLI tools are installed
2. Install/update Homebrew packages and cask apps
3. Clone and symlink your dotfiles (if enabled)
4. Install Mac App Store apps (if configured)
5. Configure the Dock (if enabled)
6. Run any macOS preference scripts
7. Install extra packages (npm, pip, gem, composer)
8. Run post-provision tasks

This takes 10-30 minutes depending on what you're installing.

---

## Phase 7: Post-Installation

### Restart Your Mac

Some settings require a restart to take effect:

```bash
sudo reboot
```

### Manual Steps

Some things can't be automated:

1. **Grant permissions** - Apps like Docker, Terminal, and IDEs may request accessibility or full disk access permissions
2. **Sign into apps** - Slack, Spotify, 1Password, etc.
3. **Configure cloud sync** - Dropbox, iCloud Drive, Google Drive
4. **Set up email accounts** - Mail.app or your preferred email client
5. **Import SSH keys** - Copy from backup or generate new ones
6. **Configure Git identity**:
   ```bash
   git config --global user.name "Your Name"
   git config --global user.email "your.email@example.com"
   ```

---

## Troubleshooting

### "Xcode license not accepted"

```bash
sudo xcodebuild -license accept
```

### Homebrew issues

```bash
brew doctor
```

Follow any recommendations it provides.

### "mas" can't find apps / permission denied

Make sure you're signed into the App Store app (not just iCloud).

### Ansible Galaxy roles fail to download

```bash
ansible-galaxy install -r requirements.yml --force
```

### Playbook fails partway through

Fix the issue, then re-run. Ansible is idempotent—it will skip completed tasks:

```bash
ansible-playbook main.yml --ask-become-pass
```

### Run only specific parts

```bash
# Just Homebrew
ansible-playbook main.yml -K --tags "homebrew"

# Just dotfiles
ansible-playbook main.yml -K --tags "dotfiles"

# Skip Mac App Store (slow or problematic)
ansible-playbook main.yml -K --skip-tags "mas"
```

### Dry run (check mode)

See what would change without making changes:

```bash
ansible-playbook main.yml -K --check
```

### Verbose output for debugging

```bash
ansible-playbook main.yml -K -vvv
```

---

## Quick Reference: Complete Command Sequence

Copy-paste friendly version for experienced users:

```bash
# 1. Install Xcode CLI tools
xcode-select --install

# 2. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. Add Homebrew to PATH (Apple Silicon)
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

# 4. Install Ansible
brew install ansible

# 5. Clone and enter the playbook directory
mkdir -p ~/Development
git clone https://github.com/geerlingguy/mac-dev-playbook.git ~/Development/mac-dev-playbook
cd ~/Development/mac-dev-playbook

# 6. Install Ansible dependencies
ansible-galaxy install -r requirements.yml

# 7. Create and customize your config
cp default.config.yml config.yml
nano config.yml  # Edit to your preferences

# 8. Sign into App Store manually (if using mas_installed_apps)

# 9. Run the playbook
ansible-playbook main.yml --ask-become-pass
```

---

## Next Steps

- Read [HOW_TO_CUSTOMIZE.md](HOW_TO_CUSTOMIZE.md) for detailed customization options
- Create your own dotfiles repository
- Add post-provision tasks for additional automation
- Store your `config.yml` in a private gist or separate repo for future Mac setups
