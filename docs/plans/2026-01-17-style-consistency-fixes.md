# Style Consistency Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Standardize code style across the Ansible playbook for consistency, maintainability, and modern best practices.

**Architecture:** This is a refactoring effort with no functional changes. Each task focuses on a specific style inconsistency, making changes file-by-file with linting verification after each change.

**Tech Stack:** Ansible YAML, yamllint, ansible-lint

---

## Task 1: Add Missing Default for `mas_installed_app_ids`

**Files:**
- Modify: `/Users/michael/Development/automation/mac-dev-playbook/default.config.yml:82-84`

**Step 1: Add the missing default variable**

The `main.yml` references `mas_installed_app_ids` in a condition but it has no default in `default.config.yml`. Add it after `mas_installed_apps`:

```yaml
# See `geerlingguy.mac.mas` role documentation for usage instructions.
mas_installed_apps: []
mas_installed_app_ids: []
mas_email: ""
mas_password: ""
```

**Step 2: Run linting to verify syntax**

Run: `cd /Users/michael/Development/automation/mac-dev-playbook && yamllint default.config.yml`
Expected: No errors (warnings about line length are acceptable)

**Step 3: Run playbook syntax check**

Run: `cd /Users/michael/Development/automation/mac-dev-playbook && ansible-playbook main.yml --syntax-check`
Expected: "playbook: main.yml" with no errors

**Step 4: Commit**

```bash
git add default.config.yml
git commit -m "config: add missing default for mas_installed_app_ids

The main.yml playbook references this variable in a when condition
but it had no default value, which could cause undefined variable errors.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 2: Remove Outdated Yosemite TODO from tasks/terminal.yml

**Files:**
- Modify: `/Users/michael/Development/automation/mac-dev-playbook/tasks/terminal.yml:22`

**Step 1: Remove the outdated TODO comment**

Yosemite (OS X 10.10) was released in 2014 and is no longer supported. Remove the obsolete comment. Change from:

```yaml
# TODO: This doesn't work in Yosemite. Consider a different solution?
- name: Ensure custom Terminal profile is set as default.
```

To:

```yaml
- name: Ensure custom Terminal profile is set as default.
```

**Step 2: Run linting to verify syntax**

Run: `cd /Users/michael/Development/automation/mac-dev-playbook && yamllint tasks/terminal.yml`
Expected: No errors

**Step 3: Commit**

```bash
git add tasks/terminal.yml
git commit -m "style: remove outdated Yosemite-era TODO comment

The TODO referencing Yosemite (OS X 10.10, released 2014) is no longer
relevant as that macOS version is long unsupported.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Remove Outdated TODO from tasks/osx.yml

**Files:**
- Modify: `/Users/michael/Development/automation/mac-dev-playbook/tasks/osx.yml:2`

**Step 1: Remove the outdated TODO comment**

This TODO about running .osx via root is from an older era and the current approach works. Change from:

```yaml
---
# TODO: Use sudo once .osx can be run via root with no user interaction.
- name: Run .osx dotfiles.
```

To:

```yaml
---
- name: Run .osx dotfiles.
```

**Step 2: Run linting to verify syntax**

Run: `cd /Users/michael/Development/automation/mac-dev-playbook && yamllint tasks/osx.yml`
Expected: No errors

**Step 3: Commit**

```bash
git add tasks/osx.yml
git commit -m "style: remove outdated TODO comment about sudo usage

The TODO about running .osx via root is no longer relevant as the
current non-sudo approach has been working for years.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 4: Add `changed_when` to ai-dock-folder.yml Command Tasks

**Files:**
- Modify: `/Users/michael/Development/automation/mac-dev-playbook/tasks/custom/ai-dock-folder.yml:22-29`

**Step 1: Add `changed_when: false` to the dockutil command**

The dockutil command always reports changed even when no changes occur. Add proper idempotency handling:

```yaml
- name: Add AI folder to dock with fan view.
  command: >
    dockutil --add "{{ ansible_facts['env']['HOME'] }}/Applications/AI"
    --view fan
    --display stack
    --sort name
    --replacing 'AI'
    --no-restart
  register: dockutil_result
  changed_when: "'already exists' not in dockutil_result.stderr | default('')"
