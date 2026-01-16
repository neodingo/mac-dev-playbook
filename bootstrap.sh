#!/bin/bash
#
# Bootstrap script for mac-dev-playbook
# Installs all dependencies needed to run the Ansible playbook
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/.venv"

echo "==> Mac Dev Playbook Bootstrap"
echo ""

# Check for Xcode Command Line Tools
echo "==> Checking for Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    echo "    Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "    Please complete the installation dialog, then re-run this script."
    exit 1
else
    echo "    Xcode Command Line Tools already installed."
fi

# Check for Homebrew
echo "==> Checking for Homebrew..."
if ! command -v brew &>/dev/null; then
    echo "    Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "    Homebrew already installed."
fi

# Ensure Homebrew is in PATH
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install Python if not available via Homebrew
echo "==> Checking for Python..."
if ! brew list python@3.12 &>/dev/null && ! brew list python@3.11 &>/dev/null && ! brew list python &>/dev/null; then
    echo "    Installing Python via Homebrew..."
    brew install python
else
    echo "    Python already installed."
fi

# Create virtual environment
echo "==> Setting up Python virtual environment..."
if [[ ! -d "${VENV_DIR}" ]]; then
    echo "    Creating virtual environment at ${VENV_DIR}..."
    python3 -m venv "${VENV_DIR}"
else
    echo "    Virtual environment already exists."
fi

# Activate virtual environment
source "${VENV_DIR}/bin/activate"

# Upgrade pip
echo "==> Upgrading pip..."
pip install --upgrade pip --quiet

# Install Ansible
echo "==> Installing Ansible..."
pip install ansible --quiet
echo "    Ansible $(ansible --version | head -1 | awk '{print $NF}') installed."

# Install Ansible Galaxy requirements
echo "==> Installing Ansible Galaxy requirements..."
cd "${SCRIPT_DIR}"
ansible-galaxy install -r requirements.yml

echo ""
echo "==> Bootstrap complete!"
echo ""
echo "To run the playbook:"
echo "  ./run.sh"
echo ""
echo "Or manually:"
echo "  source .venv/bin/activate"
echo "  ansible-playbook main.yml -K"
