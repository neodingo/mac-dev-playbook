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

# Install Rosetta 2 (needed for Intel apps like PS Remote Play)
echo "==> Checking for Rosetta 2..."
if ! /usr/bin/pgrep -q oahd; then
    echo "    Installing Rosetta 2..."
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license
else
    echo "    Rosetta 2 already installed."
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

# Install mas (Mac App Store CLI) for MAS app installation
echo "==> Checking for mas (Mac App Store CLI)..."
if ! brew list mas &>/dev/null; then
    echo "    Installing mas..."
    brew install mas
else
    echo "    mas already installed."
fi

# Determine which Python to use (prefer Homebrew)
if [[ -x "$(brew --prefix)/bin/python3" ]]; then
    PYTHON_BIN="$(brew --prefix)/bin/python3"
elif [[ -x "$(brew --prefix python@3.12)/bin/python3" ]]; then
    PYTHON_BIN="$(brew --prefix python@3.12)/bin/python3"
elif [[ -x "$(brew --prefix python@3.11)/bin/python3" ]]; then
    PYTHON_BIN="$(brew --prefix python@3.11)/bin/python3"
else
    PYTHON_BIN="python3"
fi
echo "    Using Python: ${PYTHON_BIN}"

# Create virtual environment
echo "==> Setting up Python virtual environment..."
if [[ ! -d "${VENV_DIR}" ]]; then
    echo "    Creating virtual environment at ${VENV_DIR}..."
    "${PYTHON_BIN}" -m venv "${VENV_DIR}"
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
echo "========================================================================"
echo "  IMPORTANT: Before running the playbook, please ensure you are"
echo "  logged in to the Mac App Store to install apps like Xcode,"
echo "  Tailscale, etc."
echo ""
echo "  Open the App Store app and sign in with your Apple ID if needed."
echo "========================================================================"
echo ""
echo "To run the playbook:"
echo "  ./run.sh"
echo ""
echo "Or manually:"
echo "  source .venv/bin/activate"
echo "  ansible-playbook main.yml -K"
