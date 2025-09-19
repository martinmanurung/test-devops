#!/bin/bash

# =================================================================
# Skrip Deployment Sederhana untuk Nginx di Fedora
# Deskripsi:
# Skrip ini menginstal Nginx, membuat
# halaman web statis, dan memulai layanan Nginx.
# =================================================================

# Header untuk output
echo "=== Memulai Deployment Web Server Nginx ==="

# 1. Instalasi Nginx
echo "[INFO] Menginstal Nginx..."
sudo dnf install -y nginx

# 2. Menjalankan dan Mengaktifkan Layanan Nginx
echo "[INFO] Menjalankan dan mengaktifkan layanan Nginx..."
sudo systemctl start nginx
sudo systemctl enable nginx

# 3. Membuat Halaman Web Statis
echo "[INFO] Membuat file index.html..."
echo "Hello DevOps World!" | sudo tee /var/www/html/index.html

# Selesai
IP_ADDRESS=$(hostname -I | awk '{print $1}')
echo "=== Deployment Selesai! ==="
echo "Server web dapat diakses di http://localhost atau http://${IP_ADDRESS}"