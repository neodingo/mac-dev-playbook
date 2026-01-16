#!/bin/bash
#
# Run script for mac-dev-playbook
# Performs a dry run, then asks user to confirm before executing
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/.venv"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==> Mac Dev Playbook${NC}"
echo ""

# Check if bootstrap has been run
if [[ ! -d "${VENV_DIR}" ]]; then
    echo -e "${RED}Error: Virtual environment not found.${NC}"
    echo "Please run ./bootstrap.sh first."
    exit 1
fi

# Activate virtual environment
source "${VENV_DIR}/bin/activate"

# Check if ansible is available
if ! command -v ansible-playbook &>/dev/null; then
    echo -e "${RED}Error: Ansible not found in virtual environment.${NC}"
    echo "Please run ./bootstrap.sh first."
    exit 1
fi

cd "${SCRIPT_DIR}"

# Get sudo password upfront
echo -e "${YELLOW}==> Sudo password required for playbook execution${NC}"
echo "Please enter your password (it will be used for both dry-run and execution):"
read -s BECOME_PASS
echo ""

# Verify password is correct
if ! echo "${BECOME_PASS}" | sudo -S -v &>/dev/null; then
    echo -e "${RED}Error: Incorrect password.${NC}"
    exit 1
fi

# Run dry run
echo -e "${BLUE}==> Running dry-run (check mode)...${NC}"
echo ""

# Run ansible with the password, allowing some failures (like npm not existing yet)
set +e
echo "${BECOME_PASS}" | ansible-playbook main.yml --check --become-password-file=/dev/stdin 2>&1 | tee /tmp/ansible-dry-run.log
DRY_RUN_EXIT=$?
set -e

echo ""

# Check for critical failures (ignore expected ones like npm/pip not found)
CRITICAL_FAILURES=$(grep -c "fatal:" /tmp/ansible-dry-run.log 2>/dev/null || echo "0")
EXPECTED_FAILURES=$(grep -c "Failed to find required executable" /tmp/ansible-dry-run.log 2>/dev/null || echo "0")
ACTUAL_FAILURES=$((CRITICAL_FAILURES - EXPECTED_FAILURES))

if [[ ${ACTUAL_FAILURES} -gt 0 ]]; then
    echo -e "${RED}==> Dry-run completed with ${ACTUAL_FAILURES} unexpected failure(s).${NC}"
    echo "Review the output above for details."
    echo ""
fi

if [[ ${EXPECTED_FAILURES} -gt 0 ]]; then
    echo -e "${YELLOW}==> Note: ${EXPECTED_FAILURES} expected failure(s) due to missing executables (npm/pip/gem).${NC}"
    echo "   These will resolve when packages are actually installed."
    echo ""
fi

# Show summary
echo -e "${GREEN}==> Dry-run complete.${NC}"
echo ""

# Ask user to proceed
echo -e "${YELLOW}Would you like to proceed with the actual installation?${NC}"
echo "This will install and configure software on your system."
echo ""
read -p "Proceed? [y/N] " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "Aborted. No changes were made."
    exit 0
fi

echo ""
echo -e "${BLUE}==> Running playbook...${NC}"
echo ""

# Run the actual playbook
echo "${BECOME_PASS}" | ansible-playbook main.yml --become-password-file=/dev/stdin

echo ""
echo -e "${GREEN}==> Playbook complete!${NC}"
echo ""
echo "You may need to restart your terminal or log out/in for all changes to take effect."
