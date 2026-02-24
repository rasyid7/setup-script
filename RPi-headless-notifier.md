# Raspberry Pi Headless IP Notifier

Setelah boot dan konek ke network, Raspberry Pi akan otomatis kirim notifikasi IP address ke Google Chat via webhook. Script berjalan sekali lalu menghapus dirinya sendiri.
Jangan lupa masukkan WEBHOOK url dari Google Chat ke dalam script!

## Requirements

- **Debian GNU/Linux 13 (Trixie)**
- SD card yang bisa dibaca dari Mac/Windows
- Google Chat webhook URL

## Cara Setup

### 1. Buat file `notify-ip.sh`

Buat file ini di root boot partition SD card (`/Volumes/bootfs/` di Mac):

```bash
#!/bin/bash

WEBHOOK=""

# Tunggu sampai dapat IP (max ~60 detik)
for i in $(seq 1 12); do
  IP=$(hostname -I | awk '{print $1}')
  if [ -n "$IP" ]; then
    break
  fi
  sleep 5
done

HOSTNAME=$(hostname)

curl -s -X POST "$WEBHOOK" \
  -H "Content-Type: application/json" \
  -d "{\"text\": \"🍓 *Raspberry Pi Online!*\nHostname: \`$HOSTNAME\`\nIP Address: \`$IP\`\"}"

# Cleanup: hapus entry dari cmdline.txt dan hapus script ini
mount -o remount,rw /boot
sed -i 's/ systemd.run=\/boot\/notify-ip.sh//' /boot/cmdline.txt
rm -- "$0"
```

### 2. Edit `cmdline.txt`

Buka `cmdline.txt` di boot partition, tambahkan `systemd.run=/boot/firmware/notify-ip.sh` di **akhir baris** (jangan buat baris baru).

Contoh sebelum:
```
console=serial0,115200 console=tty1 root=PARTUUID=ffc763c1-02 rootfstype=ext4 fsck.repair=yes rootwait
```

Contoh sesudah:
```
console=serial0,115200 console=tty1 root=PARTUUID=ffc763c1-02 rootfstype=ext4 fsck.repair=yes rootwait systemd.run=/boot/firmware/notify-ip.sh
```

### 3. Enable SSH (opsional)

Kalau belum, buat file kosong bernama `ssh` di boot partition:

```bash
touch /Volumes/bootfs/ssh
```

### 4. Boot Raspberry Pi

Pasang SD card dan nyalakan. Dalam beberapa detik setelah konek ke network, notifikasi akan masuk ke Google Chat berisi hostname dan IP address.

Setelah berhasil, script dan entry di `cmdline.txt` akan terhapus otomatis.

## Troubleshooting

Kalau notifikasi tidak masuk, cek via SSH:

```bash
# Cek apakah systemd.run terpanggil
sudo journalctl -b | grep systemd.run

# Coba jalanin script manual
sudo bash /boot/notify-ip.sh
```

## Catatan

- **Path boot partition:** `/boot/` (untuk Debian Trixie). Kalau pakai Raspberry Pi OS Bookworm, ganti semua `/boot/` menjadi `/boot/firmware/`.
- **`cmdline.txt` harus satu baris**, tanpa newline — ini penting, kalau ada baris baru systemd tidak akan baca parameter dengan benar.