```

**Step 2: Run ansible-lint to verify**

Run: `cd /Users/michael/Development/automation/mac-dev-playbook && ansible-lint tasks/custom/ai-dock-folder.yml`
Expected: No errors about missing changed_when

**Step 3: Commit**

```bash
git add tasks/custom/ai-dock-folder.yml
git commit -m "style: add changed_when to dockutil command task

Properly handle idempotency by checking if the dock item already
exists before reporting as changed.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 5: Add `changed_when` to ps-remote-play.yml Install Task

**Files:**
- Modify: `/Users/michael/Development/automation/mac-dev-playbook/tasks/custom/ps-remote-play.yml:14-17`

**Step 1: Add `changed_when: true` to the installer command**

The installer command always changes the system when it runs. Make this explicit:

```yaml
- name: Install PS Remote Play.
  become: true
  command: installer -pkg /tmp/RemotePlayInstaller.pkg -target /
  changed_when: true
  when: not ps_remote_play_app.stat.exists
```

**Step 2: Run ansible-lint to verify**

Run: `cd /Users/michael/Development/automation/mac-dev-playbook && ansible-lint tasks/custom/ps-remote-play.yml`
Expected: No errors about missing changed_when

**Step 3: Commit**

```bash
git add tasks/custom/ps-remote-play.yml
git commit -m "style: add explicit changed_when to installer command

Explicitly mark the pkg installer as always changing the system
when it runs, satisfying ansible-lint requirements.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 6: Standardize Path Expansion - Create `user_home` Variable in default.config.yml

**Files:**
- Modify: `/Users/michael/Development/automation/mac-dev-playbook/default.config.yml:1-3`

**Step 1: Add a standardized home directory variable at the top of the config**

Add a comment and variable that all tasks can reference:

```yaml
---
# User home directory - used for path consistency across tasks
# Note: For tasks that need the literal path (not ~), use ansible_facts['env']['HOME']
# For tasks where ~ expansion works, you can use ~ directly

configure_dotfiles: true
```

Note: We will NOT add a user_home variable because:
1. `~` works in most Ansible modules via Python's `os.path.expanduser`
2. `ansible_facts['env']['HOME']` is needed for command modules and templates
3. Adding a variable would just be another way to do the same thing

Instead, we'll document the convention in the next task.

**Step 2: Skip this task**

After analysis, adding a variable doesn't improve consistency - it adds a third way to reference home. The codebase already has two valid patterns:
- `~` for module parameters (file, copy, stat, etc.)
- `ansible_facts['env']['HOME']` for command/shell modules

This is the correct approach. Skip to Task 7.

---

## Task 7: Standardize Path Expansion - Update dotfiles-init.yml

**Files:**
- Modify: `/Users/michael/Development/automation/mac-dev-playbook/tasks/custom/dotfiles-init.yml`

**Step 1: The `~` usage is appropriate here**

After analysis, the `~` usage in `dotfiles-init.yml` is correct because:
- The `file`, `stat`, `copy` modules expand `~` properly
- The `command` module with `chdir` and `creates` also expands `~`

No changes needed. The file correctly uses `~` for these Ansible module parameters.

**Step 2: Verify with ansible-lint**

Run: `cd /Users/michael/Development/automation/mac-dev-playbook && ansible-lint tasks/custom/dotfiles-init.yml`
Expected: No path-related errors

---

## Task 8: Standardize Path Expansion - Update ohmyzsh.yml

**Files:**
- Modify: `/Users/michael/Development/automation/mac-dev-playbook/tasks/custom/ohmyzsh.yml`

**Step 1: Verify `~` usage is appropriate**

The `~` usage in `ohmyzsh.yml` is correct because:
- The `stat` module expands `~` properly
- The `command` module with `creates` expands `~`
- The `file` module expands `~`
- The `debug` message is just informational

No changes needed.

**Step 2: Verify with ansible-lint**

Run: `cd /Users/michael/Development/automation/mac-dev-playbook && ansible-lint tasks/custom/ohmyzsh.yml`
Expected: No path-related errors

---

## Task 9: Document Path Expansion Convention in CLAUDE.md

**Files:**
- Modify: `/Users/michael/Development/automation/mac-dev-playbook/CLAUDE.md`

**Step 1: Add a style conventions section**

Add after the "Key Configuration Variables" section:

```markdown
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
```

**Step 2: Verify the file is valid markdown**

Run: `cat /Users/michael/Development/automation/mac-dev-playbook/CLAUDE.md | head -80`
Expected: Well-formatted markdown

**Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: add style conventions for paths, when clauses, and commands

Document the established patterns for:
- When to use ~ vs ansible_facts['env']['HOME']
- Quoting conventions in when clauses
- changed_when requirements for command tasks

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 10: Standardize Quoting in When Clauses - main.yml

**Files:**
- Modify: `/Users/michael/Development/automation/mac-dev-playbook/main.yml:23`

**Step 1: Fix inconsistent quoting in the when clause**

Change the quoted when clause to use the unquoted `is` test syntax:

```yaml
      when: "'/usr/bin/xcodebuild' is exists"
