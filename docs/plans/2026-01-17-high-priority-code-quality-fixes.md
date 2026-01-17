# High Priority Code Quality Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix three high-priority code quality issues: duplicate Xcode license logic, unused variables, and a tautological condition.

**Architecture:** This plan makes minimal, targeted changes to existing Ansible task files. Each fix is independent and can be committed separately. The consolidated Xcode license logic will live in the post-provision task file since it needs to handle both pre-existing Xcode installations and Xcode installed during the playbook run via MAS.

**Tech Stack:** Ansible YAML task files

---

## Task 1: Remove Unused `sed_path` Variable from `sudoers.yml`

**Files:**
- Modify: `tasks/sudoers.yml` (lines 1-12)

**Context:** The `sed_path` variable is defined by looking up the path to `sed`, but it is never used anywhere in the task file. This is dead code that should be removed.

**Step 1: Read the current file to confirm understanding**

Verify that lines 1-12 define the `sed_path` variable and it is not used in the remainder of the file.

Current content to remove:
```yaml
# If the user installs GNU sed through homebrew the path is different.
- name: Register path to sed.
  command: which sed
  register: sed_which_result
  changed_when: false
  when: sed_path is undefined

- name: Define sed_path variable.
  set_fact:
    sed_path: "{{ sed_which_result.stdout }}"
  when: sed_path is undefined
```

**Step 2: Edit the file to remove dead code**

Edit `tasks/sudoers.yml` to remove lines 1-12 (the comment and both tasks related to `sed_path`).

The file should become:
```yaml
---
# Sudoers configuration.
- name: Copy sudoers configuration into place.
  copy:
    content: "{{ sudoers_custom_config }}"
    dest: /private/etc/sudoers.d/custom
    mode: 0440
    validate: 'visudo -cf %s'
  become: true
```

**Step 3: Verify syntax**

Run: `ansible-playbook /Users/michael/Development/automation/mac-dev-playbook/main.yml --syntax-check`

Expected: No syntax errors

**Step 4: Run ansible-lint**

Run: `ansible-lint /Users/michael/Development/automation/mac-dev-playbook/tasks/sudoers.yml`

Expected: No errors (warnings are acceptable)

**Step 5: Commit**

```bash
git add tasks/sudoers.yml
git commit -m "fix(sudoers): remove unused sed_path variable

The sed_path variable was defined but never used anywhere in the task
file. This removes the dead code.
"
```

---

## Task 2: Remove Tautological Condition in `ps-remote-play.yml`

**Files:**
- Modify: `tasks/custom/ps-remote-play.yml` (line 28)

**Context:** The final debug task has a `when` clause that is always true: `when: ps_remote_play_app.stat.exists or not ps_remote_play_app.stat.exists`. This condition evaluates to true regardless of the value, making it redundant. The task should always run to display the installation status.

**Step 1: Read the current file to confirm understanding**

Verify line 28 contains the tautological condition.

Current code:
```yaml
- name: Display PS Remote Play installation status.
  debug:
    msg: "PS Remote Play is installed at /Applications/RemotePlay.app"
  when: ps_remote_play_app.stat.exists or not ps_remote_play_app.stat.exists
```

**Step 2: Edit the file to remove the redundant condition**

Edit `tasks/custom/ps-remote-play.yml` to remove the `when` clause entirely from the debug task (line 28).

The task should become:
```yaml
- name: Display PS Remote Play installation status.
  debug:
    msg: "PS Remote Play is installed at /Applications/RemotePlay.app"
```

**Step 3: Verify syntax**

Run: `ansible-playbook /Users/michael/Development/automation/mac-dev-playbook/main.yml --syntax-check`

Expected: No syntax errors

**Step 4: Run ansible-lint**

Run: `ansible-lint /Users/michael/Development/automation/mac-dev-playbook/tasks/custom/ps-remote-play.yml`

Expected: No errors (warnings are acceptable)

**Step 5: Commit**

```bash
git add tasks/custom/ps-remote-play.yml
git commit -m "fix(ps-remote-play): remove tautological when condition

The debug task had a condition that was always true:
'when: x or not x'. Removed the redundant clause since the task
should always display the installation status.
"
```

---

## Task 3: Consolidate Duplicate Xcode License Logic

**Files:**
- Modify: `main.yml` (lines 15-24)
- Modify: `tasks/custom/xcode-license.yml` (entire file)

