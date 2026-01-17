# Fix Medium Priority Ansible Issues Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix three medium priority issues in the Ansible playbook: deprecated loop syntax, duplicate task names, and invalid JSON template.

**Architecture:** Each issue is independent and can be fixed in isolation. We address them in order: deprecated `with_items` to `loop` migration, renaming duplicate tasks for clarity, and fixing trailing comma in JSON template.

**Tech Stack:** Ansible YAML tasks, Jinja2 templates

---

## Task 1: Migrate deprecated `with_items` to `loop` in terminal.yml

**Files:**
- Modify: `/Users/michael/Development/automation/mac-dev-playbook/tasks/terminal.yml:24-28`

**Context:** The task "Ensure custom Terminal profile is set as default" uses deprecated `with_items` syntax. Other task files (e.g., `extra-packages.yml`) use the modern `loop` keyword. This migration maintains consistency and follows Ansible best practices.

**Step 1: Verify current state**

Run:
```bash
grep -n "with_items" /Users/michael/Development/automation/mac-dev-playbook/tasks/terminal.yml
```

Expected output: Line 25 showing `with_items:` usage.

**Step 2: Edit terminal.yml to replace with_items with loop**

Change line 25 from:
```yaml
  with_items:
```

To:
```yaml
  loop:
```

The full task block should become:
```yaml
- name: Ensure custom Terminal profile is set as default.
  command: "{{ item }}"
  loop:
    - defaults write com.apple.terminal 'Default Window Settings' -string JJG-Term
    - defaults write com.apple.terminal 'Startup Window Settings' -string JJG-Term
  changed_when: false
  when: "'JJG-Term' not in terminal_theme.stdout"
```

**Step 3: Validate the change**

Run:
```bash
ansible-playbook /Users/michael/Development/automation/mac-dev-playbook/main.yml --syntax-check
```

Expected: Syntax check passes with no errors.

**Step 4: Run ansible-lint to verify**

Run:
```bash
cd /Users/michael/Development/automation/mac-dev-playbook && ansible-lint tasks/terminal.yml
```

Expected: No errors related to deprecated loop syntax.

**Step 5: Commit the change**

Run:
```bash
cd /Users/michael/Development/automation/mac-dev-playbook && git add tasks/terminal.yml && git commit -m "refactor(terminal): migrate deprecated with_items to loop syntax"
```

---

## Task 2: Rename duplicate task names in terminal.yml

**Files:**
- Modify: `/Users/michael/Development/automation/mac-dev-playbook/tasks/terminal.yml:10-20`

**Context:** Two tasks on lines 10-15 and 17-20 both have the name "Ensure custom Terminal profile is added." This makes debugging and playbook output confusing. Each task should have a unique, descriptive name.

**Step 1: Verify current state**

Run:
```bash
grep -n "Ensure custom Terminal profile is added" /Users/michael/Development/automation/mac-dev-playbook/tasks/terminal.yml
```

Expected output: Two lines (10 and 17) with identical names.

**Step 2: Rename first task (copy operation)**

Change line 10 from:
```yaml
- name: Ensure custom Terminal profile is added.
```

To:
```yaml
- name: Copy custom Terminal profile to temp directory.
```

**Step 3: Rename second task (open operation)**

Change line 17 from:
```yaml
- name: Ensure custom Terminal profile is added.
```

To:
```yaml
- name: Import custom Terminal profile via open command.
```

**Step 4: Validate the changes**

Run:
```bash
ansible-playbook /Users/michael/Development/automation/mac-dev-playbook/main.yml --syntax-check
```

Expected: Syntax check passes with no errors.

**Step 5: Run ansible-lint to verify**

Run:
```bash
cd /Users/michael/Development/automation/mac-dev-playbook && ansible-lint tasks/terminal.yml
```

Expected: No errors related to duplicate task names.

**Step 6: Commit the change**

Run:
```bash
cd /Users/michael/Development/automation/mac-dev-playbook && git add tasks/terminal.yml && git commit -m "refactor(terminal): rename duplicate task names for clarity"
```

---

## Task 3: Fix trailing comma in Sublime Text JSON template

**Files:**
- Modify: `/Users/michael/Development/automation/mac-dev-playbook/templates/Package_Control.sublime-settings.j2:12-13`

**Context:** The JSON template has a trailing comma after the `installed_packages` array closing bracket on line 12, which is invalid JSON syntax. The template uses Jinja2 to handle commas between array items correctly, but there's an errant comma before the final closing brace.

Current template structure:
```json
{
	"auto_upgrade_last_run": null,
	"bootstrapped": true,
	"in_process_packages": [],
	"installed_packages": [
{% for package in sublime_package_control %}
  "{{ package }}"{% if not loop.last %},{% endif %}
{% endfor %}
],    <-- trailing comma here is invalid
}
```

**Step 1: Verify current state**

Run:
```bash
tail -5 /Users/michael/Development/automation/mac-dev-playbook/templates/Package_Control.sublime-settings.j2
```

Expected: Shows `],` followed by `}` on the last line.

**Step 2: Edit the template to remove trailing comma**

Change line 12 from:
```
],
```

To:
```
]
```

The corrected template ending should be:
```
{% for package in sublime_package_control %}
  "{{ package }}"{% if not loop.last %},{% endif %}
{% endfor %}
]
}
```

**Step 3: Verify the fix produces valid JSON**

Run a test render (assuming you have a test config or can create a temporary one):
```bash
cd /Users/michael/Development/automation/mac-dev-playbook && python3 -c "
from jinja2 import Template
template = open('templates/Package_Control.sublime-settings.j2').read()
t = Template(template)
result = t.render(sublime_package_control=['Package1', 'Package2'])
import json
json.loads(result)
print('Valid JSON!')
"
```

Expected: Prints "Valid JSON!" without errors.

**Step 4: Validate playbook syntax**

Run:
```bash
ansible-playbook /Users/michael/Development/automation/mac-dev-playbook/main.yml --syntax-check
```

Expected: Syntax check passes with no errors.

**Step 5: Commit the change**

Run:
```bash
cd /Users/michael/Development/automation/mac-dev-playbook && git add templates/Package_Control.sublime-settings.j2 && git commit -m "fix(sublime-text): remove trailing comma from JSON template"
```

---

## Final Verification

**Step 1: Run full lint suite**

Run:
```bash
cd /Users/michael/Development/automation/mac-dev-playbook && yamllint . && ansible-lint
```

Expected: No new errors introduced by these changes.

**Step 2: Run syntax check on main playbook**

Run:
```bash
ansible-playbook /Users/michael/Development/automation/mac-dev-playbook/main.yml --syntax-check
```

Expected: Playbook syntax OK.

---

## Summary of Changes

| File | Issue | Fix |
|------|-------|-----|
| `tasks/terminal.yml:25` | Deprecated `with_items` syntax | Changed to `loop` |
| `tasks/terminal.yml:10` | Duplicate task name | Renamed to "Copy custom Terminal profile to temp directory." |
| `tasks/terminal.yml:17` | Duplicate task name | Renamed to "Import custom Terminal profile via open command." |
| `templates/Package_Control.sublime-settings.j2:12` | Trailing comma in JSON | Removed comma after `]` |