```

Should become:

```yaml
      when: '/usr/bin/xcodebuild' is exists
```

Note: The quotes around the entire expression are unnecessary when using `is exists` test.

**Step 2: Verify syntax**

Run: `cd /Users/michael/Development/automation/mac-dev-playbook && ansible-playbook main.yml --syntax-check`
Expected: "playbook: main.yml" with no errors

**Step 3: Run ansible-lint**

Run: `cd /Users/michael/Development/automation/mac-dev-playbook && ansible-lint main.yml`
Expected: No quoting-related warnings

**Step 4: Commit**

```bash
git add main.yml
git commit -m "style: remove unnecessary quotes from when clause

Use the cleaner unquoted form for the 'is exists' test.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 11: Extract Hardcoded Application Paths to Variables - ai-dock-folder.yml

**Files:**
- Modify: `/Users/michael/Development/automation/mac-dev-playbook/tasks/custom/ai-dock-folder.yml`

**Step 1: Add variables at the top of the task file using vars**

Convert hardcoded paths to a cleaner structure using task-level variables:

```yaml
---
- name: Set AI dock folder variables.
  set_fact:
    ai_apps_folder: "{{ ansible_facts['env']['HOME'] }}/Applications/AI"
    ai_apps:
      - name: Claude
        source: /Applications/Claude.app
      - name: LM Studio
        source: /Applications/LM Studio.app

- name: Create AI apps folder.
  file:
    path: "{{ ai_apps_folder }}"
    state: directory
    mode: "0755"

- name: Create alias to AI apps in AI folder.
  command: >
    osascript -e 'tell application "Finder" to make alias file to
    POSIX file "{{ item.source }}" at POSIX file "{{ ai_apps_folder }}"'
  args:
    creates: "{{ ai_apps_folder }}/{{ item.name }}"
  loop: "{{ ai_apps }}"
  loop_control:
    label: "{{ item.name }}"

- name: Add AI folder to dock with fan view.
  command: >
    dockutil --add "{{ ai_apps_folder }}"
    --view fan
    --display stack
    --sort name
    --replacing 'AI'
    --no-restart
  register: dockutil_result
  changed_when: "'already exists' not in dockutil_result.stderr | default('')"

- name: Display AI dock folder status.
  debug:
    msg: "AI folder added to dock with fan view at {{ ai_apps_folder }}"
```

**Step 2: Run ansible-lint**

Run: `cd /Users/michael/Development/automation/mac-dev-playbook && ansible-lint tasks/custom/ai-dock-folder.yml`
Expected: No errors

**Step 3: Run playbook syntax check**

Run: `cd /Users/michael/Development/automation/mac-dev-playbook && ansible-playbook main.yml --syntax-check`
Expected: "playbook: main.yml" with no errors

**Step 4: Commit**