**Context:** Xcode license acceptance is handled in two places:
1. `main.yml` pre_tasks - checks `/usr/bin/xcodebuild` exists
2. `tasks/custom/xcode-license.yml` - checks `/Applications/Xcode.app` exists

The post-provision task file has slightly more comprehensive error handling (checks for both 'already agreed' and 'already accepted' in stderr). The consolidated logic should:
- Live in `tasks/custom/xcode-license.yml` (runs as post-provision task)
- Check both the xcodebuild binary AND Xcode.app (belt and suspenders)
- Use the more comprehensive error pattern matching

**Step 1: Read both files to confirm current state**

Verify the differences between the two implementations:
- `main.yml` checks: `/usr/bin/xcodebuild` exists, handles 'already agreed' error
- `xcode-license.yml` checks: `/Applications/Xcode.app` exists, handles 'already agreed' AND 'already accepted' errors

**Step 2: Remove Xcode license task from `main.yml`**

Edit `main.yml` to remove lines 15-24 (the "Accept Xcode license" pre_task).

The pre_tasks section should become:
```yaml
  pre_tasks:
    - name: Include playbook configuration.
      include_vars: "{{ item }}"
      with_fileglob:
        - "{{ playbook_dir }}/config.yml"
      tags: ['always']
```

**Step 3: Update `tasks/custom/xcode-license.yml` with comprehensive check**

Edit `tasks/custom/xcode-license.yml` to check for xcodebuild binary (more reliable than app path) while keeping the comprehensive error handling.

The file should become:
```yaml
---
# Accept Xcode license if Xcode is installed.
# This runs as a post-provision task to catch Xcode installed during playbook run.

- name: Check if xcodebuild is available.
  stat:
    path: /usr/bin/xcodebuild
  register: xcodebuild_binary

- name: Accept Xcode license.
  command: xcodebuild -license accept
  become: true
  register: xcode_license_result
  changed_when: "'license accepted' in xcode_license_result.stdout | default('')"
  failed_when: >
    xcode_license_result.rc != 0
    and 'already agreed' not in (xcode_license_result.stderr | default(''))
    and 'already accepted' not in (xcode_license_result.stderr | default(''))
  when: xcodebuild_binary.stat.exists

- name: Display Xcode license status.
  debug:
    msg: "Xcode license has been accepted."
  when: xcodebuild_binary.stat.exists and xcode_license_result.changed | default(false)
```

**Step 4: Verify syntax**

Run: `ansible-playbook /Users/michael/Development/automation/mac-dev-playbook/main.yml --syntax-check`

Expected: No syntax errors

**Step 5: Run ansible-lint on both files**

Run: `ansible-lint /Users/michael/Development/automation/mac-dev-playbook/main.yml /Users/michael/Development/automation/mac-dev-playbook/tasks/custom/xcode-license.yml`

Expected: No errors (warnings are acceptable)

**Step 6: Run yamllint**

Run: `yamllint /Users/michael/Development/automation/mac-dev-playbook/main.yml /Users/michael/Development/automation/mac-dev-playbook/tasks/custom/xcode-license.yml`

Expected: No errors (warnings are acceptable)

**Step 7: Commit**

```bash
git add main.yml tasks/custom/xcode-license.yml
git commit -m "refactor(xcode): consolidate license acceptance to post-provision task

Previously, Xcode license acceptance was duplicated in main.yml pre_tasks
and tasks/custom/xcode-license.yml with slightly different error handling.

Consolidated to single location in xcode-license.yml which:
- Runs as post-provision task (catches Xcode installed via MAS)
- Checks xcodebuild binary existence (more reliable)
- Handles both 'already agreed' and 'already accepted' error messages
"
```

---

## Summary

| Task | File(s) | Change |
|------|---------|--------|
| 1 | `tasks/sudoers.yml` | Remove unused `sed_path` variable (dead code) |
| 2 | `tasks/custom/ps-remote-play.yml` | Remove tautological `when` condition |
| 3 | `main.yml`, `tasks/custom/xcode-license.yml` | Consolidate duplicate Xcode license logic |

**Total estimated time:** 15-20 minutes

**Testing approach:** Each change is validated with `ansible-playbook --syntax-check` and `ansible-lint` before committing. Full playbook testing would require a macOS environment with appropriate privileges.
