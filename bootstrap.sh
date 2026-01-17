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

    echo "    Waiting for installation to complete (this may take several minutes)..."
    echo "    Please complete the installation dialog if prompted."

    # Wait for the installation to complete
    until xcode-select -p &>/dev/null; do
        sleep 5
    done
    echo "    Xcode Command Line Tools installed successfully."
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

# Install Xcode from Mac App Store (required for many Homebrew packages)
echo "==> Checking for Xcode..."
if [[ ! -d "/Applications/Xcode.app" ]]; then
    echo "    Xcode is required for many Homebrew packages to build correctly."
    echo "    Installing Xcode from Mac App Store..."
    echo "    This may take a while (Xcode is ~7GB)..."
    echo ""
    echo "    NOTE: You must be signed in to the App Store for this to work."
    echo "    If installation fails, open App Store, sign in, and re-run this script."
    echo ""
    if mas install 497799835; then
        echo "    Xcode installed successfully."
    else
        echo -e "    \033[1;33mWarning: Xcode installation failed.\033[0m"
        echo "    This usually means you're not signed in to the App Store."
        echo "    Please open App Store, sign in, then re-run this script."
        echo ""
        read -p "    Continue without Xcode? (some packages may fail) [y/N] " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "    Aborted."
            exit 1
        fi
    fi
else
    echo "    Xcode already installed."
fi

# Accept Xcode license (required before xcodebuild can be used)
if [[ -d "/Applications/Xcode.app" ]]; then
    echo "==> Checking Xcode license..."
    # Select the Xcode.app as the active developer directory
    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer 2>/dev/null || true
    if ! /usr/bin/xcodebuild -license check &>/dev/null 2>&1; then
        echo "    Accepting Xcode license (requires sudo)..."
        sudo xcodebuild -license accept
        echo "    Xcode license accepted."
    else
        echo "    Xcode license already accepted."
    fi
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
echo "To run the playbook:"
echo "  ./run.sh"
echo ""
echo "Or manually:"
echo "  source .venv/bin/activate"
echo "  ansible-playbook main.yml -K"
