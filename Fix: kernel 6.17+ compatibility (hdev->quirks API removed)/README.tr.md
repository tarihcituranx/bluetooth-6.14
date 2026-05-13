# Mercusys MA530 Bluetooth — Linux Kernel 6.17+ Fix 

**Sorun:** Mercusys MA530 (USB ID: `2c4e:0115`) Bluetooth adaptörü Linux'ta tanınıyor ancak cihaz taraması çalışmıyor.

**Neden:** Kernel 6.17 ile birlikte `hci_dev->quirks` alanı kaldırıldı. Eski `btusb` sürücüsü bu değişiklikle uyumsuz hale geldi.

**Test edilen sistem:**
- Linux Mint 22.3
- Kernel 6.17.0-23-generic
- Adaptör: Mercusys MA530 (Realtek RTL8761BU çipli)

---

## Kurulum

### 1. Gerekli araçları kur

```bash
sudo apt install git dkms -y
```

### 2. Sürücüyü indir

```bash
cd ~
git clone https://github.com/jeremyb31/bluetooth-6.14.git
cd bluetooth-6.14
```

### 3. Kernel 6.17 uyumu için btusb.c'yi düzelt

Kernel 6.17'de `hdev->quirks` doğrudan erişim kaldırıldı, yerine `hci_set_quirk()` / `hci_clear_quirk()` / `hci_test_quirk()` fonksiyonları geldi. Aşağıdaki komut btusb.c'yi otomatik olarak günceller:

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
print('Tamamlandi')
"
```

Kontrol et — **0** çıkmalı:

```bash
grep -c "hdev->quirks" btusb.c
```

### 4. DKMS ile kur

```bash
sudo dkms add ~/bluetooth-6.14
sudo dkms install btusb/4.3
```

### 5. Yeniden başlat

```bash
sudo reboot
```

---

## Doğrulama

Açıldıktan sonra:

```bash
hciconfig -a
bluetoothctl show
```

Bluetooth görev çubuğunda görünmeli ve cihaz taraması çalışmalı.

---

## Tek Satır Kurulum (Hepsini Bir Arada)

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
echo 'Kurulum tamamlandi, yeniden baslatiniz.'
```

---

## Notlar

- Bu yöntem kernel **6.15, 6.16, 6.17** için geçerlidir.
- Kernel güncellemelerinde DKMS modülü otomatik yeniden derlenir.
- Sorun yaşarsanız `Issues` sekmesini kullanabilirsiniz.

---

## Kaynaklar

- [jeremyb31/bluetooth-6.14](https://github.com/jeremyb31/bluetooth-6.14)
- [Linux Mint Forum — MA530 Thread](https://forums.linuxmint.com/viewtopic.php?t=439744)
- [Arch Linux Forum — MA530 Thread](https://bbs.archlinux.org/viewtopic.php?id=305985)
