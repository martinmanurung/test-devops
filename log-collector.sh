#!/bin/bash

# ===================================================================================
# Skrip Penyiapan Server & Pengumpul Log
# Deskripsi:
# Skrip ini melakukan penyiapan awal dan pengerasan (hardening) pada server
# Ubuntu 22.04 LTS. Skrip ini juga mencakup tugas-tugas spesifik seperti
# manajemen pengguna, konfigurasi izin, rotasi log, dan pengumpulan log.
#
# Dijalankan sebagai root atau dengan sudo.
# ===================================================================================

# Variabel
APP_DIR="/opt/rey/sample-web-app"
LOG_ARCHIVE_DIR="/tmp/archive_logs"
LOG_ARCHIVE_NAME="logs_$(date +%Y%m%d).tar.gz"

# Fungsi untuk mencetak pesan informasi
log_info() {
    echo "[INFO] $1"
}

# --- Pemeriksaan Awal ---
if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] Skrip ini harus dijalankan sebagai root atau dengan sudo."
   exit 1
fi

# --- 1. Pembaruan Sistem & Instalasi Dependensi ---
log_info "Memperbarui paket sistem dan menginstal dependensi (ufw, acl, postgresql)..."
apt-get update
apt-get upgrade -y
apt-get install -y ufw acl postgresql postgresql-contrib nginx

# --- 2. Manajemen Grup & Pengguna ---
log_info "Membuat grup 'devops' dan 'dev' jika belum ada..."
groupadd --force devops
groupadd --force dev

log_info "Memberikan akses sudo tanpa password kepada grup 'devops'..."
echo "%devops ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/devops-nopasswd

# Contoh pembuatan pengguna (sesuaikan sesuai kebutuhan)
# log_info "Membuat pengguna contoh: 'devopsuser', 'dev1', 'dev2'..."
# useradd -m -s /bin/bash -g devops -G sudo devopsuser
# useradd -m -s /bin/bash -g dev dev1
# useradd -m -s /bin/bash -g dev dev2
# log_info "CATATAN: Akses SSH dengan kunci publik harus diatur secara manual untuk setiap pengguna."

# --- 3. Pengerasan Server (Hardening) ---

# 3.1. Konfigurasi Firewall (UFW)
log_info "Mengkonfigurasi aturan firewall (UFW)..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh       # Port 22
ufw allow http      # Port 80
ufw allow https     # Port 443
ufw --force enable

# 3.2. Penyesuaian Performa Sistem (sysctl)
log_info "Menyesuaikan parameter kernel untuk menangani koneksi maksimum..."
cat > /etc/sysctl.d/99-server-performance.conf << EOL
# Meningkatkan batas koneksi antrian
net.core.somaxconn = 65535
# Meningkatkan jumlah maksimum file descriptor yang bisa dibuka
fs.file-max = 100000
EOL
sysctl --system

# --- 4. Penyiapan Direktori Aplikasi ---
log_info "Menyiapkan direktori aplikasi di $APP_DIR..."
mkdir -p "$APP_DIR"
chown -R root:dev "$APP_DIR"
# 'setgid' bit memastikan file/folder baru di dalam direktori ini akan mewarisi grup 'dev'
chmod -R 775 "$APP_DIR"
chmod g+s "$APP_DIR"
log_info "Izin direktori aplikasi telah diatur untuk grup 'dev'."

# --- 5. Konfigurasi Akses & Rotasi Log ---

# 5.1. Akses Log untuk Grup 'dev' menggunakan ACL
log_info "Memberikan akses baca ke file log di /var/log/ untuk grup 'dev' menggunakan ACL..."
# Berikan akses default agar file baru juga bisa diakses
setfacl -d -m g:dev:r /var/log/
# Terapkan pada file yang sudah ada
setfacl -m g:dev:r /var/log/*.log

# 5.2. Konfigurasi Rotasi Log
log_info "Mengatur rotasi log dengan retensi 14 hari..."
cat > /etc/logrotate.d/custom-logs << EOL
/var/log/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
    dateext
    dateformat -%Y%m%d
}
EOL

# --- 6. Skrip Pengumpul Log ---
log_info "Memulai proses pengumpulan log..."
mkdir -p "$LOG_ARCHIVE_DIR"

log_info "Mencari file .log di /var/log dan mengompresnya..."
# Cari file log, pastikan tidak mengarsipkan dirinya sendiri jika skrip dijalankan dari /var/log
find /var/log -name "*.log" -print0 | tar -czvf "$LOG_ARCHIVE_DIR/$LOG_ARCHIVE_NAME" --null -T -

if [ $? -eq 0 ]; then
    log_info "Log berhasil diarsipkan ke: $LOG_ARCHIVE_DIR/$LOG_ARCHIVE_NAME"
else
    echo "[ERROR] Terjadi kesalahan saat mengarsipkan log."
fi

# --- Selesai ---
echo ""
log_info "===== PENYIAPAN SERVER SELESAI ====="
