#!/bin/bash

# =====================================================================
# Skrip Ping Server
# Deskripsi:
# Skrip ini membaca daftar alamat IP dari file servers.txt dan
# melakukan ping ke setiap alamat untuk memeriksa status koneksi.
# =====================================================================

# Tentukan nama file yang berisi daftar server
SERVER_FILE="servers.txt"

# Periksa apakah file server ada dan dapat dibaca
if [ ! -f "$SERVER_FILE" ]; then
    echo "[ERROR] File '$SERVER_FILE' tidak ditemukan."
    echo "Harap buat file tersebut dan isi dengan daftar alamat IP, satu per baris."
    exit 1
fi

echo "=== Memulai Pengecekan Server dari '$SERVER_FILE' ==="

# Baca setiap baris dari file
while IFS= read -r ip_address
do
    # Lakukan ping dengan 1 paket dan timeout 1 detik
    # Output dari ping disembunyikan agar tampilan lebih bersih
    ping -c 1 -W 1 "$ip_address" &> /dev/null

    # Periksa exit code dari perintah ping
    # Exit code 0 berarti berhasil (success)
    if [ $? -eq 0 ]; then
        echo "Ping success [$ip_address]"
    else
        echo "Ping failed  [$ip_address]"
    fi
done < "$SERVER_FILE"

echo "=== Pengecekan Selesai ==="
