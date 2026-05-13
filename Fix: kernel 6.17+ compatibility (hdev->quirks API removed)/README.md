# Mercusys MA530 Bluetooth — Linux Kernel 6.17+ Fix

**Problem:** Mercusys MA530 (USB ID: `2c4e:0115`) Bluetooth adapter is detected by Linux but device scanning does not work.

**Why:** Starting with kernel 6.17, the `hci_dev->quirks` field was removed. The old `btusb` driver is incompatible with this change.

**Tested on:**
- Linux Mint 22.3
- Kernel 6.17.0-23-generic
- Adapter: Mercusys MA530 (Realtek RTL8761BU chipset)

---

## Installation

### 1. Install required tools

```bash
sudo apt install git dkms -y
```

### 2. Download the driver

```bash
cd ~
git clone https://github.com/jeremyb31/bluetooth-6.14.git
cd bluetooth-6.14
```

### 3. Patch btusb.c for kernel 6.17 compatibility

In kernel 6.17, direct access to `hdev->quirks` was removed and replaced with `hci_set_quirk()` / `hci_clear_quirk()` / `hci_test_quirk()` functions. The following command automatically updates btusb.c:

```bash
python3 -c "
import re
with open('btusb.c', 'r') as f:
    content = f.read()
content = re.sub(r'set_bit\((HCI_QUIRK_\w+),\s*&hdev->quirks\)', r'hci_set_quirk(hdev, \1)', content)
content = re.sub(r'clear_bit\((HCI_QUIRK_\w+),\s*&hdev->quirks\)', r'hci_clear_quirk(hdev, \1)', content)
content = re.sub(r'test_bit\((HCI_QUIRK_\w+),\s*&hdev->quirks\)', r'hci_test_quirk(hdev, \1)', content)
with open('btusb.c', 'w') as f:
    f.write(content)
print('Done')
"
```

Verify — output should be **0**:

```bash
grep -c "hdev->quirks" btusb.c
```

### 4. Install with DKMS

```bash
sudo dkms add ~/bluetooth-6.14
sudo dkms install btusb/4.3
```

### 5. Reboot

```bash
sudo reboot
```

---

## Verification

After reboot:

```bash
hciconfig -a
bluetoothctl show
```

The Bluetooth icon should appear in the taskbar and device scanning should work.

---

## One-liner Installation

```bash
sudo apt install git dkms -y && \
cd ~ && \
git clone https://github.com/jeremyb31/bluetooth-6.14.git && \
cd bluetooth-6.14 && \
python3 -c "
import re
with open('btusb.c', 'r') as f:
    content = f.read()
content = re.sub(r'set_bit\((HCI_QUIRK_\w+),\s*&hdev->quirks\)', r'hci_set_quirk(hdev, \1)', content)
content = re.sub(r'clear_bit\((HCI_QUIRK_\w+),\s*&hdev->quirks\)', r'hci_clear_quirk(hdev, \1)', content)
content = re.sub(r'test_bit\((HCI_QUIRK_\w+),\s*&hdev->quirks\)', r'hci_test_quirk(hdev, \1)', content)
with open('btusb.c', 'w') as f:
    f.write(content)
" && \
sudo dkms add ~/bluetooth-6.14 && \
sudo dkms install btusb/4.3 && \
echo 'Installation complete. Please reboot.'
```

---

## Notes

- This method works for kernels **6.15, 6.16, 6.17** and likely later versions.
- After kernel updates, DKMS will automatically recompile the module.
- If you encounter issues, please open an Issue.

---

## Credits

- [jeremyb31/bluetooth-6.14](https://github.com/jeremyb31/bluetooth-6.14) — original driver
- [Linux Mint Forum — MA530 Thread](https://forums.linuxmint.com/viewtopic.php?t=439744)
- [Arch Linux Forum — MA530 Thread](https://bbs.archlinux.org/viewtopic.php?id=305985)