```bash
git add tasks/custom/ai-dock-folder.yml
git commit -m "refactor: extract hardcoded paths to variables in ai-dock-folder

Use set_fact to define ai_apps_folder and ai_apps list, making it
easier to add or modify AI applications. Also consolidates the
alias creation into a single loop.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 12: Extract Hardcoded Path to Variable - ps-remote-play.yml

**Files:**
- Modify: `/Users/michael/Development/automation/mac-dev-playbook/tasks/custom/ps-remote-play.yml`

**Step 1: Add variables at the top of the task file**

```yaml
---
- name: Set PS Remote Play variables.
  set_fact:
    ps_remote_play_app_path: /Applications/RemotePlay.app
    ps_remote_play_installer_url: https://remoteplay.dl.playstation.net/remoteplay/module/mac/RemotePlayInstaller.pkg
    ps_remote_play_installer_path: /tmp/RemotePlayInstaller.pkg

- name: Check if PS Remote Play is already installed.
  stat:
    path: "{{ ps_remote_play_app_path }}"
  register: ps_remote_play_app

- name: Download PS Remote Play installer.
  get_url:
    url: "{{ ps_remote_play_installer_url }}"
    dest: "{{ ps_remote_play_installer_path }}"
    mode: "0644"
  when: not ps_remote_play_app.stat.exists

- name: Install PS Remote Play.
  become: true
  command: installer -pkg {{ ps_remote_play_installer_path }} -target /
  changed_when: true
  when: not ps_remote_play_app.stat.exists

- name: Clean up PS Remote Play installer.
  file:
    path: "{{ ps_remote_play_installer_path }}"
    state: absent
  when: not ps_remote_play_app.stat.exists

- name: Display PS Remote Play installation status.
  debug:
    msg: "PS Remote Play is installed at {{ ps_remote_play_app_path }}"
```

Note: Also removed the tautological `when` condition on the final debug task.

**Step 2: Run ansible-lint**

Run: `cd /Users/michael/Development/automation/mac-dev-playbook && ansible-lint tasks/custom/ps-remote-play.yml`
Expected: No errors

**Step 3: Commit**

```bash
git add tasks/custom/ps-remote-play.yml
git commit -m "refactor: extract hardcoded paths to variables in ps-remote-play

Use set_fact to define paths and URLs for easier maintenance.
Also removed tautological when condition on debug task.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Task 13: Final Linting Verification

**Files:**
- All modified files

**Step 1: Run yamllint on entire project**

Run: `cd /Users/michael/Development/automation/mac-dev-playbook && yamllint .`
Expected: No errors (warnings about line length are acceptable)

**Step 2: Run ansible-lint on entire project**

Run: `cd /Users/michael/Development/automation/mac-dev-playbook && ansible-lint`
Expected: No errors related to the changes made

**Step 3: Run full syntax check**

Run: `cd /Users/michael/Development/automation/mac-dev-playbook && ansible-playbook main.yml --syntax-check`
Expected: "playbook: main.yml" with no errors

**Step 4: Create summary commit if any fixes needed**

If any lint issues were found and fixed:
```bash
git add -A
git commit -m "style: fix remaining lint issues from style cleanup

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

---

## Summary of Changes

| File | Changes |
|------|---------|
| `default.config.yml` | Add missing `mas_installed_app_ids` default |
| `tasks/terminal.yml` | Remove outdated Yosemite TODO |
| `tasks/osx.yml` | Remove outdated sudo TODO |
| `tasks/custom/ai-dock-folder.yml` | Add `changed_when`, extract paths to variables, consolidate loops |
| `tasks/custom/ps-remote-play.yml` | Add `changed_when`, extract paths to variables, fix tautological when |
| `main.yml` | Standardize when clause quoting |
| `CLAUDE.md` | Document style conventions |

## Files NOT Changed (and why)

| File | Reason |
|------|--------|
| `tasks/custom/dotfiles-init.yml` | `~` usage is correct for the modules used |
| `tasks/custom/ohmyzsh.yml` | `~` usage is correct for the modules used |
| `tasks/extra-packages.yml` | `~` usage in default filter is appropriate |
| `default.config.yml` paths | `~` is the standard for user-configurable paths |
