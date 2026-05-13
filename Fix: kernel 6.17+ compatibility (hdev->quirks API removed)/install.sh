#!/bin/bash
# ================================================================
#  Mercusys MA530 Bluetooth — Kernel 6.17+ Fix
#  Tek tıkla kurulum scripti
#  Kullanım: bash install.sh
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

# Kernel kontrolü
KERNEL=$(uname -r)
echo -e "${CYAN}[i]${RESET} Kernel: $KERNEL"

# Adaptör kontrolü
if ! lsusb | grep -q "2c4e:0115"; then
    echo -e "${RED}[✘]${RESET} Mercusys MA530 adaptörü bulunamadı! USB bağlı mı?"
    exit 1
fi
echo -e "${GREEN}[✔]${RESET} MA530 adaptörü tespit edildi"

# Bağımlılıklar
echo -e "${CYAN}[i]${RESET} git ve dkms kuruluyor..."
sudo apt install git dkms -y -q

# Eski kurulum varsa temizle
if sudo dkms status | grep -q "btusb/4.3"; then
    echo -e "${CYAN}[i]${RESET} Eski btusb/4.3 kaldırılıyor..."
    sudo dkms remove btusb/4.3 --all
fi

# Repo indir
if [ -d ~/bluetooth-6.14 ]; then
    echo -e "${CYAN}[i]${RESET} Mevcut bluetooth-6.14 klasörü siliniyor..."
    rm -rf ~/bluetooth-6.14
fi

echo -e "${CYAN}[i]${RESET} Sürücü indiriliyor..."
cd ~
git clone https://github.com/jeremyb31/bluetooth-6.14.git -q
cd bluetooth-6.14

# Kernel 6.17 uyumu
echo -e "${CYAN}[i]${RESET} btusb.c kernel 6.17 için güncelleniyor..."
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
    echo -e "${RED}[✘]${RESET} btusb.c düzeltilemedi! ($REMAINING satır kaldı)"
    exit 1
fi
echo -e "${GREEN}[✔]${RESET} btusb.c güncellendi"

# DKMS ile kur
echo -e "${CYAN}[i]${RESET} DKMS ile derleniyor ve kuruluyor..."
sudo dkms add ~/bluetooth-6.14
sudo dkms install btusb/4.3

echo ""
echo -e "${GREEN}${BOLD}[✔] Kurulum tamamlandı!${RESET}"
echo -e "${CYAN}[i]${RESET} Lütfen sistemi yeniden başlatın: ${BOLD}sudo reboot${RESET}"
