# Requirements: Reconcile System State & Clawdbot Dependencies

**Date:** 2026-01-29
**Target System:** `mac-dev-playbook` / `config.yml`
**Context:** The automation configuration has drifted from the physical machine state. Critical dependencies for the AI agent (Clawdbot) are missing from the configuration, posing a risk to agent continuity during a rebuild.

## 1. Clawdbot Dependencies
The configuration MUST explicitly include the binaries required for the active AI agent's skills.
- **Requirement 1.1:** Add `ffmpeg` to `homebrew_installed_packages`.
- **Requirement 1.2:** Add `memo` (Apple Notes CLI) to `homebrew_installed_packages`.
- **Requirement 1.3:** Add `remindctl` (Apple Reminders CLI) to `homebrew_installed_packages`.
- **Requirement 1.4:** Add `peekaboo` (Screen capture) to `homebrew_installed_packages`.
- **Requirement 1.5:** Add `summarize` (Text extraction) to `homebrew_installed_packages`.
- **Requirement 1.6:** Add `mactop` to `homebrew_installed_packages`.

## 2. Package Categorization Corrections
The configuration MUST correctly categorize packages between Formulae (CLI) and Casks (GUI).
- **Requirement 2.1:** Move `ollama-app` from `homebrew_installed_packages` (Formulae) to `homebrew_cask_apps` (Casks).
  - *Constraint:* `ollama` (CLI) must remain in `homebrew_installed_packages`.

## 3. System Tooling Parity
The configuration MUST include system utilities that are currently installed and necessary for playbook operations.
- **Requirement 3.1:** Add `mas` (Mac App Store CLI) to `homebrew_installed_packages`.
- **Requirement 3.2:** Add `dockutil` to `homebrew_installed_packages`.
- **Requirement 3.3:** Add `openai-whisper` to `homebrew_installed_packages`.

## 4. Acceptance Criteria
- Running `ansible-playbook --check` yields no syntax errors.
- The `homebrew_installed_packages` list contains all items from Section 1 and 3.
- The `homebrew_cask_apps` list contains `ollama-app`.
