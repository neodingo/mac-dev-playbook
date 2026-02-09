#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

# ---------- Defaults ----------
DRY_RUN=false
SYNTAX_CHECK=false
VERBOSE=false
SKIP_GALAXY=false
TAGS=""

# ---------- Usage ----------
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Wrapper script for running the mac-dev-playbook Ansible playbook.
Manages a Python venv, installs Ansible, and runs the playbook.

Options:
  -n, --dry-run        Run playbook in check mode (--check)
  -t, --tags <tags>    Run only the specified tags (comma-separated)
  -s, --syntax-check   Run syntax check only, don't execute
  -v, --verbose        Run playbook with verbose output (-vvv)
      --skip-galaxy    Skip the ansible-galaxy install step
  -h, --help           Show this help message

Examples:
  ./run.sh                          # Full run, prompts for sudo password
  ./run.sh --tags "homebrew,dock"   # Run only homebrew and dock tasks
  ./run.sh --dry-run                # Check mode, no changes made
  ./run.sh --syntax-check           # Validate playbook syntax
EOF
  exit 0
}

# ---------- Argument parsing ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -t|--tags)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --tags requires a value."
        exit 1
      fi
      TAGS="$2"
      shift 2
      ;;
    -s|--syntax-check)
      SYNTAX_CHECK=true
      shift
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    --skip-galaxy)
      SKIP_GALAXY=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1"
      echo "Run '$(basename "$0") --help' for usage."
      exit 1
      ;;
  esac
done

# ---------- Virtual environment ----------
if [[ ! -d ".venv" ]]; then
  echo "Setting up virtual environment..."
  python3 -m venv .venv
fi

echo "Activating virtual environment..."
# shellcheck disable=SC1091
source .venv/bin/activate

if ! .venv/bin/python -m pip show ansible &>/dev/null; then
  echo "Installing/upgrading pip..."
  pip install --upgrade pip

  echo "Installing Ansible..."
  pip install ansible
else
  echo "Ansible already installed in venv."
fi

# ---------- Galaxy roles/collections ----------
if [[ "$SKIP_GALAXY" == false ]]; then
  if [[ ! -d "roles/geerlingguy.mac" ]]; then
    echo "Installing Ansible Galaxy roles and collections..."
    ansible-galaxy install -r requirements.yml
  else
    echo "Galaxy roles already installed (use --skip-galaxy to skip this check)."
  fi
else
  echo "Skipping ansible-galaxy install."
fi

# ---------- Build ansible-playbook command ----------
CMD=(ansible-playbook main.yml)

if [[ "$SYNTAX_CHECK" == true ]]; then
  CMD+=(--syntax-check)
  echo "Running syntax check..."
  "${CMD[@]}"
  echo "Syntax check passed."
  exit 0
fi

# Always ask for become password on a real run.
CMD+=(-K)

if [[ "$DRY_RUN" == true ]]; then
  CMD+=(--check)
  echo "Dry-run mode enabled (--check)."
fi

if [[ -n "$TAGS" ]]; then
  CMD+=(--tags "$TAGS")
  echo "Running with tags: $TAGS"
fi

if [[ "$VERBOSE" == true ]]; then
  CMD+=(-vvv)
fi

echo "Running: ${CMD[*]}"
"${CMD[@]}"
