# Booky - Aplikasi Peminjaman Buku Perpustakaan Sekolah

Booky adalah platform digital perpustakaan sekolah terintegrasi yang memudahkan siswa untuk memesan (booking) buku secara online sebelum melakukan pengambilan fisik di perpustakaan, serta memudahkan admin/pustakawan untuk memonitor, mengelola inventaris, dan memproses status peminjaman secara efisien.

Platform ini dibangun menggunakan arsitektur modern:
- **Backend (API)**: [Laravel 11+](./bb_backend) dengan autentikasi berbasis token menggunakan Laravel Sanctum.
- **Frontend (Mobile)**: [Flutter SDK](./bb_frontend) dengan manajemen state Provider dan caching data yang dioptimalkan untuk performa tinggi.

---

## Daftar Isi
1. [Fitur Utama](#fitur-utama)
2. [Teknologi yang Digunakan](#teknologi-yang-digunakan)
3. [Arsitektur & Alur Sistem (Flow)](#arsitektur--alur-sistem-flow)
4. [Prasyarat Sistem](#prasyarat-sistem)
5. [Langkah-Langkah Setup Backend](#langkah-langkah-setup-backend)
6. [Langkah-Langkah Setup Frontend](#langkah-langkah-setup-frontend)
7. [Konfigurasi Jaringan & Koneksi Device Fisik](#konfigurasi-jaringan--koneksi-device-fisik)
8. [Akun Demo Pengujian](#akun-demo-pengujian)
9. [Referensi Struktur Database](#referensi-struktur-database)
10. [Referensi Endpoint API](#referensi-endpoint-api)
11. [Aturan Bisnis Peminjaman](#aturan-bisnis-peminjaman)
12. [Panduan Pemecahan Masalah (Troubleshooting)](#panduan-pemecahan-masalah-troubleshooting)

---

## Fitur Utama

### Untuk Siswa (Mobile App)
- **Eksplorasi Buku**: Pencarian buku secara dinamis, filtering berdasarkan kategori, serta pengecekan stok real-time (Tersedia / Stok Habis).
- **Sistem Booking Buku**: Reservasi buku dengan masa pinjam standar selama 2 minggu.
- **Manajemen Wishlist**: Menyimpan buku favorit atau buku yang akan dipinjam nanti ke daftar keinginan.
- **Riwayat & Status Peminjaman**: Memantau status peminjaman aktif (Booking, Dipinjam, Kembali, Terlambat, Batal).
- **Notifikasi In-App**: Menerima pembaruan status peminjaman, pengingat pengembalian buku, dan pesan siaran (broadcast) dari admin.
- **Manajemen Profil**: Mengubah nama, kelas, nomor ponsel, serta memantau ringkasan aktivitas akun.

### Untuk Admin (Dashboard & Manajemen)
- **Statistik Dashboard**: Informasi ringkas mengenai total buku, jumlah siswa terdaftar, transaksi aktif, dan jumlah buku yang terlambat dikembalikan.
- **Kelola Buku**: CRUD (Create, Read, Update, Delete) buku lengkap dengan deskripsi, kategori, stok, dan gambar cover.
- **Kelola Kategori**: Mengelompokkan koleksi perpustakaan dengan ikon representatif.
- **Kelola Siswa**: Mendaftarkan atau menyunting informasi data NIS, kelas, dan kontak siswa.
- **Monitoring Peminjaman**: Panel komprehensif untuk memantau semua reservasi, menyunting status transaksi, dan menambahkan catatan admin.
- **Notifikasi Cerdas**: Mengirim notifikasi pengingat keterlambatan kepada siswa secara individual atau mengirim pesan siaran ke seluruh siswa.

---

## Teknologi yang Digunakan

### Backend (`bb_backend`)
- **Core Framework**: Laravel 11.x (PHP 8.3+)
- **Autentikasi**: Laravel Sanctum (Token-Based REST API)
- **Database**: MySQL 8.x
- **Development Helper**: Laravel Tinker & Concurrently untuk eksekusi server simultan
- **Testing**: Pest PHP Framework

### Frontend (`bb_frontend`)
- **Core SDK**: Flutter ^3.12.0 (Dart ^3.x)
- **State Management**: Provider ^6.1.2
- **Network Client**: HTTP ^1.2.0 (dengan penanganan timeout dan penanganan eror koneksi)
- **Local Storage**: Shared Preferences ^2.3.2 (untuk persistensi sesi login)
- **UI/UX Library**:
  - `cached_network_image` (optimasi caching gambar cover agar hemat kuota dan memuat cepat)
  - `shimmer` (efek animasi skeleton loading saat memuat data)
  - `badges` (badge notifikasi real-time)
  - `google_fonts` (sistem tipografi modern)
  - `flutter_staggered_grid_view` (tampilan grid buku yang dinamis)
  - `image_picker` (akses galeri untuk mengunggah gambar)

---

## Arsitektur & Alur Sistem (Flow)

Dokumentasi alur detail sistem tersedia di file [APP_FLOW.md](./APP_FLOW.md). Berikut adalah visualisasi alur peminjaman buku:

### Alur Peminjaman Buku (Siswa ke Admin)

```
[Siswa] Mencari Buku di Aplikasi
   ↓
[Siswa] Menekan "Pinjam Sekarang" (Membuat Booking)
   ↓
[Sistem] Stok Berkurang 1, Status Booking: "Pending"
   ↓
[Siswa] Datang ke Perpustakaan Fisik & Menunjukkan Akun
   ↓
[Admin] Membuka Menu "Monitor Pinjam" -> Cari Nama Siswa
   ↓
[Admin] Menyerahkan Buku Fisik & Mengubah Status ke "Active" (Dipinjam)
   ↓
[Siswa] Membaca Buku (Maksimal 14 Hari)
   ↓
[Siswa] Mengembalikan Buku ke Perpustakaan
   ↓
[Admin] Mengubah Status ke "Returned" (Kembali)
   ↓
[Sistem] Stok Bertambah 1 secara Otomatis
```

---

## Prasyarat Sistem

Sebelum memulai instalasi, pastikan lingkungan pengembangan Anda telah terinstal tools berikut:
- **PHP** >= 8.3
- **Composer** >= 2.x
- **MySQL Server** >= 8.x
- **Node.js** >= 18.x & **NPM**
- **Flutter SDK** >= 3.12.0
- **Android Studio** atau **Xcode** (untuk emulator)
- **Git**

---

## Langkah-Langkah Setup Backend

Ikuti tahapan di bawah ini untuk menjalankan server API Laravel:

1. **Masuk ke direktori backend:**
   ```bash
   cd bb_backend
   ```

2. **Instal dependensi Composer:**
   ```bash
   composer install
   ```

3. **Salin file konfigurasi lingkungan (.env):**
   ```bash
   cp .env.example .env
   ```

4. **Konfigurasikan database pada `.env`:**
   Buka file `.env` menggunakan teks editor pilihan Anda dan sesuaikan baris berikut dengan kredensial MySQL lokal Anda:
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=db_booky_library
   DB_USERNAME=root
   DB_PASSWORD=your_mysql_password
   ```
   *(Opsional: Buat database kosong bernama `db_booky_library` terlebih dahulu di MySQL Anda).*

5. **Generate Application Key:**
   ```bash
   php artisan key:generate
   ```

6. **Jalankan Migrasi & Database Seeder:**
   Perintah ini akan membuat semua tabel database yang diperlukan dan mengisinya dengan data sampel (akun admin, data siswa, kategori buku, buku contoh, dan data transaksi awal):
   ```bash
   php artisan migrate --seed
   ```

7. **Jalankan Aplikasi:**
   Untuk kenyamanan, backend ini menyediakan script `dev` yang akan menjalankan server lokal, worker antrean notifikasi, dan logger logs secara bersamaan menggunakan `concurrently`:
   ```bash
   composer dev
   ```
   *Jika Anda ingin menjalankannya secara manual tanpa dependensi NPM, jalankan:*
   ```bash
   php artisan serve
   ```
   Server API secara default akan berjalan di **`http://127.0.0.1:8000`**.

---

## Langkah-Langkah Setup Frontend

Ikuti langkah-langkah berikut untuk mengonfigurasi dan menjalankan aplikasi mobile Flutter:

1. **Masuk ke direktori frontend:**
   ```bash
   cd bb_frontend
   ```

2. **Instal dependensi Flutter/Dart:**
   ```bash
   flutter pub get
   ```

3. **Sesuaikan Alamat API Backend:**
   Alamat IP server API dikonfigurasikan terpusat pada file [lib/core/constants.dart](./bb_frontend/lib/core/constants.dart).
   Secara default, konfigurasinya adalah:
   ```dart
   static const String baseUrl = 'http://127.0.0.1:8000/api';
   ```
   *(Baca bagian [Konfigurasi Jaringan](#konfigurasi-jaringan--koneksi-device-fisik) di bawah untuk penyesuaian jika menggunakan emulator Android atau perangkat fisik).*

4. **Jalankan Perangkat Emulator:**
   Pastikan emulator Android (AVD) atau Simulator iOS sudah berjalan di latar belakang. Anda bisa memeriksa daftar perangkat yang terdeteksi dengan perintah:
   ```bash
   flutter devices
   ```

5. **Jalankan Aplikasi Flutter:**
   ```bash
   flutter run
   ```

---

## Konfigurasi Jaringan & Koneksi Device Fisik

Ketika menjalankan aplikasi di emulator atau perangkat fisik, localhost (`127.0.0.1`) perangkat berbeda dengan localhost komputer Anda. Gunakan pedoman berikut untuk menyelaraskannya:

### 1. Menggunakan Emulator Android (Default AVD)
Emulator Android memiliki alamat loopback khusus untuk mengakses localhost komputer host.
- Ubah `baseUrl` di `lib/core/constants.dart` menjadi:
  ```dart
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  ```

### 2. Menggunakan Perangkat Fisik (Melalui Wi-Fi yang Sama)
Perangkat fisik harus menunjuk ke IP lokal komputer host Anda.
1. Cari tahu IP lokal komputer Anda melalui terminal:
   - **Windows**: `ipconfig` (lihat `IPv4 Address` pada adapter aktif)
   - **Linux/macOS**: `ifconfig` atau `ip a` (cari IP seperti `192.168.1.XX`)
2. Pastikan port `8000` di komputer Anda tidak diblokir oleh firewall lokal.
3. Ubah `baseUrl` di `lib/core/constants.dart` dengan IP tersebut:
   ```dart
   static const String baseUrl = 'http://192.168.1.XX:8000/api';
   ```

### 3. Menggunakan Fitur ADB Reverse (Rekomendasi untuk Android Fisik via Kabel)
Jika perangkat Android Anda terhubung menggunakan kabel USB dengan fitur USB Debugging menyala, ini adalah metode termudah dan paling stabil tanpa perlu mengubah kode `lib/core/constants.dart` (tetap menggunakan `127.0.0.1`):
1. Jalankan perintah reverse port di terminal komputer Anda:
   ```bash
   adb reverse tcp:8000 tcp:8000
   ```
2. Sekarang, permintaan API dari perangkat Android fisik ke `http://127.0.0.1:8000` akan otomatis diteruskan ke server Laravel di komputer Anda.

---

## Akun Demo Pengujian

Data seeder menyediakan akun simulasi yang siap langsung digunakan untuk login dan pengujian:

| Peran (Role) | Email | Password | Keterangan Tambahan |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin@booky.id` | `password` | Akun administrator utama pengelola sistem |
| **Siswa 1** | `andi@siswa.id` | `password` | Nama: Andi Pratama, Kelas: XII RPL 1, NIS: 2024001 |
| **Siswa 2** | `budi@siswa.id` | `password` | Nama: Budi Santoso, Kelas: XI TKJ 2, NIS: 2024002 |
| **Siswa 3** | `citra@siswa.id` | `password` | Nama: Citra Dewi, Kelas: X MM 1, NIS: 2024003 |

---

## Referensi Struktur Database

Skema tabel penting di dalam database MySQL yang dibuat melalui migrasi:

### 1. `users` (Menampung Data Admin & Siswa)
- `id` (Primary Key)
- `name` (string) - Nama lengkap
- `email` (string, unique) - Email login
- `password` (string) - Password terenkripsi
- `role` (enum: 'admin', 'student') - Hak akses pengguna
- `nis` (string, nullable) - Nomor Induk Siswa (khusus siswa)
- `kelas` (string, nullable) - Kelas siswa (khusus siswa)
- `phone` (string, nullable) - Nomor HP
- Timestamps (`created_at`, `updated_at`)

### 2. `books` (Menampung Data Koleksi Buku)
- `id` (Primary Key)
- `category_id` (Foreign Key ke `categories`)
- `title` (string) - Judul buku
- `author` (string) - Penulis
- `publisher` (string, nullable) - Penerbit
- `year` (integer, nullable) - Tahun terbit
- `description` (text, nullable) - Sinopsis / penjelasan buku
- `cover_url` (string, nullable) - URL gambar cover buku
- `stock` (integer) - Ketersediaan fisik buku
- `availability` (enum: 'available', 'unavailable') - Status otomatis ketersediaan
- Timestamps

### 3. `borrowings` (Menampung Riwayat Transaksi Peminjaman)
- `id` (Primary Key)
- `user_id` (Foreign Key ke `users`)
- `book_id` (Foreign Key ke `books`)
- `status` (enum: 'pending', 'active', 'returned', 'overdue', 'cancelled')
- `borrowed_at` (timestamp, nullable) - Tanggal buku mulai diambil secara fisik
- `due_date` (timestamp, nullable) - Tanggal batas akhir pengembalian (default: `borrowed_at + 14 hari`)
- `returned_at` (timestamp, nullable) - Tanggal pengembalian buku aktual
- `admin_notes` (text, nullable) - Catatan khusus admin (misalnya: denda, kondisi buku rusak)
- Timestamps

---

## Referensi Endpoint API

Aplikasi mobile terhubung ke backend menggunakan REST API dengan endpoint berikut:

### Autentikasi & Profil (Umum)
- `POST /api/login` - Login pengguna, mengembalikan Token Sanctum & data profil.
- `POST /api/register` - Registrasi akun siswa baru.
- `POST /api/logout` - Logout (menghapus token aktif saat ini).
- `GET /api/profile` - Mengambil profil lengkap user yang login.
- `PUT /api/profile` - Memperbarui informasi profil pengguna.

### Fitur Buku & Kategori (Siswa & Admin)
- `GET /api/books` - Daftar semua buku (dilengkapi dengan filter pencarian `?search=` dan kategori).
- `GET /api/books/{id}` - Informasi detail satu buku tertentu.
- `GET /api/categories` - Mengambil daftar seluruh kategori buku perpustakaan.

### Fitur Peminjaman (Siswa)
- `GET /api/borrowings` - Mengambil daftar transaksi peminjaman milik siswa bersangkutan.
- `POST /api/borrowings` - Mengajukan booking/reservasi buku baru.
- `POST /api/borrowings/{id}/cancel` - Membatalkan pemesanan buku (hanya berlaku jika status masih "pending").

### Fitur Wishlist & Notifikasi (Siswa)
- `GET /api/wishlists` - Mengambil daftar buku favorit siswa.
- `POST /api/wishlists` - Menambahkan buku ke dalam wishlist.
- `DELETE /api/wishlists/{book_id}` - Menghapus buku dari wishlist.
- `GET /api/notifications` - Riwayat notifikasi masuk untuk siswa.

### Operasional Administrasi (Khusus Admin - Dilindungi Middleware `admin`)
- `GET /api/admin/dashboard` - Statistik utama dashboard admin.
- `POST /api/admin/books` - Menambahkan buku baru ke inventaris.
- `PUT /api/admin/books/{id}` - Menyunting detail data buku.
- `DELETE /api/admin/books/{id}` - Menghapus buku dari database.
- `GET /api/admin/borrowings` - Melihat seluruh riwayat transaksi peminjaman semua siswa.
- `PUT /api/admin/borrowings/{id}` - Mengubah status transaksi peminjaman (misal: "pending" -> "active").
- `POST /api/admin/remind/{id}` - Mengirimkan push notification pengingat spesifik ke siswa yang meminjam.
- `POST /api/admin/notifications` - Mengirim notifikasi siaran (broadcast) ke seluruh siswa.
- `GET /api/admin/users` - Mengelola akun-akun siswa terdaftar di platform.

---

## Aturan Bisnis Peminjaman

1. **Durasi Peminjaman Standar**: Maksimal **14 hari** (2 minggu) setelah buku diserahterimakan oleh admin (status berubah menjadi `active`).
2. **Pengambilan Buku Fisik**: Siswa harus mengambil buku fisik yang telah di-booking pada hari yang sama saat melakukan pemesanan online sebelum jam istirahat sekolah berakhir.
3. **Pembatalan Otomatis**: Jika buku tidak diambil hingga batas waktu operasional hari pemesanan berakhir, sistem berhak membatalkan transaksi (`cancelled`) dan stok buku akan dikembalikan.
4. **Pembatasan Ketersediaan**: Buku dengan stok `0` otomatis berlabel *Stok Habis*, tombol pinjam akan dinonaktifkan untuk mencegah pemesanan ganda.
5. **Keterlambatan**: Jika pengembalian melebihi batas `due_date`, status transaksi akan berubah menjadi `overdue` dan memblokir siswa untuk melakukan booking buku baru sampai buku sebelumnya dikembalikan.

---

## Panduan Pemecahan Masalah (Troubleshooting)

### 1. Eror `SocketException: Connection refused` / Aplikasi Loading Selamanya
Eror ini terjadi karena aplikasi Flutter tidak dapat mencapai server Laravel Anda.
- **Solusi**:
  1. Pastikan server Laravel sedang berjalan dengan mengetik `php artisan serve` di direktori backend.
  2. Periksa alamat IP yang dimasukkan di `lib/core/constants.dart`. Pastikan Anda tidak menggunakan `localhost` jika berjalan di emulator Android fisik (gunakan `10.0.2.2` atau IP Lokal).
  3. Jika menggunakan device fisik Android, coba jalankan `adb reverse tcp:8000 tcp:8000` di terminal Anda.
  4. Pastikan PC dan ponsel Anda berada di jaringan Wi-Fi yang sama dan atur mode Wi-Fi ke "Private" (bukan Public) agar port dapat diakses.

### 2. Eror `Database ... not found` saat Menjalankan Migrasi
- **Solusi**:
  1. Pastikan service MySQL lokal Anda sudah menyala.
  2. Buat database baru bernama `db_booky_library` melalui phpMyAdmin, DBeaver, atau perintah CLI MySQL `CREATE DATABASE db_booky_library;`.
  3. Jalankan kembali perintah `php artisan migrate --seed`.

### 3. Gambar Cover Buku Tidak Terload (Gambar Abu-Abu / Rusak)
- **Solusi**:
  Buku default di seeder menggunakan URL gambar asli. Pastikan komputer Anda terhubung ke internet saat memuat aplikasi pertama kali agar gambar dapat di-cache ke dalam penyimpanan lokal ponsel melalui library `cached_network_image`.

---

*Hak Cipta &copy; 2026 - Booky Library App. Dikembangkan untuk kemudahan literasi sekolah.*
