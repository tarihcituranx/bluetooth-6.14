#!/bin/bash
# ================================================================
#  Mercusys MA530 Bluetooth — Kernel 6.17+ Fix
#  One-click installer
#  Usage: bash install.en.sh
# ================================================================

set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${BOLD}${CYAN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Mercusys MA530 — Kernel 6.17+ Bluetooth Fix        ║"
echo "╚══════════════════════════════════════════════════════╝${RESET}"
echo ""

# Kernel info
KERNEL=$(uname -r)
echo -e "${CYAN}[i]${RESET} Kernel: $KERNEL"

# Check adapter
if ! lsusb | grep -q "2c4e:0115"; then
    echo -e "${RED}[✘]${RESET} Mercusys MA530 adapter not found! Is it plugged in?"
    exit 1
fi
echo -e "${GREEN}[✔]${RESET} MA530 adapter detected"

# Dependencies
echo -e "${CYAN}[i]${RESET} Installing git and dkms..."
sudo apt install git dkms -y -q

# Remove old install if exists
if sudo dkms status | grep -q "btusb/4.3"; then
    echo -e "${CYAN}[i]${RESET} Removing old btusb/4.3..."
    sudo dkms remove btusb/4.3 --all
fi

# Remove old clone if exists
if [ -d ~/bluetooth-6.14 ]; then
    echo -e "${CYAN}[i]${RESET} Removing existing bluetooth-6.14 directory..."
    rm -rf ~/bluetooth-6.14
fi

# Clone driver
echo -e "${CYAN}[i]${RESET} Downloading driver..."
cd ~
git clone https://github.com/jeremyb31/bluetooth-6.14.git -q
cd bluetooth-6.14

# Patch for kernel 6.17
echo -e "${CYAN}[i]${RESET} Patching btusb.c for kernel 6.17 compatibility..."
python3 -c "
import re
with open('btusb.c', 'r') as f:
    content = f.read()
content = re.sub(r'set_bit\((HCI_QUIRK_\w+),\s*&hdev->quirks\)', r'hci_set_quirk(hdev, \1)', content)
content = re.sub(r'clear_bit\((HCI_QUIRK_\w+),\s*&hdev->quirks\)', r'hci_clear_quirk(hdev, \1)', content)
content = re.sub(r'test_bit\((HCI_QUIRK_\w+),\s*&hdev->quirks\)', r'hci_test_quirk(hdev, \1)', content)
with open('btusb.c', 'w') as f:
    f.write(content)
"

REMAINING=$(grep -c "hdev->quirks" btusb.c || true)
if [ "$REMAINING" -gt 0 ]; then
    echo -e "${RED}[✘]${RESET} Failed to patch btusb.c! ($REMAINING lines remaining)"
    exit 1
fi
echo -e "${GREEN}[✔]${RESET} btusb.c patched successfully"

# Install with DKMS
echo -e "${CYAN}[i]${RESET} Building and installing with DKMS..."
sudo dkms add ~/bluetooth-6.14
sudo dkms install btusb/4.3

echo ""
echo -e "${GREEN}${BOLD}[✔] Installation complete!${RESET}"
echo -e "${CYAN}[i]${RESET} Please reboot your system: ${BOLD}sudo reboot${RESET}"
